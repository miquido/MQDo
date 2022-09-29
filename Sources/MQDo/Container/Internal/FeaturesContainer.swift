internal final class FeaturesContainer {

	private let scope: FeaturesScope.Identifier
	#if DEBUG
		private var scopeContext: Any
	#else
		private let scopeContext: Any
	#endif
	private let staticFeatures: StaticFeatures
	private let scopesRegistries: Dictionary<FeaturesScopeIdentifier, DynamicFeaturesRegistry>
	private let featuresFactory: FeaturesFactory
	private var featuresCache: FeaturesCache
	private let parentContainer: FeaturesContainer?
	private let treeLock: Lock

	private init(
		scope: FeaturesScope.Identifier,
		scopeContext: Any,
		registry: DynamicFeaturesRegistry,
		staticFeatures: StaticFeatures,
		scopesRegistries: Dictionary<FeaturesScopeIdentifier, DynamicFeaturesRegistry>,
		parentContainer: FeaturesContainer?,
		treeLock: Lock
	) {
		self.scope = scope
		self.scopeContext = scopeContext
		self.staticFeatures = staticFeatures
		self.scopesRegistries = scopesRegistries
		self.featuresFactory = .init(using: registry)
		self.featuresCache = .init()
		self.parentContainer = parentContainer
		self.treeLock = treeLock
	}

	deinit {
		// ensure proper unloading of features
		self.featuresCache.clear()
	}
}

extension FeaturesContainer {

	internal static func root(
		registry: ScopedFeaturesRegistry<RootFeaturesScope>.SetupFunction
	) -> Self {
		var featuresRegistry: ScopedFeaturesRegistry<RootFeaturesScope> = .init()
		registry(&featuresRegistry)

		return .init(
			scope: RootFeaturesScope.identifier,
			scopeContext: Void(),
			registry: featuresRegistry.registry,
			staticFeatures: featuresRegistry.staticFeatures,
			scopesRegistries: featuresRegistry.scopesRegistries,
			parentContainer: .none,
			treeLock: .nsRecursiveLock()
		)
	}

	internal func branch<Scope>(
		_ scope: Scope.Type,
		context: Scope.Context,
		file: StaticString,
		line: UInt
	) throws -> Self
	where Scope: FeaturesScope {
		#if DEBUG
			guard !self.testingScope else {
				var contexts: Dictionary<AnyHashable, Any> = self.scopeContext as! Dictionary<AnyHashable, Any>
				contexts[ObjectIdentifier(Scope.self)] = context
				self.scopeContext = contexts
				return self
			}
		#endif

		guard let scopeRegistry: DynamicFeaturesRegistry = self.scopesRegistries[scope.identifier]
		else {
			throw
				FeaturesScopeUndefined
				.error(
					message: "Please define all required scopes on root features registry.",
					scope: scope,
					file: file,
					line: line
				)
				.asRuntimeWarning()
		}

		return .init(
			scope: scope.identifier,
			scopeContext: context,
			registry: scopeRegistry,
			staticFeatures: self.staticFeatures,
			scopesRegistries: self.scopesRegistries,
			parentContainer: self,
			treeLock: self.treeLock
		)
	}

	internal var features: Features {
		.init(
			treeLock: self.treeLock,
			container: self
		)
	}
}

extension FeaturesContainer {

	private var combinedScopes: Set<FeaturesScope.Identifier> {
		Set<FeaturesScope.Identifier>([self.scope]).union(self.parentContainer?.combinedScopes ?? .init())
	}

	internal func containsScope<Scope>(
		_ scope: Scope.Type,
		checkRecursively: Bool,
		file: StaticString,
		line: UInt
	) -> Bool
	where Scope: FeaturesScope {
		let scopesToCheck: Set<FeaturesScope.Identifier>

		if checkRecursively {
			scopesToCheck = self.combinedScopes
		}
		else {
			scopesToCheck = [self.scope]
		}

		#if DEBUG
			return scopesToCheck.contains(scope.identifier)
				|| self.testingScope
		#else
			return scopesToCheck.contains(scope.identifier)
		#endif
	}

	internal func context<Scope>(
		for scopeType: Scope.Type,
		file: StaticString,
		line: UInt
	) throws -> Scope.Context
	where Scope: FeaturesScope {
		#if DEBUG
			guard !self.testingScope else {
				let contexts: Dictionary<AnyHashable, Any> = self.scopeContext as! Dictionary<AnyHashable, Any>
				if let context: Scope.Context = contexts[ObjectIdentifier(Scope.self)] as? Scope.Context {
					return context
				}
				else {
					throw
						FeaturesScopeContextUnavailable
						.error(
							scope: Scope.self,
							file: file,
							line: line
						)
				}
			}
		#endif
		if let context: Scope.Context = self.scopeContext as? Scope.Context {
			return context
		}
		else if let parent: FeaturesContainer = self.parentContainer {
			return try parent.context(
				for: Scope.self,
				file: file,
				line: line
			)
		}
		else {
			throw
				FeaturesScopeContextUnavailable
				.error(scope: Scope.self)
				.asRuntimeWarning()
		}
	}
}

extension FeaturesContainer {

	internal var branchDescription: String {
		var description: String = ""
		var current: FeaturesContainer? = self
		while let features = current {
			description.append("\nNode: \(features.scope)")
			current = features.parentContainer
		}
		return description
	}
}

extension FeaturesContainer {

	internal func instance<Feature>(
		of featureType: Feature.Type,
		file: StaticString,
		line: UInt
	) -> Feature
	where Feature: StaticFeature {
		self.staticFeatures
			.instance(
				of: featureType,
				file: file,
				line: line
			)
	}

	internal func instance<Feature>(
		of featureType: Feature.Type,
		context: Feature.Context,
		file: StaticString,
		line: UInt
	) throws -> Feature
	where Feature: DynamicFeature {
		if let cachedFeature: Feature = try self.featuresCache.get(featureType, context: context) {
			return cachedFeature
		}
		else {
			do {
				let feature: Feature =
					try self
					.featuresFactory
					.load(
						featureType,
						context: context,
						within: self,
						cache: { (entry: FeaturesCache.Entry) in
							#if DEBUG
								var entry: FeaturesCache.Entry = entry
								entry
									.debugContext
									.set(context, for: "context")
								entry
									.debugContext
									.set(self.branchDescription, for: "branch")
							#endif
							self.featuresCache.set(
								entry: entry,
								for: .key(
									for: featureType,
									context: context
								)
							)
						},
						file: file,
						line: line
					)
				return feature
			}
			catch let error as FeatureLoadingFailed
			where error.cause is FeatureUndefined {
				if let parent: FeaturesContainer = self.parentContainer {
					do {
						return
							try parent
							.instance(
								of: featureType,
								context: context,
								file: file,
								line: line
							)
					}
					catch {
						throw
							error
							.asTheError()
							// replace branch description with current
							.with(self.branchDescription, for: "branch")
							.asRuntimeWarning()
					}
				}
				else {
					#if DEBUG
						if self.testingScope {
							let placeholder: Feature = .placeholder
							self.featuresCache.set(
								entry: .init(
									feature: placeholder,
									debugContext: .context(
										message: "Placeholder",
										file: file,
										line: line
									)
									.with(context, for: "context")
									.with(self.branchDescription, for: "branch"),
									removal: noop
								),
								for: .key(
									for: featureType,
									context: context
								)
							)
							return placeholder
						}  // else continue to an error
					#endif
					throw error.asRuntimeWarning()
				}
			}
			catch {
				throw error
			}
		}
	}

	internal func loadIfNeeded<Feature>(
		_ featureType: Feature.Type,
		context: Feature.Context,
		file: StaticString = #fileID,
		line: UInt = #line
	) throws
	where Feature: DynamicFeature {
		do {
			// TODO: refine preloading features
			// to avoid loading instances which
			// are not cached
			_ = try self.instance(
				of: featureType,
				context: context,
				file: file,
				line: line
			)
		}
		catch {
			throw
				error
				.asTheError()
				.appending(
					.message(
						"Preloading feature instance failed at loading completion",
						file: file,
						line: line
					)
				)
				.asRuntimeWarning()
		}
	}
}

#if DEBUG

	extension FeaturesContainer {

		internal static func testing<Feature>(
			_ featureType: Feature.Type,
			_ loader: FeatureLoader<Feature>
		) -> Self
		where Feature: DynamicFeature {
			.init(
				scope: TestingScope.identifier,
				scopeContext: Dictionary<AnyHashable, Any>(),
				registry: .init(dynamicFeaturesLoaders: [loader.asAnyLoader]),
				staticFeatures: .init(),
				scopesRegistries: .init(),
				parentContainer: .none,
				treeLock: .nsRecursiveLock()
			)
		}

		private var testingScope: Bool {
			self.scope == TestingScope.identifier
		}
	}

	extension FeaturesContainer {

		internal func use<Feature>(
			instance: Feature,
			context: Feature.Context,
			file: StaticString,
			line: UInt
		) where Feature: DynamicFeature {
			self.featuresCache
				.set(
					entry: .init(
						feature: instance,
						debugContext: .context(
							message: "Forced instance cached",
							file: file,
							line: line
						)
						.with(context, for: "context")
						.with(self.branchDescription, for: "branch"),
						removal: noop
					),
					for: .key(
						for: Feature.self,
						context: context
					)
				)
		}

		internal func patch<Feature>(
			_ featureType: Feature.Type,
			context: Feature.Context,
			with patching: (inout Feature) -> Void,
			file: StaticString,
			line: UInt
		) where Feature: DynamicFeature {
			// load if needed ignoring errors
			do {
				try self.loadIfNeeded(
					Feature.self,
					context: context
				)
			}
			catch {
				error
					.asTheError()
					.asAssertionFailure()
			}

			guard
				var cacheEntry: FeaturesCache.Entry =
					self
					.featuresCache
					.getEntry(
						for: .key(
							for: featureType,
							context: context
						)
					)
			else {
				return runtimeAssertionFailure(
					message: "Trying to patch not existing feature."
				)
			}

			guard var feature: Feature = cacheEntry.feature as? Feature
			else {
				InternalInconsistency
					.error(message: "Feature is not matching expected type, please report a bug.")
					.with(self.branchDescription, for: "branch")
					.with(Feature.self, for: "expected")
					.with(context, for: "context")
					.with(type(of: cacheEntry.feature), for: "received")
					.appending(
						.message(
							"FeatureLoader is invalid",
							file: file,
							line: line
						)
					)
					.asFatalError()
			}

			patching(&feature)
			cacheEntry.feature = feature
			cacheEntry
				.debugContext
				.append(
					.message(
						"Patched",
						file: file,
						line: line
					)
					.with(context, for: "context")
					.with(self.branchDescription, for: "branch")
				)
			self.featuresCache.set(
				entry: cacheEntry,
				for: .key(
					for: featureType,
					context: context
				)
			)
		}

		internal func setContext<Scope>(
			_ context: Scope.Context,
			for scopeType: Scope.Type,
			file: StaticString,
			line: UInt
		) where Scope: FeaturesScope {
			if self.testingScope {
				var contexts: Dictionary<AnyHashable, Any> = self.scopeContext as! Dictionary<AnyHashable, Any>
				contexts[ObjectIdentifier(Scope.self)] = context
				return self.scopeContext = contexts
			}
			else {
				FeaturesScopeContextUnavailable
					.error(
						message: "Context patching is available only to test containers.",
						scope: Scope.self,
						file: file,
						line: line
					)
					.asRuntimeWarning()
			}
		}

		internal func debugContext<Feature>(
			for featureType: Feature.Type,
			context: Feature.Context,
			file: StaticString,
			line: UInt
		) -> SourceCodeContext
		where Feature: DynamicFeature {
			self
				.featuresCache
				.getDebugContext(
					for: .key(
						for: featureType,
						context: context
					)
				)
				?? self
				.featuresFactory
				.loaderDebugContext(
					for: featureType,
					context: context
				)
				?? self
				.parentContainer?
				.debugContext(
					for: featureType,
					context: context,
					file: file,
					line: line
				)
				?? FeatureUndefined
				.error(
					message: "FeatureLoader.undefined",
					feature: featureType,
					file: file,
					line: line
				)
				.with(self.branchDescription, for: "branch")
				.with(Feature.self, for: "feature")
				.with("Undefined", for: "implementation")
				.context
		}

		internal func clearCache() {
			self.featuresCache.clear()
		}
	}

	private enum TestingScope: FeaturesScope {

		typealias Context = Never
	}

#endif
