import MQ

/// Container for accessing feature instances.
///
/// ``Features`` is a hierarchical, tree like container for managing access
/// to instances of features. It allows to propagate multiple implementations
/// of features, scoping access to it, caching feature instances and resolving
/// dependencies across the application.
///
/// Each instance of ``Features`` is associated with at least one type of ``FeaturesScope``.
/// It is used to distinguish scopes and available features in the application. Each container
/// has to be created as either root or branch of other existing container. It is allowed to have
/// multiple root containers and multiple instances of container with the same scope within single tree.
/// It is also allowed to have multiple branches inside single tree.
///
/// Each ``Features`` container is allowed to create and cache only instances of features that
/// were defined for its scope when creating root container or added when creating child for a branch.
/// When accessing a feature which is defined for current branch
/// scope a local feature copy will be used.
/// If it is not defined locally it will be provided from parent containers if able.
/// If requested feature is not defined in current tree branch it fails to load with an error.
public final class Features {

	private let scope: FeaturesScope.Identifier
	private var combinedScopes: Set<FeaturesScope.Identifier> {
		Set<FeaturesScope.Identifier>([self.scope]).union(self.parent?.combinedScopes ?? .init())
	}
	#if DEBUG
		private var scopeContext: Any
		private var staticFeatures: Dictionary<StaticFeatureIdentifier, StaticFeatureInstance>
	#else
		private let scopeContext: Any
		private let staticFeatures: Dictionary<StaticFeatureIdentifier, StaticFeatureInstance>
	#endif
	private let scopesRegistries: Dictionary<FeaturesScopeIdentifier, FeaturesRegistry>
	private let factory: FeaturesFactory
	private var cache: FeaturesCache
	private unowned let parent: Features?
	private let lock: Lock  // shared for the tree

	private init(
		lock: Lock,
		scope: FeaturesScope.Identifier,
		scopeContext: Any,
		parent: Features?,
		registry: FeaturesRegistry,
		scopesRegistries: Dictionary<FeaturesScopeIdentifier, FeaturesRegistry>,
		staticFeatures: Dictionary<StaticFeatureIdentifier, StaticFeatureInstance>
	) {
		self.lock = lock
		self.scope = scope
		self.scopeContext = scopeContext
		self.parent = parent
		self.factory = .init(using: registry)
		self.cache = .init()
		self.scopesRegistries = scopesRegistries
		self.staticFeatures = staticFeatures
	}

	deinit {
		// ensure proper unloading of features
		self.cache.clear()
	}
}

extension Features: @unchecked Sendable {}

extension Features {

	/// Create root container for features.
	///
	/// Root container is initial container that provides the most basic
	/// and critical features across the application.
	///
	/// - Note: There can be multiple instances of root container simultaneously.
	/// If you want to use only a single one you have to reuse the same instance
	/// of the container across the application.
	///
	/// - Note: All associated, forked containers will have access to features from root.
	///
	/// - Parameter registry: ``ScopedFeaturesRegistry`` used to provide
	/// feature implementations for the container.
	/// - Returns: New instance of root ``Features`` container using provided feature
	/// implementation.
	public static func root(
		registry: ScopedFeaturesRegistry<RootFeaturesScope>.SetupFunction
	) -> Self {
		var featuresRegistry: ScopedFeaturesRegistry<RootFeaturesScope> = .init()
		registry(&featuresRegistry)

		return .init(
			lock: .nsRecursiveLock(),
			scope: RootFeaturesScope.identifier,
			scopeContext: Void(),
			parent: .none,
			registry: featuresRegistry.registry,
			scopesRegistries: featuresRegistry.scopesRegistries,
			staticFeatures: featuresRegistry.staticFeatures
		)
	}

	/// Verify scope of the container.
	///
	/// Check if fatures branch contains given scope.
	/// Recursive check will verify access to a scope within branch.
	/// Nonrecursive check will verify if this features container
	/// has defined given scope directly.
	///
	/// - Parameters:
	///   - scope: Scope to be verified.
	///   - checkRecursively: Determines if scope verification should affect only
	///   this instance of ``Features`` container or should check tree recursively up to the root.
	///   Default is false which will only check explicitly defined scope for this ``Features`` instance.
	///   - file: Source code file identifier used to track potential error.
	///   Filled automatically based on compile time constants.
	///   - line: Line in given source code file used to track potential error.
	///   Filled automatically based on compile time constants.
	/// - Returns: `true` if required scope was present in search,
	/// otherwise returns `false`.
	@Sendable public func containsScope<Scope>(
		_ scope: Scope.Type,
		checkRecursively: Bool = false,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Bool where Scope: FeaturesScope {
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

	/// Create new container branch with provided scope.
	///
	/// - Parameters:
	///   - scope: Scope of new child container (new branch).
	/// - Returns: New instance of ``Features`` container using
	/// provided scope and context value.
	@_disfavoredOverload @Sendable public func branch<Scope>(
		_ scope: Scope.Type
	) throws -> Features
	where Scope: FeaturesScope, Scope.Context == Void {
		try self.branch(
			Scope.self,
			context: Void()
		)
	}

	/// Create new container branch with provided scope.
	///
	/// - Parameters:
	///   - scope: Scope of new child container (new branch).
	///   - context: Context value for the new scope container.
	/// - Returns: New instance of ``Features`` container using
	/// provided scope and context value.
	@_disfavoredOverload @Sendable public func branch<Scope>(
		_ scope: Scope.Type,
		context: Scope.Context
	) throws -> Features
	where Scope: FeaturesScope {
		#if DEBUG
			guard !self.testingScope else {
				var contexts: Dictionary<AnyHashable, Any> = self.scopeContext as! Dictionary<AnyHashable, Any>
				contexts[ObjectIdentifier(Scope.self)] = context
				self.scopeContext = contexts
				return self
			}
		#endif

		guard let scopeRegistry: FeaturesRegistry = self.scopesRegistries[scope.identifier]
		else {
			throw
				FeaturesScopeUndefined
				.error(
					message: "Please define all required scopes on root features registry.",
					scope: scope
				)
				.asRuntimeWarning()
		}

		return .init(
			lock: self.lock,
			scope: scope.identifier,
			scopeContext: context,
			parent: self,
			registry: scopeRegistry,
			scopesRegistries: self.scopesRegistries,
			staticFeatures: self.staticFeatures
		)
	}

	/// Access a context value associated with scope.
	///
	/// This function allows to accessing context values
	/// of scopes in current container tree. It will throw
	/// an error if requested scope was not used in the tree.
	///
	/// - Parameters:
	///   - scopeType: Type of requested scope.
	///   - file: Source code file identifier used to track potential error.
	///   Filled automatically based on compile time constants.
	///   - line: Line in given source code file used to track potential error.
	///   Filled automatically based on compile time constants.
	/// - Returns: Context value for requested scope if any.
	@Sendable public func context<Scope>(
		for scopeType: Scope.Type,
		file: StaticString = #fileID,
		line: UInt = #line
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
		else if let parent: Features = self.parent {
			return try parent.context(for: Scope.self)
		}
		else {
			throw
				FeaturesScopeContextUnavailable
				.error(scope: Scope.self)
				.asRuntimeWarning()
		}
	}
}

extension Features {

	/// Access an instance of a ``StaticFeature``.
	///
	/// This function allows for accessing instances of static features.
	/// Static features are always available and shared
	/// across fatures container tree. All static features have
	/// to be defined when initializing root features container.
	///
	/// Static features are required to be available. If requested
	/// feature is not defined for any reason it will result in crash.
	///
	/// - Parameters:
	///   - featureType: Type of requested feature.
	///   - file: Source code file identifier used to track potential error.
	///   Filled automatically based on compile time constants.
	///   - line: Line in given source code file used to track potential error.
	///   Filled automatically based on compile time constants.
	/// - Returns: Instance of requested feature resolved by this container.
	@Sendable public func instance<Feature>(
		of featureType: Feature.Type = Feature.self,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Feature
	where Feature: StaticFeature {
		if let instance: StaticFeatureInstance = self.staticFeatures[Feature.identifier] {
			if let instance: Feature = instance.instance as? Feature {
				return instance
			}
			else {
				InternalInconsistency
					.error(
						message: "Feature is not matching expected type, please report a bug."
					)
					.appending(
						.message(
							"Feature instance is invalid",
							file: file,
							line: line
						)
					)
					.asFatalError()
			}
		}
		else {
			#if DEBUG
				let instance: Feature
				if self.testingScope {
					instance = .placeholder
					self.staticFeatures[Feature.identifier] = .init(
						instance: instance,
						implementation: "placeholder",
						file: file,
						line: line
					)
				}
				else {
					instance = .defaultImplementation(
						file: file,
						line: line
					)
					self.staticFeatures[Feature.identifier] = .init(
						instance: instance,
						implementation: "defaultImplementation",
						file: file,
						line: line
					)
				}
				return instance
			#else
				return .defaultImplementation(
					file: file,
					line: line
				)
			#endif
		}
	}
}

extension Features {

	/// Access an instance of a ``DynamicFeature``.
	///
	/// This function allows accessing instances of dynamic features.
	/// Access to the feature depends on provided ``FeatureLoader``.
	/// New instance becomes created each time if needed.
	/// If the feature supports caching it will be initialized and reused.
	/// If the feature was not defined for this container
	/// it will be provided by its parent if able. If no container
	/// has implementation of requested feature an error will be thrown.
	///
	/// Feature implementations that are defined in this container have priority
	/// over its parent containers. Even if parent container has already cached instance
	/// of requested feature but this container has its own definition (even the same one)
	/// it will create a new, local instance of that feature and provide it through this function.
	///
	/// Instances of features which context conform to ``DynamicFeatureContext``
	/// are additionally distinguished by the value of context. If the feature
	/// supports caching then multiple instances of it can be cached at once.
	///
	/// - Parameters:
	///   - featureType: Type of requested feature.
	///   - context: Context in which requested feature should be provided.
	///   - file: Source code file identifier used to track potential error.
	///   Filled automatically based on compile time constants.
	///   - line: Line in given source code file used to track potential error.
	///   Filled automatically based on compile time constants.
	/// - Returns: Instance of requested feature resolved by this container
	/// - Throws: When a feature loading fails or is not defined error is thrown.
	@Sendable public func instance<Feature>(
		of featureType: Feature.Type = Feature.self,
		context: Feature.Context,
		file: StaticString = #fileID,
		line: UInt = #line
	) throws -> Feature
	where Feature: DynamicFeature {
		try self.lock.withLock { () throws -> Feature in
			if let cachedFeature: Feature = try self.cache.get(featureType, context: context) {
				return cachedFeature
			}
			else {
				do {
					let feature: Feature =
						try self
						.factory
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
								self.cache.set(
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
								// replace branch description with current
								.with(self.branchDescription, for: "branch")
								.asRuntimeWarning()
						}
					}
					else {
						#if DEBUG
							if self.testingScope {
								let placeholder: Feature = .placeholder
								self.cache.set(
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
	}

	/// Access an instance of a ``DynamicFeature``.
	///
	/// This function allows accessing instances of features.
	/// Access to the feature depends on provided ``FeatureLoader``
	/// New instance becomes created each time if needed.
	/// If the feature supports caching it will be initialized and stored
	/// if needed. If the feature was not defined for this container
	/// it will be provided by its parent if able. If no container
	/// has implementation of requested feature an error will be thrown.
	///
	/// Feature implementations that are defined in this container have priority
	/// over its parent containers. Even if parent container has already cached instance
	/// of requested feature but this container has its own definition (even the same one)
	/// it will create a new, local instance of that feature and provide it through this function.
	///
	/// - Parameters:
	///   - featureType: Type of requested feature.
	///   - file: Source code file identifier used to track potential error.
	///   Filled automatically based on compile time constants.
	///   - line: Line in given source code file used to track potential error.
	///   Filled automatically based on compile time constants.
	/// - Returns: Instance of requested feature resolved by this container
	///   or throws an error otherwise.
	/// - Throws: When a feature loading fails or is not defined error is thrown.
	@Sendable public func instance<Feature>(
		of featureType: Feature.Type = Feature.self,
		file: StaticString = #fileID,
		line: UInt = #line
	) throws -> Feature
	where Feature: DynamicFeature, Feature.Context == ContextlessFeatureContext {
		try self.instance(
			of: featureType,
			context: .context,
			file: file,
			line: line
		)
	}

	/// Get an lazily resolved instance of the requested feature.
	///
	/// This function allows lazily accessing instances of features.
	/// It can be used to resolve circular dependencies
	/// between features.
	/// Access to the feature is postponed until first call
	/// for instance from returned ``LazyInstance``.
	/// ``LazyInstance`` caches result of loading ``Feature``
	/// and does not reach ``Features`` container again after first loading attempt.
	/// See ``instance(of:context:file:line:)`` for the details about loading features.
	///
	/// - Parameters:
	///   - featureType: Type of requested feature.
	///   - context: Context in which requested feature should be provided.
	///   - file: Source code file identifier used to track potential error.
	///   Filled automatically based on compile time constants.
	///   - line: Line in given source code file used to track potential error.
	///   Filled automatically based on compile time constants.
	/// - Returns: Lazy wrapper for instance of requested
	/// feature. Feature instance is not resolved
	/// immediately and can fail later.
	@Sendable public func lazyInstance<Feature>(
		of featureType: Feature.Type = Feature.self,
		context: Feature.Context,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> LazyInstance<Feature>
	where Feature: DynamicFeature {
		LazyInstance(
			{ @Sendable () throws -> Feature in
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

	/// Get an lazily resolved instance of the requested feature.
	///
	/// This function allows lazily accessing instances of features.
	/// It can be used to resolve circular dependencies
	/// between features.
	/// Access to the feature is postponed until first call
	/// for instance from returned ``LazyInstance``.
	/// ``LazyInstance`` caches result of loading ``Feature``
	/// and does not reach ``Features`` container again after first loading attempt.
	/// See ``instance(of:context:file:line:)`` for the details about loading features.
	///
	/// - Parameters:
	///   - featureType: Type of requested feature.
	///   - file: Source code file identifier used to track potential error.
	///   Filled automatically based on compile time constants.
	///   - line: Line in given source code file used to track potential error.
	///   Filled automatically based on compile time constants.
	/// - Returns: Lazy wrapper for instance of requested
	/// feature. Feature instance is not resolved
	/// immediately and can fail later.
	@Sendable public func lazyInstance<Feature>(
		of featureType: Feature.Type = Feature.self,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> LazyInstance<Feature>
	where Feature: DynamicFeature, Feature.Context == ContextlessFeatureContext {
		LazyInstance(
			{ @Sendable () throws -> Feature in
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

	/// Load and cache instance of requested feature if able.
	///
	/// This function allows preloading instances of features.
	/// It can be also used to force trigger operations that
	/// are performed after loading given feature without using it.
	/// If there is already an instance of requested feature this method does nothing.
	///
	/// If the feature supports caching it will be initialized and stored,
	/// otherwise the error will be thrown.
	/// If the feature was not defined for this container
	/// it will be provided by its parent if able. If no container
	/// has implementation of requested feature an error will be thrown.
	///
	/// Feature implementations that are defined in this container have priority
	/// over its parent containers. Even if parent container has already cached instance
	/// of requested feature but this container has its own definition (even the same one)
	/// it will create a new, local instance of that feature.
	///
	/// Instances of features which context conform to ``DynamicFeatureContext``
	/// are additionally distinguished by the value of context. If the feature
	/// supports caching then multiple instances of it can be cached at once.
	///
	/// - Parameters:
	///   - featureType: Type of requested feature.
	///   - context: Context in which requested feature should be loaded.
	///   - file: Source code file identifier used to track potential error.
	///   Filled automatically based on compile time constants.
	///   - line: Line in given source code file used to track potential error.
	///   Filled automatically based on compile time constants.
	/// - Throws: When a feature cannot be cached, loading it fails
	///   or it is not defined error is thrown.
	@Sendable public func loadIfNeeded<Feature>(
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

	/// Load and cache instance of requested feature if able.
	///
	/// This function allows preloading instances of features.
	/// It can be also used to force trigger operations that
	/// are performed after loading given feature without using it.
	/// If there is already an instance of requested feature this method does nothing.
	///
	/// If the feature supports caching it will be initialized and stored,
	/// otherwise the error will be thrown.
	/// If the feature was not defined for this container
	/// it will be provided by its parent if able. If no container
	/// has implementation of requested feature an error will be thrown.
	///
	/// Feature implementations that are defined in this container have priority
	/// over its parent containers. Even if parent container has already cached instance
	/// of requested feature but this container has its own definition (even the same one)
	/// it will create a new, local instance of that feature.
	///
	/// - Parameters:
	///   - featureType: Type of requested feature.
	///   - file: Source code file identifier used to track potential error.
	///   Filled automatically based on compile time constants.
	///   - line: Line in given source code file used to track potential error.
	///   Filled automatically based on compile time constants.
	/// - Throws: When a feature cannot be cached, loading it fails
	///   or it is not defined error is thrown.
	@Sendable public func loadIfNeeded<Feature>(
		_ featureType: Feature.Type,
		file: StaticString = #fileID,
		line: UInt = #line
	) throws
	where Feature: DynamicFeature, Feature.Context == ContextlessFeatureContext {
		try self.loadIfNeeded(
			featureType,
			context: .context,
			file: file,
			line: line
		)
	}
}

// swift-format-ignore: AllPublicDeclarationsHaveDocumentation
extension Features: CustomStringConvertible {

	public var description: String {
		"Features\(self.scope)"
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
		var description: String = ""
		var current: Features? = self
		while let features = current {
			description.append("\nNode: \(features.scope)")
			current = features.parent
		}
		return description
	}
}

#if DEBUG
	extension Features {

		/// Create container for testing.
		///
		/// `testing` ``Features`` container allows easier testing of features.
		/// It behaves differently from regular containers by automatically mocking
		/// required features except the one provided for initialization.
		///
		/// Testing container ignores scope assertions.
		///
		/// It is intended to test single implementation of a feature by mocking
		/// its regular environment and dependencies.
		///
		/// - Parameters:
		///   - featureType: Type of feature to be tested.
		///   - loader: Implementation of a feature to be tested.
		/// - Returns: Instance of ``Features`` container for testing purposes.
		public static func testing<Feature>(
			_ featureType: Feature.Type = Feature.self,
			_ loader: FeatureLoader<Feature>
		) -> Self
		where Feature: DynamicFeature {
			.init(
				lock: .nsRecursiveLock(),
				scope: TestingScope.identifier,
				scopeContext: Dictionary<AnyHashable, Any>(),
				parent: .none,
				registry: .init(dynamicFeaturesLoaders: [loader.asAnyLoader]),
				scopesRegistries: .init(),
				staticFeatures: .init()
			)
		}

		private var testingScope: Bool {
			self.scope == TestingScope.identifier
		}

		/// Force given instance in branch cache.
		///
		/// Set provided feature instance as a cached
		/// instance for given feature type and context.
		/// Replaces currently cached instance if any
		/// and sets cache entry with given instance
		/// even if currently used feature implementation
		/// does not support cache (i.e. disposable).
		///
		/// Parameters:
		///   - instance: Feature instance that will be cached.
		///   - context: Context value used to identify instance.
		///   - file: Source code file identifier used to track potential error.
		///   Filled automatically based on compile time constants.
		///   - line: Line in given source code file used to track potential error.
		///   Filled automatically based on compile time constants.
		@Sendable public func use<Feature>(
			instance: Feature,
			context: Feature.Context,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Feature: DynamicFeature {
			self.lock.withLock { () -> Void in
				self.cache
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
		}

		/// Force given instance in branch cache.
		///
		/// Set provided feature instance as a cached
		/// instance for given feature type and context.
		/// Replaces currently cached instance if any
		/// and sets cache entry with given instance
		/// even if currently used feature implementation
		/// does not support cache (i.e. disposable).
		///
		/// Parameters:
		///   - instance: Feature instance that will be cached.
		///   - file: Source code file identifier used to track potential error.
		///   Filled automatically based on compile time constants.
		///   - line: Line in given source code file used to track potential error.
		///   Filled automatically based on compile time constants.
		@Sendable public func use<Feature>(
			instance: Feature,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Feature: DynamicFeature, Feature.Context == ContextlessFeatureContext {
			self.use(
				instance: instance,
				context: .context,
				file: file,
				line: line
			)
		}

		/// Modify parts of features.
		///
		/// Patch can be used to mock and replace selected parts of features.
		/// If a feature is cached its current instance will be patched.
		/// If a feature is not cached new instance will be created if able.
		/// If feature instance cannot be created or its implementation
		/// does not support cache this method will fail.
		///
		/// - Parameters:
		///   - keyPath: Key path in feature to be replaced.
		///   - context: Context of patched feature, used to
		///   identify exact feature instance.
		///   - updated: Updated value of patched key path.
		///   - file: Source code file identifier used to track potential error.
		///   Filled automatically based on compile time constants.
		///   - line: Line in given source code file used to track potential error.
		///   Filled automatically based on compile time constants.
		@_disfavoredOverload @Sendable public func patch<Feature, Property>(
			_ keyPath: WritableKeyPath<Feature, Property>,
			context: Feature.Context,
			with updated: Property,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Feature: DynamicFeature {
			self.lock.withLock { () -> Void in
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
						.cache
						.getEntry(
							for: .key(
								for: Feature.self,
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

				feature[keyPath: keyPath] = updated
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
				self.cache.set(
					entry: cacheEntry,
					for: .key(
						for: Feature.self,
						context: context
					)
				)
			}
		}

		/// Modify parts of features.
		///
		/// Patch can be used to mock and replace selected parts of features.
		/// If a feature is cached its current instance will be patched.
		/// If a feature is not cached new instance will be created if able.
		/// If feature instance cannot be created or its implementation
		/// does not support cache this method will fail.
		///
		/// - Parameters:
		///   - keyPath: Key path in a feature to be replaced.
		///   - updated: Updated value of patched key path.
		///   - file: Source code file identifier used to track potential error.
		///   Filled automatically based on compile time constants.
		///   - line: Line in given source code file used to track potential error.
		///   Filled automatically based on compile time constants.
		@Sendable public func patch<Feature, Property>(
			_ keyPath: WritableKeyPath<Feature, Property>,
			with updated: Property,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Feature: DynamicFeature, Feature.Context == ContextlessFeatureContext {
			self.patch(
				keyPath,
				context: ContextlessFeatureContext.context,
				with: updated,
				file: file,
				line: line
			)
		}

		/// Modify parts of features.
		///
		/// Patch can be used to mock and replace selected parts of features.
		/// If a feature is cached its current instance will be patched.
		/// If a feature is not cached new instance will be created if able.
		/// If feature instance cannot be created or its implementation
		/// does not support cache this method will fail.
		///
		/// - Parameters:
		///   - featureType: Type of feature, used to identify mocked instance.
		///   - context: Feature context, used to identify mocked instance.
		///   - patching: Function used to mofify feature instance.
		///   - file: Source code file identifier used to track potential error.
		///   Filled automatically based on compile time constants.
		///   - line: Line in given source code file used to track potential error.
		///   Filled automatically based on compile time constants.
		@_disfavoredOverload @Sendable public func patch<Feature>(
			_ featureType: Feature.Type,
			context: Feature.Context,
			with patching: (inout Feature) -> Void,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Feature: DynamicFeature {
			self.lock.withLock { () -> Void in
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
						.cache
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
				self.cache.set(
					entry: cacheEntry,
					for: .key(
						for: featureType,
						context: context
					)
				)
			}
		}

		/// Modify parts of features.
		///
		/// Patch can be used to mock and replace selected parts of features.
		/// If a feature is cached its current instance will be patched.
		/// If a feature is not cached new instance will be created if able.
		/// If feature instance cannot be created or its implementation
		/// does not support cache this method will fail.
		///
		/// - Parameters:
		///   - featureType: Type of feature, used to identify mocked instance.
		///   - patching: Function used to mofify feature instance.
		///   - file: Source code file identifier used to track potential error.
		///   Filled automatically based on compile time constants.
		///   - line: Line in given source code file used to track potential error.
		///   Filled automatically based on compile time constants.
		@Sendable public func patch<Feature>(
			_ featureType: Feature.Type,
			with patching: (inout Feature) -> Void,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Feature: DynamicFeature, Feature.Context == ContextlessFeatureContext {
			self.patch(
				featureType,
				context: ContextlessFeatureContext.context,
				with: patching,
				file: file,
				line: line
			)
		}

		/// Check currently used implementation of feature.
		///
		/// Get the ``SourceCodeContext`` of requested feature implementation
		/// if able.
		///
		/// - Parameters
		///   - featureType: Type of feature to be checked.
		///   - context: Context of a feature to be checked.
		///   - file: Source code file identifier used to track potential error.
		///   Filled automatically based on compile time constants.
		///   - line: Line in given source code file used to track potential error.
		///   Filled automatically based on compile time constants.
		/// - Returns: ``SourceCodeContext`` of requested feature implementation
		/// if any or undefined context otherwise.
		@Sendable public func debugContext<Feature>(
			for featureType: Feature.Type,
			context: Feature.Context,
			file: StaticString = #fileID,
			line: UInt = #line
		) -> SourceCodeContext
		where Feature: DynamicFeature {
			self.lock.withLock { () -> SourceCodeContext in
				self
					.cache
					.getDebugContext(
						for: .key(
							for: featureType,
							context: context
						)
					)
					?? self
					.factory
					.loaderDebugContext(
						for: featureType,
						context: context
					)
					?? self
					.parent?
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
		}

		/// Check currently used implementation of feature.
		///
		/// Get the ``SourceCodeContext`` of requested feature implementation
		/// if able.
		///
		/// - Parameters
		///   - featureType: Type of feature to be checked.
		///   - file: Source code file identifier used to track potential error.
		///   Filled automatically based on compile time constants.
		///   - line: Line in given source code file used to track potential error.
		///   Filled automatically based on compile time constants.
		/// - Returns: ``SourceCodeContext`` of requested feature implementation
		/// if any or undefined context otherwise.
		@Sendable public func debugContext<Feature>(
			for featureType: Feature.Type,
			file: StaticString = #fileID,
			line: UInt = #line
		) -> SourceCodeContext
		where Feature: DynamicFeature, Feature.Context == ContextlessFeatureContext {
			self.debugContext(
				for: featureType,
				context: .context,
				file: file,
				line: line
			)
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

		/// Remove all currently cached feature instances from cache.
		///
		/// Clearing cache can be used for debugging and testing.
		/// It is not available in release builds.
		/// Exact result of this function call is undefined.
		@Sendable public func clearCache() {
			self.lock.withLock { () -> Void in
				self.cache.clear()
			}
		}
	}
#endif

#if DEBUG

	private enum TestingScope: FeaturesScope {

		typealias Context = Never
	}

#endif
