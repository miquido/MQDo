import MQ

/// Container for accessing feature instances.
///
/// ``Features`` is a hierarchical, tree like container for managing access
/// to instances of features. It allows to propagate multiple implementations
/// of features, scoping access to it, caching feature instances and resolving
/// dependencies across the application.
///
/// Each instance of ``Features`` is associated with a type of ``FeaturesScope``.
/// It is used to distinguish scopes and available features in the application. Each container
/// has to be created as either root or branch of other existing container. It is allowed to have
/// multiple root containers and multiple instances of container with the same scope within single tree.
/// However it is allowed to have multiple trees at the same time.
/// It is also allowed to have multiple branches inside a single tree.
///
/// Each ``Features`` container is allowed to create and cache only instances of features that
/// were defined for its scope when creating root container or added when creating child for a branch.
/// When accessing a feature which is defined for current branch
/// scope a local feature copy will be used.
/// If it is not defined locally it will be provided from parent containers if able.
/// If requested feature is not defined in current tree branch it fails to load with an error.
public final class Features {
	// Features is temporarily a class, it will be converted
	// to a struct with new memory management of branches.
	private let treeLock: Lock
	private let container: FeaturesContainer?

	internal init(
		treeLock: Lock,
		container: FeaturesContainer
	) {
		self.treeLock = treeLock
		self.container = container
	}
}

extension Features: Sendable {}

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
	) -> Features {
		FeaturesContainer
			.root(registry: registry)
			.features
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
		self.container?
			.containsScope(
				scope,
				checkRecursively: checkRecursively,
				file: file,
				line: line
			)
			?? false
	}

	/// Create new container branch with provided scope.
	///
	/// - Parameter scope: Scope of new child container (new branch).
	/// - Returns: New instance of ``Features`` container using
	/// provided scope and context value.
	/// - Throws: When requested scope is not defined in root registry
	/// ``FeaturesScopeUndefined`` error is thrown.
	@_disfavoredOverload @Sendable public func branch<Scope>(
		_ scope: Scope.Type,
		file: StaticString = #fileID,
		line: UInt = #line
	) throws -> Features
	where Scope: FeaturesScope, Scope.Context == Void {
		try self.branch(
			Scope.self,
			context: Void(),
			file: file,
			line: line
		)
	}

	/// Create new container branch with provided scope.
	///
	/// - Parameters:
	///   - scope: Scope of new child container (new branch).
	///   - context: Context value for the new scope container.
	/// - Returns: New instance of ``Features`` container using
	/// provided scope and context value.
	/// - Throws: When requested scope is not defined in root registry
	/// ``FeaturesScopeUndefined`` error is thrown.
	@_disfavoredOverload @Sendable public func branch<Scope>(
		_ scope: Scope.Type,
		context: Scope.Context,
		file: StaticString = #fileID,
		line: UInt = #line
	) throws -> Features
	where Scope: FeaturesScope {
		guard let container: FeaturesContainer = self.container
		else {
			throw
				FeaturesContainerUnavailable
				.error(
					file: file,
					line: line
				)
		}

		return
			try container
			.branch(
				scope,
				context: context,
				file: file,
				line: line
			)
			.features
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
	/// - Throws: When context for the scope was not defined
	/// (scope was not used) throws ``FeaturesScopeContextUnavailable`` error.
	@Sendable public func context<Scope>(
		for scope: Scope.Type,
		file: StaticString = #fileID,
		line: UInt = #line
	) throws -> Scope.Context
	where Scope: FeaturesScope {
		guard let container: FeaturesContainer = self.container
		else {
			throw
				FeaturesContainerUnavailable
				.error(
					file: file,
					line: line
				)
		}

		return
			try container
			.context(
				for: scope,
				file: file,
				line: line
			)
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
		guard let container: FeaturesContainer = self.container
		else {
			//
			FeaturesContainerUnavailable
				.error(
					file: file,
					line: line
				)
				.asFatalError()
		}

		#if DEBUG
			return self.treeLock.withLock { () -> Feature in
				container
					.instance(
						of: featureType,
						file: file,
						line: line
					)
			}
		#else
			return
				container
				.instance(
					of: featureType,
					file: file,
					line: line
				)
		#endif
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
		guard let container: FeaturesContainer = self.container
		else {
			throw
				FeaturesContainerUnavailable
				.error(
					file: file,
					line: line
				)
		}

		return try self.treeLock.withLock { () throws -> Feature in
			try container
				.instance(
					of: featureType,
					context: context,
					file: file,
					line: line
				)
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

	/// Get an instance of the requested feature with deferred loading.
	///
	/// This function allows lazily accessing instances of features.
	/// It can be used to resolve circular dependencies
	/// between features.
	/// Access to the feature is postponed until first call
	/// for instance from returned ``DeferredInstance``.
	/// ``DeferredInstance`` caches result of loading ``Feature``
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
	@Sendable public func deferredInstance<Feature>(
		of featureType: Feature.Type = Feature.self,
		context: Feature.Context,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> DeferredInstance<Feature>
	where Feature: DynamicFeature {
		DeferredInstance(
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
	/// for instance from returned ``DeferredInstance``.
	/// ``DeferredInstance`` caches result of loading ``Feature``
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
	@Sendable public func deferredInstance<Feature>(
		of featureType: Feature.Type = Feature.self,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> DeferredInstance<Feature>
	where Feature: DynamicFeature, Feature.Context == ContextlessFeatureContext {
		DeferredInstance(
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
		guard let container: FeaturesContainer = self.container
		else {
			throw
				FeaturesContainerUnavailable
				.error(
					file: file,
					line: line
				)
		}

		return try self.treeLock.withLock { () throws -> Void in
			try container
				.loadIfNeeded(
					featureType,
					context: context,
					file: file,
					line: line
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
		"Features"
	}
}

// swift-format-ignore: AllPublicDeclarationsHaveDocumentation
extension Features: CustomDebugStringConvertible {

	public var debugDescription: String {
		#if DEBUG
			"Features tree:\n\(self.container?.branchDescription ?? "N/A")"
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
		) -> Features
		where Feature: DynamicFeature {
			let container: FeaturesContainer = .testing(
				featureType,
				loader
			)

			return container.features
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
			self.treeLock.withLock { () -> Void in
				self.container?
					.use(
						instance: instance,
						context: context,
						file: file,
						line: line
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
			self.treeLock.withLock { () -> Void in
				self.container?
					.patch(
						Feature.self,
						context: context,
						with: { (feature: inout Feature) in
							feature[keyPath: keyPath] = updated
						},
						file: file,
						line: line
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
			self.treeLock.withLock { () -> Void in
				self.container?
					.patch(
						Feature.self,
						context: context,
						with: patching,
						file: file,
						line: line
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
			self.treeLock.withLock { () -> SourceCodeContext in
				self.container?
					.debugContext(
						for: featureType,
						context: context,
						file: file,
						line: line
					)
					?? FeaturesContainerUnavailable
					.error(
						file: file,
						line: line
					)
					.with(Feature.self, for: "feature")
					.with("Unavailable", for: "implementation")
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
			self.treeLock.withLock { () -> Void in
				self.container?
					.setContext(
						context,
						for: scopeType,
						file: file,
						line: line
					)
			}
		}

		/// Remove all currently cached feature instances from cache.
		///
		/// Clearing cache can be used for debugging and testing.
		/// It is not available in release builds.
		/// Exact result of this function call is undefined.
		@Sendable public func clearCache() {
			self.treeLock.withLock { () -> Void in
				self.container?.clearCache()
			}
		}
	}
#endif
