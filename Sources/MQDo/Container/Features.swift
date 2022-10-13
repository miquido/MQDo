import MQ

/// Container for accessing feature instances.
///
public final class Features {

	#if DEBUG
		private var testing: Bool { self.tested != nil }
		private let tested: Any.Type?
		private var testOverrides: Dictionary<AnyHashable, Any> = .init()
	#endif
	private let treeLock: Lock
	private let scope: any FeaturesScope.Type
	private let scopeContext: any Sendable
	private let featuresRegistry: FeaturesTreeRegistry
	private let branchFeatures: Array<Features>  // reversed order, closes predecessor first
	private var parentFeatures: Features? {
		self.branchFeatures.first
	}
	private var featuresCache:
		Dictionary<CacheableFeatureInstanceIdentifier, (instance: any CacheableFeature, unload: @Sendable () -> Void)>

	private init(
		treeLock: Lock,
		scope: any FeaturesScope.Type,
		scopeContext: any Sendable,
		featuresRegistry: FeaturesTreeRegistry,
		branchFeatures: Array<Features>
	) {
		#if DEBUG
			self.tested = nil
			self.testOverrides = [scope.identifier: scopeContext]
		#endif
		self.treeLock = treeLock
		self.scope = scope
		self.scopeContext = scopeContext
		self.featuresRegistry = featuresRegistry
		self.branchFeatures = branchFeatures
		self.featuresCache = .init()
	}

	#if DEBUG
		private init<Feature>(
			testing featureType: Feature.Type = Feature.self,
			loader: any DisposableFeatureLoader,
			testOverrides: Dictionary<AnyHashable, Any>
		) where Feature: DisposableFeature {
			self.tested = Feature.self
			self.testOverrides = testOverrides
			self.treeLock = .nsRecursiveLock()
			self.scope = TestFeaturesScope.self
			self.scopeContext = Dictionary<FeaturesScopeIdentifier, Any>()
			var featuresRegistry: FeaturesTreeRegistry = .init()
			featuresRegistry.scopeFeatureLoaders[TestFeaturesScope.identifier] = .init()
			featuresRegistry.scopeFeatureLoaders[TestFeaturesScope.identifier]?.disposable[Feature.identifier] = loader
			self.featuresRegistry = featuresRegistry
			self.branchFeatures = .init()
			self.featuresCache = .init()
		}

		private init<Feature>(
			testing featureType: Feature.Type = Feature.self,
			loader: any CacheableFeatureLoader,
			testOverrides: Dictionary<AnyHashable, Any>
		) where Feature: CacheableFeature {
			self.tested = Feature.self
			self.testOverrides = testOverrides
			self.treeLock = .nsRecursiveLock()
			self.scope = TestFeaturesScope.self
			self.scopeContext = Dictionary<AnyHashable, Any>()
			var featuresRegistry: FeaturesTreeRegistry = .init()
			featuresRegistry.scopeFeatureLoaders[TestFeaturesScope.identifier] = .init()
			featuresRegistry.scopeFeatureLoaders[TestFeaturesScope.identifier]?.cacheable[Feature.identifier] = loader
			self.featuresRegistry = featuresRegistry
			self.branchFeatures = .init()
			self.featuresCache = .init()
		}
	#endif

	deinit {
		for cacheEntry in self.featuresCache.values {
			cacheEntry.unload()
		}
	}
}

extension Features: Sendable {}

extension Features {

	/// Create root container for features.
	///
	public static func root(
		registrySetup: FeaturesRegistry<RootFeaturesScope>.Setup
	) -> Features {
		var rootRegistry: FeaturesRegistry<RootFeaturesScope> = .init()
		registrySetup(&rootRegistry)

		return .init(
			treeLock: .nsRecursiveLock(),
			scope: RootFeaturesScope.self,
			scopeContext: Void(),
			featuresRegistry: rootRegistry.treeRegistry,
			branchFeatures: .init()
		)
	}

	/// Verify scope of the container.
	///
	@Sendable public func containsScope<Scope>(
		_ scope: Scope.Type
	) -> Bool where Scope: FeaturesScope {
		#if DEBUG
			if self.testing {
				return true
			}  // else continue ignoring overrides
		#endif
		return self.scope.identifier == scope.identifier
			|| self.branchFeatures
				.contains(where: { $0.scope.identifier == scope.identifier })
	}

	/// Create new container branch with provided scope.
	///
	@_disfavoredOverload @Sendable public func branch<Scope>(
		_ scope: Scope.Type,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Features
	where Scope: FeaturesScope, Scope.Context == Never {
		#if DEBUG
			if self.testing {
				self.testOverrides[Scope.identifier] = Void()
				return self
			}  // else continue ignoring overrides
		#endif
		var branchFeatures: Array<Features> = self.branchFeatures
		branchFeatures
			.insert(self, at: branchFeatures.startIndex)
		return .init(
			treeLock: self.treeLock,
			scope: scope,
			scopeContext: Void(),
			featuresRegistry: self.featuresRegistry,
			branchFeatures: branchFeatures
		)
	}

	/// Create new container branch with provided scope and context.
	///
	@_disfavoredOverload @Sendable public func branch<Scope>(
		_ scope: Scope.Type,
		context: Scope.Context,
		file: StaticString = #fileID,
		line: UInt = #line
	) throws -> Features
	where Scope: FeaturesScope {
		#if DEBUG
			if self.testing {
				self.testOverrides[Scope.identifier] = context
				return self
			}  // else continue ignoring overrides
		#endif
		var branchFeatures: Array<Features> = self.branchFeatures
		branchFeatures
			.insert(self, at: branchFeatures.startIndex)
		return .init(
			treeLock: self.treeLock,
			scope: scope,
			scopeContext: context,
			featuresRegistry: self.featuresRegistry,
			branchFeatures: branchFeatures
		)
	}

	/// Access a context value associated with scope.
	///
	@Sendable public func context<Scope>(
		for scope: Scope.Type,
		file: StaticString = #fileID,
		line: UInt = #line
	) throws -> Scope.Context
	where Scope: FeaturesScope {
		#if DEBUG
			if self.testing, let context: Scope.Context = self.testOverrides[scope.identifier] as? Scope.Context {
				return context
			}  // else continue ignoring overrides
		#endif
		if self.scope.identifier == scope.identifier {
			if let context: Scope.Context = self.scopeContext as? Scope.Context {
				return context
			}
			else {
				throw
					InternalInconsistency
					.error(
						message: "Type mismatch in scope contexts, please report a bug."
					)
					.asRuntimeWarning()
			}
		}
		else if let parent: Features = self.branchFeatures.first(where: { $0.scope.identifier == scope.identifier }) {
			if let context: Scope.Context = parent.scopeContext as? Scope.Context {
				return context
			}
			else {
				throw
					InternalInconsistency
					.error(
						message: "Type mismatch in scope contexts, please report a bug."
					)
					.asRuntimeWarning()
			}
		}
		else {
			throw
				FeaturesScopeContextUnavailable
				.error(
					scope: scope,
					file: file,
					line: line
				)
				.asRuntimeWarning()
		}
	}

	/// Remove all cached features from container.
	///
	@Sendable public func cleanCache() {
		self.treeLock.withLock { () -> Void in
			for cacheEntry in self.featuresCache.values {
				cacheEntry.unload()
			}
			self.featuresCache = .init()
		}
	}
}

extension Features {

	/// Access an instance of a ``StaticFeature``.
	///
	@Sendable public func instance<Feature>(
		of featureType: Feature.Type = Feature.self,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Feature
	where Feature: StaticFeature {
		#if DEBUG
			if self.testing {
				return self.treeLock.withLock { () -> Feature in
					let instance: Feature = self.testOverrides[Feature.identifier] as? Feature ?? .placeholder
					self.testOverrides[Feature.identifier] = instance
					return instance
				}
			}  // else continue ignoring overrides
		#endif
		return self.featuresRegistry
			.instance(
				of: featureType,
				file: file,
				line: line
			)
	}

	/// Create an instance of a ``DisposableFeature``.
	///
	@Sendable public func instance<Feature>(
		of featureType: Feature.Type = Feature.self,
		context: Feature.Context,
		file: StaticString = #fileID,
		line: UInt = #line
	) throws -> Feature
	where Feature: DisposableFeature {
		#if DEBUG
			if self.testing && self.tested != Feature.self {
				return try self.treeLock.withLock { () throws -> Feature in
					let instance: Feature = self.testOverrides[Feature.identifier] as? Feature ?? .placeholder
					self.testOverrides[Feature.identifier] = instance
					return instance
				}
			}  // else continue ignoring overrides
		#endif
		do {
			return try self.featuresRegistry
				.loadInstance(
					of: featureType,
					context: context,
					in: self.scope,
					using: self,
					file: file,
					line: line
				)
		}
		catch {
			throw
				FeatureLoadingFailed
				.error(
					feature: Feature.self,
					cause: error.asTheError(),
					file: file,
					line: line
				)
		}
	}

	/// Create an instance of a ``DisposableFeature``.
	///
	@Sendable public func instance<Feature>(
		of featureType: Feature.Type = Feature.self,
		file: StaticString = #fileID,
		line: UInt = #line
	) throws -> Feature
	where Feature: DisposableFeature, Feature.Context == Void {
		#if DEBUG
			if self.testing && self.tested != Feature.self {
				return try self.treeLock.withLock { () throws -> Feature in
					let instance: Feature = self.testOverrides[Feature.identifier] as? Feature ?? .placeholder
					self.testOverrides[Feature.identifier] = instance
					return instance
				}
			}  // else continue ignoring overrides
		#endif
		do {
			return try self.featuresRegistry
				.loadInstance(
					of: featureType,
					context: Void(),
					in: self.scope,
					using: self,
					file: file,
					line: line
				)
		}
		catch {
			throw
				FeatureLoadingFailed
				.error(
					feature: Feature.self,
					cause: error.asTheError(),
					file: file,
					line: line
				)
		}
	}

	/// Create an instance of a ``CacheableFeature``.
	///
	@Sendable public func instance<Feature>(
		of featureType: Feature.Type = Feature.self,
		context: Feature.Context,
		file: StaticString = #fileID,
		line: UInt = #line
	) throws -> Feature
	where Feature: CacheableFeature {
		try self.treeLock.withLock { () throws -> Feature in
			let cacheIdentifier: CacheableFeatureInstanceIdentifier = .init(for: Feature.self, context: context)
			#if DEBUG
				if self.testing && self.tested != Feature.self {
					let instance: Feature = self.testOverrides[cacheIdentifier] as? Feature ?? .placeholder
					self.testOverrides[cacheIdentifier] = instance
					return instance
				}  // else continue ignoring overrides
			#endif

			do {
				if let cachedFeature: Feature = self.featuresCache[cacheIdentifier]?.instance as? Feature {
					return cachedFeature
				}
				else if let parent: Features = self.parentFeatures {
					return
						try parent
						.instance(of: Feature.self, context: context)
				}
				else {
					let loadedCacheableInstance: (instance: Feature, unload: @Sendable () -> Void) = try self.featuresRegistry
						.loadInstance(
							of: featureType,
							context: context,
							in: self.scope,
							using: self,
							file: file,
							line: line
						)
					self.featuresCache[cacheIdentifier] = loadedCacheableInstance
					return loadedCacheableInstance.instance
				}
			}
			catch {
				throw
					FeatureLoadingFailed
					.error(
						feature: Feature.self,
						cause: error.asTheError(),
						file: file,
						line: line
					)
			}
		}
	}

	/// Create an instance of a ``CacheableFeature``.
	///
	@Sendable public func instance<Feature>(
		of featureType: Feature.Type = Feature.self,
		file: StaticString = #fileID,
		line: UInt = #line
	) throws -> Feature
	where Feature: CacheableFeature, Feature.Context == ContextlessCacheableFeatureContext {
		try self.treeLock.withLock { () throws -> Feature in
			let cacheIdentifier: CacheableFeatureInstanceIdentifier = .init(
				for: Feature.self,
				context: ContextlessCacheableFeatureContext.context
			)

			#if DEBUG
				if self.testing && self.tested != Feature.self {
					let instance: Feature = self.testOverrides[cacheIdentifier] as? Feature ?? .placeholder
					self.testOverrides[cacheIdentifier] = instance
					return instance
				}  // else continue ignoring overrides
			#endif

			do {
				if let cachedFeature: Feature = self.featuresCache[cacheIdentifier]?.instance as? Feature {
					return cachedFeature
				}
				else if let parent: Features = self.parentFeatures {
					return
						try parent
						.instance(of: Feature.self)
				}
				else {
					let loadedCacheableInstance: (instance: Feature, unload: @Sendable () -> Void) = try self.featuresRegistry
						.loadInstance(
							of: featureType,
							context: ContextlessCacheableFeatureContext.context,
							in: self.scope,
							using: self,
							file: file,
							line: line
						)
					self.featuresCache[cacheIdentifier] = loadedCacheableInstance
					return loadedCacheableInstance.instance
				}
			}
			catch {
				throw
					FeatureLoadingFailed
					.error(
						feature: Feature.self,
						cause: error.asTheError(),
						file: file,
						line: line
					)
			}
		}
	}

	/// Get a lazy instance of a ``DisposableFeature`` without context.
	///
	@Sendable public func deferredInstance<Feature>(
		of featureType: Feature.Type = Feature.self,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> DeferredInstance<Feature>
	where Feature: DisposableFeature, Feature.Context == Void {
		DeferredInstance(
			{ @Sendable [unowned self] () throws -> Feature in
				try self.instance(
					of: featureType,
					context: Void(),
					file: file,
					line: line
				)
			},
			file: file,
			line: line
		)
	}

	/// Get a lazy instance of a ``DisposableFeature``.
	///
	@Sendable public func deferredInstance<Feature>(
		of featureType: Feature.Type = Feature.self,
		context: Feature.Context,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> DeferredInstance<Feature>
	where Feature: DisposableFeature {
		DeferredInstance(
			{ @Sendable [unowned self] () throws -> Feature in
				try self.instance(
					of: featureType,
					context: context,
					file: file,
					line: line
				)
			},
			file: file,
			line: line
		)
	}

	/// Get a lazy instance of a ``CacheableFeature`` without context.
	///
	@Sendable public func deferredInstance<Feature>(
		of featureType: Feature.Type = Feature.self,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> DeferredInstance<Feature>
	where Feature: CacheableFeature, Feature.Context == ContextlessCacheableFeatureContext {
		DeferredInstance(
			{ @Sendable [unowned self] () throws -> Feature in
				try self.instance(
					of: featureType,
					file: file,
					line: line
				)
			},
			file: file,
			line: line
		)
	}

	/// Get a lazy instance of a ``CacheableFeature``.
	///
	@Sendable public func deferredInstance<Feature>(
		of featureType: Feature.Type = Feature.self,
		context: Feature.Context,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> DeferredInstance<Feature>
	where Feature: CacheableFeature {
		DeferredInstance(
			{ @Sendable [unowned self] () throws -> Feature in
				try self.instance(
					of: featureType,
					context: context,
					file: file,
					line: line
				)
			},
			file: file,
			line: line
		)
	}
}

// swift-format-ignore: AllPublicDeclarationsHaveDocumentation
extension Features: CustomStringConvertible {

	public var description: String {
		"Features"
	}
}

// swift-format-ignore: AllPublicDeclarationsHaveDocumentation
extension Features: CustomDebugStringConvertible {

	public var debugDescription: String {
		#if DEBUG
			self.branchFeatures
				.reduce(
					into: "Features tree branch:\n\(self.scope)"
				) { (description: inout String, features: Features) in
					description.append("\(features.scope)")
				}
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
			children: [],
			displayStyle: .none,
			ancestorRepresentation: .suppressed
		)
	}
}

#if DEBUG
	extension Features {

		/// Create container for testing.
		///
		public static func testing<Feature>(
			_ featureType: Feature.Type = Feature.self,
			_ loader: any DisposableFeatureLoader
		) -> Features
		where Feature: DisposableFeature {
			.init(
				testing: Feature.self,
				loader: loader,
				testOverrides: .init()
			)
		}

		/// Create container for testing.
		///
		public static func testing<Feature>(
			_ featureType: Feature.Type = Feature.self,
			_ loader: any CacheableFeatureLoader
		) -> Features
		where Feature: CacheableFeature {
			.init(
				testing: Feature.self,
				loader: loader,
				testOverrides: .init()
			)
		}

		/// Force given feature instance in container.
		///
		@Sendable public func use<Feature>(
			instance: Feature,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Feature: StaticFeature {
			precondition(
				self.testing,
				"Cannot override features out of tests."
			)
			self.treeLock.withLock { () -> Void in
				self.testOverrides[Feature.identifier] = instance
			}
		}

		/// Force given feature instance in container.
		///
		@Sendable public func use<Feature>(
			instance: Feature,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Feature: DisposableFeature {
			precondition(
				self.testing,
				"Cannot override features out of tests."
			)
			self.treeLock.withLock { () -> Void in
				self.testOverrides[Feature.identifier] = instance
			}
		}

		/// Force given feature instance in container.
		///
		@Sendable public func use<Feature>(
			instance: Feature,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Feature: CacheableFeature, Feature.Context == ContextlessCacheableFeatureContext {
			precondition(
				self.testing,
				"Cannot override features out of tests."
			)
			self.treeLock.withLock { () -> Void in
				self.testOverrides[
					CacheableFeatureInstanceIdentifier(for: Feature.self, context: ContextlessCacheableFeatureContext.context)
				] = instance
			}
		}

		/// Force given feature instance in container.
		///
		@Sendable public func use<Feature>(
			instance: Feature,
			context: Feature.Context,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Feature: CacheableFeature {
			precondition(
				self.testing,
				"Cannot override features out of tests."
			)
			self.treeLock.withLock { () -> Void in
				self.testOverrides[CacheableFeatureInstanceIdentifier(for: Feature.self, context: context)] = instance
			}
		}

		/// Patch parts of overriden features.
		///
		@_disfavoredOverload @Sendable public func patch<Feature, Property>(
			_ keyPath: WritableKeyPath<Feature, Property>,
			with updated: Property,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Feature: StaticFeature {
			precondition(
				self.testing,
				"Cannot override features out of tests."
			)
			self.treeLock.withLock { () -> Void in
				var feature: Feature = self.testOverrides[Feature.identifier] as? Feature ?? .placeholder
				feature[keyPath: keyPath] = updated
				self.testOverrides[Feature.identifier] = feature
			}
		}

		/// Patch parts of overriden features.
		///
		@_disfavoredOverload @Sendable public func patch<Feature, Property>(
			_ keyPath: WritableKeyPath<Feature, Property>,
			with updated: Property,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Feature: DisposableFeature {
			precondition(
				self.testing,
				"Cannot override features out of tests."
			)
			self.treeLock.withLock { () -> Void in
				var feature: Feature = self.testOverrides[Feature.identifier] as? Feature ?? .placeholder
				feature[keyPath: keyPath] = updated
				self.testOverrides[Feature.identifier] = feature
			}
		}

		/// Patch parts of overriden features.
		///
		@_disfavoredOverload @Sendable public func patch<Feature, Property>(
			_ keyPath: WritableKeyPath<Feature, Property>,
			with updated: Property,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Feature: CacheableFeature, Feature.Context == ContextlessCacheableFeatureContext {
			precondition(
				self.testing,
				"Cannot override features out of tests."
			)
			self.treeLock.withLock { () -> Void in
				var feature: Feature =
					self.testOverrides[
						CacheableFeatureInstanceIdentifier(for: Feature.self, context: ContextlessCacheableFeatureContext.context)
					] as? Feature ?? .placeholder
				feature[keyPath: keyPath] = updated
				self.testOverrides[
					CacheableFeatureInstanceIdentifier(for: Feature.self, context: ContextlessCacheableFeatureContext.context)
				] = feature
			}
		}

		/// Patch parts of overriden features.
		///
		@_disfavoredOverload @Sendable public func patch<Feature, Property>(
			_ keyPath: WritableKeyPath<Feature, Property>,
			context: Feature.Context,
			with updated: Property,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Feature: CacheableFeature {
			precondition(
				self.testing,
				"Cannot override features out of tests."
			)
			self.treeLock.withLock { () -> Void in
				var feature: Feature =
					self.testOverrides[CacheableFeatureInstanceIdentifier(for: Feature.self, context: context)] as? Feature
					?? .placeholder
				feature[keyPath: keyPath] = updated
				self.testOverrides[CacheableFeatureInstanceIdentifier(for: Feature.self, context: context)] = feature
			}
		}

		/// Patch parts of overriden features.
		///
		@_disfavoredOverload @Sendable public func patch<Feature>(
			_ feature: Feature.Type,
			with update: (inout Feature) -> Void,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Feature: StaticFeature {
			precondition(
				self.testing,
				"Cannot override features out of tests."
			)
			self.treeLock.withLock { () -> Void in
				var feature: Feature = self.testOverrides[Feature.identifier] as? Feature ?? .placeholder
				update(&feature)
				self.testOverrides[Feature.identifier] = feature
			}
		}

		/// Patch parts of overriden features.
		///
		@_disfavoredOverload @Sendable public func patch<Feature>(
			_ feature: Feature.Type,
			with update: (inout Feature) -> Void,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Feature: DisposableFeature {
			precondition(
				self.testing,
				"Cannot override features out of tests."
			)
			self.treeLock.withLock { () -> Void in
				var feature: Feature = self.testOverrides[Feature.identifier] as? Feature ?? .placeholder
				update(&feature)
				self.testOverrides[Feature.identifier] = feature
			}
		}

		/// Patch parts of overriden features.
		///
		@_disfavoredOverload @Sendable public func patch<Feature>(
			_ feature: Feature.Type,
			with update: (inout Feature) -> Void,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Feature: CacheableFeature, Feature.Context == ContextlessCacheableFeatureContext {
			precondition(
				self.testing,
				"Cannot override features out of tests."
			)
			self.treeLock.withLock { () -> Void in
				var feature: Feature =
					self.testOverrides[
						CacheableFeatureInstanceIdentifier(for: Feature.self, context: ContextlessCacheableFeatureContext.context)
					] as? Feature ?? .placeholder
				update(&feature)
				self.testOverrides[
					CacheableFeatureInstanceIdentifier(for: Feature.self, context: ContextlessCacheableFeatureContext.context)
				] = feature
			}
		}

		/// Patch parts of overriden features.
		///
		@_disfavoredOverload @Sendable public func patch<Feature>(
			_ feature: Feature.Type,
			context: Feature.Context,
			with update: (inout Feature) -> Void,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Feature: CacheableFeature {
			precondition(
				self.testing,
				"Cannot override features out of tests."
			)
			self.treeLock.withLock { () -> Void in
				var feature: Feature =
					self.testOverrides[CacheableFeatureInstanceIdentifier(for: Feature.self, context: context)] as? Feature
					?? .placeholder
				update(&feature)
				self.testOverrides[CacheableFeatureInstanceIdentifier(for: Feature.self, context: context)] = feature
			}
		}

		/// Set scope context.
		///
		/// Assign context value for a given scope.
		/// This function allows to setup test environment
		/// properly with scope context mocking. It has no
		/// effect in nondebug builds and nontesting containers.
		///
		/// - Parameters
		///   - context: Context value to be assigned.
		///   - scopeType: Type of scope to be used.
		///   - file: Source code file identifier used to track potential error.
		///   Filled automatically based on compile time constants.
		///   - line: Line in given source code file used to track potential error.
		///   Filled automatically based on compile time constants.
		@Sendable public func setContext<Scope>(
			_ context: Scope.Context,
			for scopeType: Scope.Type,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Scope: FeaturesScope {
			precondition(
				self.testing,
				"Cannot override feature scopes out of tests."
			)
			self.treeLock.withLock { () -> Void in
				self.testOverrides[Scope.identifier] = context
			}
		}
	}
#endif
