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

	private let scopes: Set<FeaturesScope.Identifier>
	private var combinedScopes: Set<FeaturesScope.Identifier> {
		self.scopes.union(self.parent?.combinedScopes ?? .init())
	}
	private let lock: Lock
	private let factory: FeaturesFactory
	private var cache: FeaturesCache
	private let parent: Features?
	// swift-format-ignore: NeverUseImplicitlyUnwrappedOptionals
	private unowned var root: Features!

	private convenience init(
		scopes: Set<FeaturesScope.Identifier>,
		lock: Lock,  // a tree should use only one, shared lock
		parent: Features?,
		root: Features?,
		registry: FeaturesRegistry
	) {
		self.init(
			scopes: scopes,
			lock: lock,
			parent: parent,
			root: root,
			factory: .init(using: registry),
			cache: .init()
		)
	}

	private init(
		scopes: Set<FeaturesScope.Identifier>,
		lock: Lock,  // a tree should use only one, shared lock
		parent: Features?,
		root: Features?,
		factory: FeaturesFactory,
		cache: FeaturesCache
	) {
		self.scopes = scopes
		self.lock = lock
		self.parent = parent
		self.factory = factory
		self.cache = cache
		self.root = root ?? self
	}

	deinit {
		// ensure proper unloading of features
		self.cache.clear()
	}
}

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
			scopes: [RootFeaturesScope.identifier],
			lock: .osUnfairLock(),
			parent: .none,
			root: .none,
			registry: featuresRegistry.registry
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
	public func containsScope<Scope>(
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
			scopesToCheck = self.scopes
		}

		#if DEBUG
			return scopesToCheck.contains(scope.identifier)
				|| self.testingScope
		#else
			return scopesToCheck.contains(scope.identifier)
		#endif
	}

	/// Create new container branch with provided scopes.
	///
	/// - Parameters:
	///   - scope: Scope of new child container (new branch).
	///   - registrySetup: Optional customization of feature implementations (registry)
	///   for the child container. No customization will be done if not provided.
	/// - Returns: New instance of ``Features`` container using
	/// provided scope and optionally modified features registry.
	public func branch<Scope>(
		scope: Scope.Type = Scope.self,
		registrySetup: ScopedFeaturesRegistry<Scope>.SetupFunction = noop
	) -> Features
	where Scope: FeaturesScope {
		runtimeAssert(
			Scope.identifier != RootFeaturesScope.identifier,
			message: "Cannot use RootFeaturesScope for a child!"
		)

		var featuresRegistry: ScopedFeaturesRegistry<Scope>
		do {
			featuresRegistry =
				try .init(
					scope: Scope.self,
					registry: self
						.root  // scope registry has to be defined only on roots
						.instance(
							of: ScopeFeaturesRegistry.self,
							context: Scope.identifier
						)
						.featuresRegistry
				)
		}
		catch let error as FeatureLoadingFailed where error.cause is FeatureUndefined {
			FeaturesScopeUndefined
				.error(
					message: "Please define all required scopes on root features registry.",
					scope: Scope.self
				)
				.asAssertionFailure()

			// use empty registry for undefined scopes on nondebug builds
			featuresRegistry = .init()
		}
		catch {
			Unidentified
				.error(
					message:
						"FeaturesRegistryForScope was not available due to unknown error, please report the bug.",
					underlyingError: error
				)
				.asAssertionFailure()

			// use empty registry as a fallback on nondebug builds
			featuresRegistry = .init()
		}

		registrySetup(&featuresRegistry)

		return .init(
			scopes: [Scope.identifier],
			lock: self.lock,
			parent: self,
			root: self.root,
			registry: featuresRegistry.registry
		)
	}

	/// Create new container branch with provided scopes.
	///
	/// - Parameters:
	///   - scope: First scope of new child container (new branch).
	///   - scopes: Tail (rest) of new child container scopes.
	///   In case of conflicting features definitions resolved
	///   implementation will be the last one provided (from last
	///   scope in argument list containing conflicting feature).
	/// - Returns: New instance of ``Features`` container using
	/// provided scopes and combined features registry.
	@_disfavoredOverload public func branch(
		scope: any FeaturesScope.Type,
		_ scopes: any FeaturesScope.Type...
	) -> Features {
		let scopes: Array<FeaturesScope.Type> = [scope] + scopes

		runtimeAssert(
			!scopes.contains { $0 == RootFeaturesScope.self },
			message: "Cannot use RootFeaturesScope for a child container!"
		)

		var combinedFeaturesRegistry: FeaturesRegistry = .init()
		for scope in scopes {
			do {
				try combinedFeaturesRegistry.merge(
					self
						.root  // scope registry has to be defined only on roots
						.instance(
							of: ScopeFeaturesRegistry.self,
							context: scope.identifier
						)
						.featuresRegistry
				)
			}
			catch let error as FeatureLoadingFailed where error.cause is FeatureUndefined {
				FeaturesScopeUndefined
					.error(
						message: "Please define all required scopes on root features registry.",
						scope: scope
					)
					.asAssertionFailure()

				// ignore undefined scopes on nondebug builds
			}
			catch {
				Unidentified
					.error(
						message:
							"ScopeFeaturesRegistry was not available due to unknown error, please report the bug.",
						underlyingError: error
					)
					.asAssertionFailure()

				// ignore errors on nondebug builds
			}
		}

		return .init(
			scopes: Set(scopes.map { $0.identifier }),
			lock: self.lock,
			parent: self,
			root: self.root,
			registry: combinedFeaturesRegistry
		)
	}
}

extension Features {

	/// Get an instance of the requested feature if able.
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
	/// Instances of features which context conform to ``LoadableFeatureContext``
	/// are additionally distinguished by the value of context. If the feature
	/// supports caching then multiple instances of it can be cached at once.
	///
	/// - Parameters:
	///   - featureType: Type of requested feature.
	///   - context: Context in which requested feature should be provided.
	///   or throws an error otherwise.
	///   - file: Source code file identifier used to track potential error.
	///   Filled automatically based on compile time constants.
	///   - line: Line in given source code file used to track potential error.
	///   Filled automatically based on compile time constants.
	/// - Returns: Instance of requested feature resolved by this container
	/// - Throws: When a feature loading fails or is not defined error is thrown.
	public func instance<Feature>(
		of featureType: Feature.Type = Feature.self,
		context: Feature.Context,
		file: StaticString = #fileID,
		line: UInt = #line
	) throws -> Feature
	where Feature: LoadableFeature {
		try self.lock.withLock {
			if let cachedFeature: Feature = try self.cache.get(featureType, context: context) {
				return cachedFeature
			}
			else {
				do {
					let selfCopy: Features = self.noLockCopy()
					// synchronize cache after loading
					defer { self.cache = selfCopy.cache }
					let feature: Feature =
						try self
						.factory
						.load(
							featureType,
							context: context,
							within: selfCopy,
							cache: { (entry: FeaturesCache.Entry) in
								#if DEBUG
									var entry: FeaturesCache.Entry = entry
									entry
										.debugContext
										.set(context, for: "context")
									entry
										.debugContext
										.set(selfCopy.scopes, for: "scope")
								#endif
								selfCopy.cache.set(
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
				catch let error as FeatureLoadingFailed where error.cause is FeatureUndefined {
					if let parent: Features = self.parent {
						do {
							let parentCopy: Features = parent.noLockCopy()
							// synchronize cache after loading
							defer { parent.cache = parentCopy.cache }
							return
								try parentCopy
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
								.with(context, for: "context")
								.with(self.scopes, for: "scope")
								.with(self.branchDescription, for: "features")
						}
					}
					else {
						throw
							error
							.asTheError()
							.with(context, for: "context")
							.with(self.scopes, for: "scope")
							.with(self.branchDescription, for: "features")
					}
				}
				catch {
					throw
						error
						.asTheError()
						.with(context, for: "context")
						.with(self.scopes, for: "scope")
						.with(self.branchDescription, for: "features")
				}
			}
		}
	}

	/// Get an instance of the requested feature if able.
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
	public func instance<Feature, Tag>(
		of featureType: Feature.Type = Feature.self,
		file: StaticString = #fileID,
		line: UInt = #line
	) throws -> Feature
	where Feature: LoadableFeature, Feature.Context == TagFeatureContext<Tag> {
		try self.instance(
			of: featureType,
			context: .context,
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
	/// Instances of features which context conform to ``LoadableFeatureContext``
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
	public func loadIfNeeded<Feature>(
		_ featureType: Feature.Type,
		context: Feature.Context,
		file: StaticString = #fileID,
		line: UInt = #line
	) throws
	where Feature: LoadableFeature {
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
	public func loadIfNeeded<Feature, Tag>(
		_ featureType: Feature.Type,
		file: StaticString = #fileID,
		line: UInt = #line
	) throws
	where Feature: LoadableFeature, Feature.Context == TagFeatureContext<Tag> {
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

extension Features {

	// Copies without lock relay on single lock per container tree.
	// It allows to avoid recursion in locking and should be
	// used only with that purpose.
	private func noLockCopy() -> Self {
		.init(
			scopes: self.scopes,
			lock: .init(  // no locking
				acquire: noop,
				tryAcquire: always(true),
				release: noop
			),
			parent: self.parent,
			root: self.root,
			factory: self.factory,
			cache: self.cache
		)
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
		where Feature: LoadableFeature {
			Self.init(
				scopes: [TestingScope.identifier],
				lock: .init(  // no locking, test should be synchronous
					acquire: noop,
					tryAcquire: always(true),
					release: noop
				),
				parent: .none,
				root: .none,
				registry: .init(loaders: [loader.asAnyLoader])
			)
		}

		private var testingScope: Bool {
			self.scopes.contains(TestingScope.identifier)
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
		public func use<Feature>(
			instance: Feature,
			context: Feature.Context,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Feature: LoadableFeature {
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
							.with(context, for: "context"),
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
		public func use<Feature, Tag>(
			instance: Feature,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Feature: LoadableFeature, Feature.Context == TagFeatureContext<Tag> {
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
		@_disfavoredOverload public func patch<Feature, Property>(
			_ keyPath: WritableKeyPath<Feature, Property>,
			context: Feature.Context,
			with updated: Property,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Feature: LoadableFeature {
			self.lock.withLock { () -> Void in
				// load if needed ignoring errors
				do {
					let selfCopy: Features = self.noLockCopy()
					// synchronize cache after loading
					defer { self.cache = selfCopy.cache }
					try selfCopy.loadIfNeeded(Feature.self, context: context)
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
						.with(self.scopes, for: "scope")
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
						.with(self.scopes, for: "scope")
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
		public func patch<Feature, Property, Tag>(
			_ keyPath: WritableKeyPath<Feature, Property>,
			with updated: Property,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Feature: LoadableFeature, Feature.Context == TagFeatureContext<Tag> {
			self.patch(
				keyPath,
				context: TagFeatureContext<Tag>.context,
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
		@_disfavoredOverload public func patch<Feature>(
			_ featureType: Feature.Type,
			context: Feature.Context,
			with patching: (inout Feature) -> Void,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Feature: LoadableFeature {
			self.lock.withLock { () -> Void in
				// load if needed ignoring errors
				do {
					let selfCopy: Features = self.noLockCopy()
					// synchronize cache after loading
					defer { self.cache = selfCopy.cache }
					try selfCopy.loadIfNeeded(Feature.self, context: context)
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
						.with(self.scopes, for: "scope")
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
						.with(self.scopes, for: "scope")
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
		public func patch<Feature, Tag>(
			_ featureType: Feature.Type,
			with patching: (inout Feature) -> Void,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Feature: LoadableFeature, Feature.Context == TagFeatureContext<Tag> {
			self.patch(
				featureType,
				context: TagFeatureContext<Tag>.context,
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
		public func debugContext<Feature>(
			for featureType: Feature.Type,
			context: Feature.Context,
			file: StaticString = #fileID,
			line: UInt = #line
		) -> SourceCodeContext
		where Feature: LoadableFeature {
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
					.debugContext(for: featureType, context: context)
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
		public func debugContext<Feature, Tag>(
			for featureType: Feature.Type,
			file: StaticString = #fileID,
			line: UInt = #line
		) -> SourceCodeContext
		where Feature: LoadableFeature, Feature.Context == TagFeatureContext<Tag> {
			self.debugContext(
				for: featureType,
				context: .context,
				file: file,
				line: line
			)
		}

		/// Remove all currently cached feature instances from cache.
		///
		/// Clearing cache can be used for debugging and testing.
		/// It is not available in release builds.
		/// Exact result of this function call is undefined.
		public func clearCache() {
			self.lock.withLock {
				self.cache.clear()
			}
		}
	}
#endif

#if DEBUG

	private enum TestingScope: FeaturesScope {}

#endif
