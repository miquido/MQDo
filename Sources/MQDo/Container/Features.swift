import MQ

@MainActor internal final class Features {

	#if DEBUG
		internal let debugContext: SourceCodeContext
	#endif
	private let scopes: Set<FeaturesScope.Identifier>
	private var combinedScopes: Set<FeaturesScope.Identifier> {
		self.scopes.union(self.parent?.combinedScopes ?? .init())
	}
	private let factory: FeaturesFactory
	@MainActor private var cache: FeaturesCache
	private let parent: Features?
	private lazy var root: Features = self

	internal init(
		scopes: Set<FeaturesScope.Identifier>,
		registry: FeaturesRegistry,
		parent: Features?,
		root: Features?,
		file: StaticString,
		line: UInt
	) {

		self.scopes = scopes
		self.cache = .init()
		self.factory = .init(using: registry)
		self.parent = parent
		#if DEBUG
			self.debugContext = .context(
				message: root == nil
					? "Features container root"
					: "Features container branch",
				file: file,
				line: line
			)
		#endif
		if let root = root {
			self.root = root
		}
		else {
			noop()
		}
	}

	deinit {
		// ensure that unloads will be called
		self.cache.clear()
	}
}

extension Features: FeaturesContainer {

	@MainActor internal func containsScope<Scope>(
		_ scope: Scope.Type
	) -> Bool
	where Scope: FeaturesScope {
		self.combinedScopes.contains(scope.identifier)
	}

	@MainActor internal func branch<Scope>(
		_ scope: Scope.Type,
		registrySetup: ScopedFeaturesRegistry<Scope>.SetupFunction,
		file: StaticString,
		line: UInt
	) -> FeaturesContainer
	where Scope: FeaturesScope {
		runtimeAssert(
			Scope.self != RootFeaturesScope.self,
			message: "Cannot use RootFeaturesScope for a branch!"
		)

		var featuresRegistry: ScopedFeaturesRegistry<Scope>
		do {
			featuresRegistry =
				try self
				.root  // scope registry has to be defined only on roots
				.instance(of: FeaturesRegistryForScope<Scope>.self)
				.featuresRegistry

		}
		catch let error as FeatureLoadingFailed
		where error.cause is FeatureUndefined {
			FeaturesScopeUndefined
				.error(
					message: "Please define all required scopes on root features registry.",
					scope: Scope.self
				)
				.asAssertionFailure()
			// use empty registry as a fallback for undefined scopes
			featuresRegistry = .init()
		}
		catch {
			Unidentified
				.error(
					message:
						"FeaturesRegistryForScope was not available due to unknown error, please report a bug.",
					underlyingError: error
				)
				.asFatalError()
		}

		registrySetup(&featuresRegistry)

		return Features(
			scopes: [Scope.identifier],
			registry: featuresRegistry.registry,
			parent: self,
			root: self.root,
			file: file,
			line: line
		)
	}

	@MainActor internal func instance<Feature>(
		of featureType: Feature.Type,
		context: Feature.Context,
		file: StaticString,
		line: UInt
	) throws -> Feature
	where Feature: LoadableContextualFeature {
		if let cachedFeature: Feature = try self.cache.get(featureType, context: context) {
			return cachedFeature
		}
		else {
			let cacheSnapshot: FeaturesCache = self.cache
			do {
				let feature: Feature =
					try self
					.factory
					.load(
						featureType,
						in: context,
						using: self,
						cache: { (entry: FeaturesCache.Entry) in
							#if DEBUG
								var entry: FeaturesCache.Entry = entry
								entry
									.debugContext
									.set(self.scopes, for: "scope")
							#endif
							self.cache.set(
								entry: entry,
								for: .identifier(
									of: featureType,
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
				if let parent: Features = self.parent {
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
							.with(self.scopes, for: "scope")
							.with(self.branchDescription, for: "features")
					}
				}
				else {
					throw
						error
						.asTheError()
						.with(self.scopes, for: "scope")
						.with(self.branchDescription, for: "features")
				}
			}
			catch {
				// FIXME: it won't call unload for dependant features
				// cleanup cache after failed loading attempt
				self.cache = cacheSnapshot
				throw
					error
					.asTheError()
					.with(self.scopes, for: "scope")
					.with(self.branchDescription, for: "features")
			}
		}
	}

	@MainActor internal func instance<Feature>(
		of featureType: Feature.Type,
		file: StaticString,
		line: UInt
	) throws -> Feature
	where Feature: LoadableFeature {
		if let cachedFeature: Feature = try self.cache.get(featureType) {
			return cachedFeature
		}
		else {
			let cacheSnapshot: FeaturesCache = self.cache
			do {
				let feature: Feature =
					try self
					.factory
					.load(
						featureType,
						using: self,
						cache: { (entry: FeaturesCache.Entry) in
							#if DEBUG
								var entry: FeaturesCache.Entry = entry
								entry
									.debugContext
									.set(self.scopes, for: "scope")
							#endif
							self.cache.set(
								entry: entry,
								for: .identifier(
									of: featureType,
									context: void
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
				if let parent: Features = self.parent {
					do {
						return
							try parent
							.instance(
								of: featureType,
								file: file,
								line: line
							)
					}
					catch {
						throw
							error
							.asTheError()
							.with(self.scopes, for: "scope")
							.with(self.branchDescription, for: "features")
					}
				}
				else {
					throw
						error
						.asTheError()
						.with(self.scopes, for: "scope")
						.with(self.branchDescription, for: "features")
				}
			}
			catch {
				// FIXME: it won't call unload for dependant features
				// cleanup cache after failed loading attempt
				self.cache = cacheSnapshot
				throw
					error
					.asTheError()
					.with(self.scopes, for: "scope")
					.with(self.branchDescription, for: "features")
			}
		}
	}
}

// swift-format-ignore: AllPublicDeclarationsHaveDocumentation
extension Features: CustomStringConvertible {

	public var description: String {
		"Features\(self.scopes)"
	}
}

// swift-format-ignore: AllPublicDeclarationsHaveDocumentation
extension Features: CustomDebugStringConvertible {

	public var debugDescription: String {
		#if DEBUG
			"Features tree:\n\(self.branchDescription)"
		#else
			self.description
		#endif
	}
}

// swift-format-ignore: AllPublicDeclarationsHaveDocumentation
extension Features: CustomLeafReflectable {

	public var customMirror: Mirror {
		.init(
			self,
			children: [
				"branch": self.branchDescription
			],
			displayStyle: .none,
			ancestorRepresentation: .suppressed
		)
	}
}

extension Features {

	internal var branchDescription: String {
		var description: String = "Branch"
		var current: Features? = self
		while let features = current {
			description.append("\n\(features.description)")
			current = features.parent
		}
		return description
	}
}

#if DEBUG
	extension Features {

		//		public static func testing<Feature>(
		//			_ featureType: Feature.Type = Feature.self,
		//			_ loader: FeatureLoader<Feature>
		//		) -> Self
		//		where Feature: LoadableFeature {
		//			Self.init(
		//				scopes: [TestingScope.identifier],
		//				lock: .init(  // no locking, test should be synchronous
		//					acquire: noop,
		//					tryAcquire: always(true),
		//					release: noop
		//				),
		//				parent: .none,
		//				registry: .init(loaders: [loader.asAnyLoader])
		//			)
		//		}
		//
		//		private var testingScope: Bool {
		//			self.scopes.contains(TestingScope.identifier)
		//		}
		//
		//		public func patch<Feature, Property>(
		//			_ keyPath: WritableKeyPath<Feature, Property>,
		//			context: Feature.Context,
		//			with updated: Property,
		//			file: StaticString = #fileID,
		//			line: UInt = #line
		//		) where Feature: LoadableFeature, Feature.Context: IdentifiableFeatureContext {
		//			var cacheEntry: FeaturesCache.Entry =
		//				self
		//				.cache
		//				.entry(
		//					for: .identifier(
		//						of: Feature.self,
		//						context: context
		//					)
		//				)
		//				?? .init(
		//					feature: Feature.placeholder,
		//					debugContext: .context(
		//						message: "Placeholder",
		//						file: file,
		//						line: line
		//					)
		//					.with(self.scopes, for: "scope"),
		//					removal: noop
		//				)
		//			withExtendedLifetime(cacheEntry) {
		//				guard var feature: Feature = cacheEntry.feature as? Feature
		//				else {
		//					InternalInconsistency
		//						.error(message: "Feature is not matching expected type")
		//						.with(self.scopes, for: "scope")
		//						.with(Feature.self, for: "expected")
		//						.with(type(of: cacheEntry.feature), for: "received")
		//						.appending(
		//							.message(
		//								"FeatureLoader is invalid",
		//								file: file,
		//								line: line
		//							)
		//						)
		//						.asFatalError()
		//				}
		//
		//				feature[keyPath: keyPath] = updated
		//				cacheEntry.feature = feature
		//				cacheEntry
		//					.debugContext
		//					.append(
		//						.message(
		//							"Patched",
		//							file: file,
		//							line: line
		//						)
		//						.with(self.scopes, for: "scope")
		//					)
		//				cache.set(
		//					entry: cacheEntry,
		//					for: .identifier(
		//						of: Feature.self,
		//						context: context
		//					)
		//				)
		//			}
		//		}

		@MainActor public func debugContext<Feature>(
			for featureType: Feature.Type,
			file: StaticString = #fileID,
			line: UInt = #line
		) -> SourceCodeContext
		where Feature: LoadableFeature {
			return self
				.cache
				.getDebugContext(
					for: .identifier(
						of: featureType,
						context: void
					)
				)
				?? self
				.factory
				.loaderDebugContext(for: featureType)
				?? self
				.parent?
				.debugContext(for: featureType)
				?? FeatureUndefined
				.error(
					message: "FeatureLoader.undefined",
					feature: featureType,
					file: file,
					line: line
				)
				.with(self.scopes, for: "scope")
				.with(Feature.self, for: "feature")
				.with("Undefined", for: "implementation")
				.context
		}
	}
#endif
