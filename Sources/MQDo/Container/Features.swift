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
/// has to be created as either root or fork of other existing container. It is allowed to have
/// multiple root containers and multiple instances of container with the same scope within single tree.
/// It is also allowed to have multiple branches inside single tree.
///
/// Each ``Features`` container is allowed to create and cache only instances of features that
/// were defined for its scope when creating root container or added when creating child for a scope.
/// When accessing a feature which is defined for current scope local feature copy will be used.
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
	private var root: Features {
		if let parent: Features = parent {
			return parent.root
		}
		else {
			self.assertScope(RootFeaturesScope.self)
			return self
		}
	}

	private init(
		scopes: Set<FeaturesScope.Identifier>,
		lock: Lock = .nsRecursiveLock(),
		parent: Features?,
		registry: FeaturesRegistry
	) {
		self.scopes = scopes
		self.lock = lock
		self.parent = parent
		self.factory = .init(using: registry)
		self.cache = .init()
	}

	deinit {
		self
			.lock
			.withLock {
				do {
					try cache.clear()
				}
				catch {
					// we are not crashing on that error in release builds
					// it won't execute all cache removal methods but should
					// still work in most cases
					error
						.asTheError()
						.asAssertionFailure(message: "Features deinit failed")
				}
			}
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
	/// - Parameters:
	///   - lock: Lock used for synchronization of container data. Note that provided lock
	///   implementation has to support recursion. Default is ``Lock.nsRecursiveLock()``.
	///   - registry: ``ScopedFeaturesRegistry`` used to provide feature implementations
	///   for the container.
	/// - Returns: New instance of root ``Features`` container using provided feature
	/// implementation.
	public static func root(
		lock: Lock = .nsRecursiveLock(),
		registry: ScopedFeaturesRegistry<RootFeaturesScope>.SetupFunction
	) -> Self {
		var featuresRegistry: ScopedFeaturesRegistry<RootFeaturesScope> = .init()
		registry(&featuresRegistry)

		return .init(
			scopes: [RootFeaturesScope.identifier],
			lock: lock,
			parent: .none,
			registry: featuresRegistry.registry
		)
	}

	/// Verify scope of the container.
	///
	/// Check if scope of the container contains given scope.
	/// Assertion result is handled by ``runtimeAssert`` function.
	///
	///- Note: Checking combined scopes passes assertion if any of ``Features`` containers
	/// on this tree branch has requested scope. It does not mean that this particular instance has it.
	/// It can be used to verify access to certain scope of features in given tree branch.
	/// Checking not combined scope will always verify scope of this particular ``Features`` instance.
	///
	/// - Parameters:
	///   - scope: Scope to be verified.
	///   - checkCombined: Determines if scope verification should affect only
	///   this instance of ``Features`` container or should check tree recursively up to the root.
	///   Default is false which will only check explicitly defined scope for this ``Features`` instance.
	///   - file: Source code file identifier used to track potential error.
	///   Filled automatically based on compile time constants.
	///   - line: Line in given source code file used to track potential error.
	///   Filled automatically based on compile time constants.
	public func assertScope<Scope>(
		_ scope: Scope.Type,
		checkCombined: Bool = false,
		file: StaticString = #fileID,
		line: UInt = #line
	) where Scope: FeaturesScope {
		let scopesToCheck: Set<AnyHashable>

		if checkCombined {
			scopesToCheck = self.combinedScopes
		}
		else {
			scopesToCheck = self.scopes
		}

		#if DEBUG
			runtimeAssert(
				scopesToCheck.contains(scope.identifier) || self.testingScope,
				message: "Invalid scope of features! Missing \(scope)",
				file: file,
				line: line
			)
		#else
			runtimeAssert(
				scopesToCheck.contains(scope.identifier),
				message: "Invalid scope of features! Missing \(scope)",
				file: file,
				line: line
			)
		#endif
	}

	/// Create child container for a new scope with this features container as its parent.
	///
	/// - Parameters:
	///   - scope: Scope of new, child container.
	///   - registrySetup: Optional customization of feature implementations (registry)
	///   for the child container. No customization will be done if not provided.
	/// - Returns: New instance of ``Features`` container using provided feature
	/// scope and features registry with this instance of ``Features`` as its parent.
	public func child<Scope>(
		scope: Scope.Type = Scope.self,
		registrySetup: ScopedFeaturesRegistry<Scope>.SetupFunction = { _ in }
	) -> Features
	where Scope: FeaturesScope {
		runtimeAssert(
			Scope.self != RootFeaturesScope.self,
			message: "Cannot use RootFeaturesScope for a child!"
		)

		var featuresRegistry: ScopedFeaturesRegistry<Scope>
		do {
			featuresRegistry =
				try self
				.root  // scope registry has to be defined only on roots
				.instance(of: FeaturesRegistryForScope<Scope>.self)
				.featuresRegistry

		}
		catch let error as FeatureLoadingFailed where error.cause is FeatureUndefined {
			FeaturesScopeUndefined
				.error(
					message: "Please define all required scopes on root features registry.",
					scope: Scope.self
				)
				.asAssertionFailure()
			featuresRegistry = .init()  // use empty registry for undefined scopes
		}
		catch {
			Unidentified
				.error(
					message:
						"FeaturesRegistryForScope was not available due to unknown error, please report the bug.",
					underlyingError: error
				)
				.asFatalError()
		}

		registrySetup(&featuresRegistry)

		return .init(
			scopes: [Scope.identifier],
			lock: self.lock,
			parent: self,
			registry: featuresRegistry.registry
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
	/// Instances of features which context conform to ``IdentifiableFeatureContext``
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
			if let cachedFeature: Feature = self.cache.get(featureType, context: context) {
				return cachedFeature
			}
			else {
				do {
					var cacheSnapshot: FeaturesCache = self.cache
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
										.set(self.scopes, for: "scope")
								#endif
								cacheSnapshot.set(
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
					self.cache = cacheSnapshot  // it will be executed only if loading not throw
					return feature
				}
				catch let error as FeatureLoadingFailed where error.cause is FeatureUndefined {
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
								.with(context, for: "context")
								.with(self.scopes, for: "scope")
								.with(self.branchDescription, for: "features")
						}
					}
					else {
						#if DEBUG
							if self.testingScope {
								// intentionally not caching placeholders
								// it will be cached only when using `patch` function
								return featureType.placeholder
							}
							else {
								throw
									error
									.asTheError()
									.with(context, for: "context")
									.with(self.scopes, for: "scope")
									.with(self.branchDescription, for: "features")
							}
						#else
							throw
								error
								.asTheError()
								.with(context, for: "context")
								.with(self.scopes, for: "scope")
								.with(self.branchDescription, for: "features")
						#endif
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
	/// Instances of features which context conform to ``IdentifiableFeatureContext``
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
					acquireBefore: always(true),
					tryAcquire: always(true),
					release: noop
				),
				parent: .none,
				registry: .init(loaders: [loader.asAnyLoader])
			)
		}

		private var testingScope: Bool {
			self.scopes.contains(TestingScope.identifier)
		}

		/// Replace parts of features.
		///
		/// Patch can be used to mock and replace selected parts of features.
		/// If a feature is cached its current instance will be patched.
		/// If a feature is not cached new instance from placeholder implementation
		/// will be created, cached and patched instead.
		///
		/// - Note: Provided feature implementations will be ignored when patched
		/// feature is not in cache.
		///
		/// - Parameters:
		///   - keyPath: Key path in feature to be replaced.
		///   - context: Context of patched feature if context conforms to
		///   ``IdentifiableFeatureContext`` to identify exact feature instance.
		///   - updated: Updated value of patched key path.
		///   - file: Source code file identifier used to track potential error.
		///   Filled automatically based on compile time constants.
		///   - line: Line in given source code file used to track potential error.
		///   Filled automatically based on compile time constants.
		public func patch<Feature, Property>(
			_ keyPath: WritableKeyPath<Feature, Property>,
			context: Feature.Context,
			with updated: Property,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Feature: LoadableFeature, Feature.Context: IdentifiableFeatureContext {
			self.lock.withLock {
				var cacheEntry: FeaturesCache.Entry =
					self
					.cache
					.entry(
						for: .identifier(
							of: Feature.self,
							context: context
						)
					)
					?? .init(
						feature: Feature.placeholder,
						debugContext: .context(
							message: "Placeholder",
							file: file,
							line: line
						)
						.with(context, for: "context")
						.with(self.scopes, for: "scope"),
						removal: noop
					)
				withExtendedLifetime(cacheEntry) {
					guard var feature: Feature = cacheEntry.feature as? Feature
					else {
						InternalInconsistency
							.error(message: "Feature is not matching expected type")
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

					withExtendedLifetime(feature) {
						withExtendedLifetime(cacheEntry.feature) {
							withExtendedLifetime(feature[keyPath: keyPath]) {
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
								cache.set(
									entry: cacheEntry,
									for: .identifier(
										of: Feature.self,
										context: context
									)
								)
							}
						}
					}
				}
			}
		}

		/// Replace parts of features.
		///
		/// Patch can be used to mock and replace selected parts of features.
		/// If a feature is cached its current instance will be patched.
		/// If a feature is not cached new instance from placeholder implementation
		/// will be created, cached and patched instead.
		///
		/// - Note: Provided feature implementations will be ignored when patched
		/// feature is not in cache.
		///
		/// - Parameters:
		///   - keyPath: Key path in feature to be replaced.
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
			self.lock.withLock {
				var cacheEntry: FeaturesCache.Entry =
					self
					.cache
					.entry(
						for: .identifier(
							of: Feature.self,
							context: TagFeatureContext<Tag>.context
						)
					)
					?? .init(
						feature: Feature.placeholder,
						debugContext: .context(
							message: "Placeholder",
							file: file,
							line: line
						)
						.with(self.scopes, for: "scope"),
						removal: noop
					)
				withExtendedLifetime(cacheEntry.feature) {
					guard var feature: Feature = cacheEntry.feature as? Feature
					else {
						InternalInconsistency
							.error(message: "Feature is not matching expected type")
							.with(self.scopes, for: "scope")
							.with(Feature.self, for: "expected")
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

					withExtendedLifetime(feature) {
						withExtendedLifetime(cacheEntry.feature) {
							withExtendedLifetime(feature[keyPath: keyPath]) {
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
										.with(self.scopes, for: "scope")
									)
								self.cache.set(
									entry: cacheEntry,
									for: .identifier(
										of: Feature.self,
										context: TagFeatureContext<Tag>.context
									)
								)
							}
						}
					}
				}
			}
		}

		/// Replace parts of features.
		///
		/// Patch can be used to mock and replace selected parts of features.
		/// If a feature is cached its current instance will be patched.
		/// If a feature is not cached new instance from placeholder implementation
		/// will be created, cached and patched instead.
		///
		/// - Note: Provided feature implementations will be ignored when patched
		/// feature is not in cache.
		///
		/// - Parameters:
		///   - keyPath: Key path in feature to be replaced.
		///   - updated: Updated value of patched key path.
		///   - file: Source code file identifier used to track potential error.
		///   Filled automatically based on compile time constants.
		///   - line: Line in given source code file used to track potential error.
		///   Filled automatically based on compile time constants.
		@_disfavoredOverload
		public func patch<Feature, Property>(
			_ keyPath: WritableKeyPath<Feature, Property>,
			with updated: Property,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Feature: LoadableFeature {
			self.lock.withLock {
				var cacheEntry: FeaturesCache.Entry =
					self
					.cache
					.entry(
						for: .identifier(
							of: Feature.self,
							context: void
						)
					)
					?? .init(
						feature: Feature.placeholder,
						debugContext: .context(
							message: "Placeholder",
							file: file,
							line: line
						)
						.with(self.scopes, for: "scope"),
						removal: noop
					)
				withExtendedLifetime(cacheEntry.feature) {
					guard var feature: Feature = cacheEntry.feature as? Feature
					else {
						InternalInconsistency
							.error(message: "Feature is not matching expected type")
							.with(self.scopes, for: "scope")
							.with(Feature.self, for: "expected")
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
					withExtendedLifetime(feature) {
						withExtendedLifetime(cacheEntry.feature) {
							withExtendedLifetime(feature[keyPath: keyPath]) {
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
										.with(self.scopes, for: "scope")
									)
								self.cache.set(
									entry: cacheEntry,
									for: .identifier(
										of: Feature.self,
										context: void
									)
								)
							}
						}
					}
				}
			}
		}

		// TODO: add docs
		@available(*, unavailable)
		public func patch<Feature, Property>(
			_ keyPath: WritableKeyPath<Feature, Property>,
			with updated: Property,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Feature: LoadableFeature, Feature.Context: IdentifiableFeatureContext {
			unreachable("Method not available")
		}

		// TODO: add docs
		@available(*, unavailable)
		public func patch<Feature>(
			_ featureType: Feature.Type,
			with patching: (inout Feature) -> Void,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Feature: LoadableFeature, Feature.Context: IdentifiableFeatureContext {
			unreachable("Method not available")
		}

		// TODO: add docs
		public func patch<Feature>(
			_ featureType: Feature.Type,
			context: Feature.Context,
			with patching: (inout Feature) -> Void,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Feature: LoadableFeature, Feature.Context: IdentifiableFeatureContext {
			self.lock.withLock {
				var cacheEntry: FeaturesCache.Entry =
					self
					.cache
					.entry(
						for: .identifier(
							of: Feature.self,
							context: context
						)
					)
					?? .init(
						feature: Feature.placeholder,
						debugContext: .context(
							message: "Placeholder",
							file: file,
							line: line
						)
						.with(context, for: "context")
						.with(self.scopes, for: "scope"),
						removal: noop
					)
				withExtendedLifetime(cacheEntry) {
					guard var feature: Feature = cacheEntry.feature as? Feature
					else {
						InternalInconsistency
							.error(message: "Feature is not matching expected type")
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
					withExtendedLifetime(feature) {
						withExtendedLifetime(cacheEntry.feature) {
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
							cache.set(
								entry: cacheEntry,
								for: .identifier(
									of: Feature.self,
									context: context
								)
							)
						}
					}
				}
			}
		}

		// TODO: add docs
		public func patch<Feature, Tag>(
			_ featureType: Feature.Type,
			with patching: (inout Feature) -> Void,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Feature: LoadableFeature, Feature.Context == TagFeatureContext<Tag> {
			self.lock.withLock {
				var cacheEntry: FeaturesCache.Entry =
					self
					.cache
					.entry(
						for: .identifier(
							of: Feature.self,
							context: TagFeatureContext<Tag>.context
						)
					)
					?? .init(
						feature: Feature.placeholder,
						debugContext: .context(
							message: "Placeholder",
							file: file,
							line: line
						)
						.with(self.scopes, for: "scope"),
						removal: noop
					)
				withExtendedLifetime(cacheEntry) {
					guard var feature: Feature = cacheEntry.feature as? Feature
					else {
						InternalInconsistency
							.error(message: "Feature is not matching expected type")
							.with(self.scopes, for: "scope")
							.with(Feature.self, for: "expected")
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
					withExtendedLifetime(feature) {
						withExtendedLifetime(cacheEntry.feature) {
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
									.with(self.scopes, for: "scope")
								)
							cache.set(
								entry: cacheEntry,
								for: .identifier(
									of: Feature.self,
									context: TagFeatureContext<Tag>.context
								)
							)
						}
					}
				}
			}
		}

		// TODO: add docs
		@_disfavoredOverload
		public func patch<Feature>(
			_ featureType: Feature.Type,
			with patching: (inout Feature) -> Void,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Feature: LoadableFeature {
			self.lock.withLock {
				var cacheEntry: FeaturesCache.Entry =
					self
					.cache
					.entry(
						for: .identifier(
							of: Feature.self,
							context: void
						)
					)
					?? .init(
						feature: Feature.placeholder,
						debugContext: .context(
							message: "Placeholder",
							file: file,
							line: line
						)
						.with(self.scopes, for: "scope"),
						removal: noop
					)
				withExtendedLifetime(cacheEntry) {
					guard var feature: Feature = cacheEntry.feature as? Feature
					else {
						InternalInconsistency
							.error(message: "Feature is not matching expected type")
							.with(self.scopes, for: "scope")
							.with(Feature.self, for: "expected")
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
					withExtendedLifetime(feature) {
						withExtendedLifetime(cacheEntry.feature) {
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
									.with(self.scopes, for: "scope")
								)
							cache.set(
								entry: cacheEntry,
								for: .identifier(
									of: Feature.self,
									context: void
								)
							)
						}
					}
				}
			}
		}

		/// Check currently used implementation of feature.
		///
		/// Get the ``SourceCodeContext`` of requested feature implementation
		/// if able.
		///
		/// - Parameters
		///   - featureType: Type of feature to be checked.
		///   - context: Context of a feature to be checked. Can be none for
		///   features which context does not conform to ``IdentifiableFeatureContext``.
		///   - file: Source code file identifier used to track potential error.
		///   Filled automatically based on compile time constants.
		///   - line: Line in given source code file used to track potential error.
		///   Filled automatically based on compile time constants.
		/// - Returns: ``SourceCodeContext`` of requested feature implementation
		/// if any or undefined context otherwise.
		public func debugContext<Feature>(
			for featureType: Feature.Type,
			context: Feature.Context?,
			file: StaticString = #fileID,
			line: UInt = #line
		) -> SourceCodeContext
		where Feature: LoadableFeature {
			return self
				.cache
				.getDebugContext(
					for: .identifier(
						of: featureType,
						context: context as Any
					)
				)
				?? self
				.factory
				.loaderDebugContext(for: featureType)
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

		/// Remove all currently cached feature instances from cache.
		///
		/// Clearing cache can be used for debugging and testing.
		/// It is not available in release builds, all errors
		/// are ignored and there is no guarantee that some feature
		/// instances will not be still in use. Exact result of this
		/// function call is undefined.
		///
		/// - Throws: When any of cached features was not successfully
		/// removed from cache due to some error. When error was thrown
		/// cache might not be fully cleared and the operation has to be repeated.
		public func clearCache() throws {
			try self.lock.withLock {
				try self.cache.clear()
			}
		}
	}
#endif

/// Scope type always used by root ``Features`` container instances.
public enum RootFeaturesScope: FeaturesScope {}

#if DEBUG

	private enum TestingScope: FeaturesScope {}

#endif
