import MQ

/// Scoped registry of feature implementations.
///
/// ``ScopedFeaturesRegistry`` is a container for defining feature implementations.
/// It is used to associate concrete implementations with given feature interfaces.
/// ``Features`` container initializes and forks with a scoped registry which defines
/// features available through that container. ``ScopedFeaturesRegistry`` is strongly
/// associated with ``FeaturesScope`` which is used to distinguish available
/// feature implementations for defined scopes preventing unwanted usage of features.
public struct ScopedFeaturesRegistry<Scope> where Scope: FeaturesScope {

	/// Typealias for functions used to adjust and setup
	/// instances of ``ScopedFeaturesRegistry``.
	public typealias SetupFunction = (inout ScopedFeaturesRegistry<Scope>) -> Void

	internal private(set) var registry: FeaturesRegistry

	internal init(
		scope: Scope.Type = Scope.self,
		loaders: Set<AnyFeatureLoader> = .init()
	) {
		self.registry = .init(loaders: loaders)
	}
}

extension ScopedFeaturesRegistry {

	/// Set implementation for a feature.
	///
	/// Associate provided ``FeatureLoader`` implementation with given feature.
	/// If there was already defined implementation for the same
	/// feature it will be replaced with the new one.
	///
	/// - Parameters:
	///   - featureType: Type of feature.
	///   - loader: Loader aka implementation of a feature that will
	///   be used in this registry.
	public mutating func use<Feature>(
		_ featureType: Feature.Type = Feature.self,
		_ loader: FeatureLoader<Feature>
	) where Feature: LoadableFeature {
		self.registry.use(loader: loader.asAnyLoader)
	}

	/// Remove implementation of a feature.
	///
	/// Remove given feature from the registry if able.
	/// This function has no effect if the feature was not
	/// registered before.
	///
	/// - Parameter featureType: Type of feature.
	public mutating func remove<Feature>(
		_ featureType: Feature.Type
	) where Feature: LoadableFeature {
		self.registry.removeLoader(for: featureType)
	}

	/// Set implementation for a feature.
	///
	/// Associate provided implementation with given feature.
	/// If there was already defined implementation for the same
	/// feature it will be replaced with the new one.
	///
	/// This method is equivalent of ``FeatureLoader.lazyLoaded`` implementation.
	///
	/// - Parameters:
	///   - featureType: Type of feature.
	///   - implementation: Name of given implementation used to identify feature implementation.
	///   By default it is name of a function enclosing invocation of this function.
	///   - load: Function which produces new instances of given feature.
	///   - loadingCompletion: Function allowing to execute initial operations after loading
	///   instance of feature. It can be also used to resolve circular dependencies.
	///   If loading completion fails (throws) then feature won't be cached
	///   nor returned from container. Default implementation does nothing.
	///   - cacheRemoval: Function called when instance of feature is going to be removed from cache.
	///   If this function will be called whenever instance of given feature will be removed from a cache.
	///   First instance of feature that will be created in given ``Features`` container will be cached.
	///   - file: Source code file identifier used to identify feature implementation.
	///   Filled automatically based on compile time constants.
	///   - line: Line in given source code file used to identify feature implementation.
	///   Filled automatically based on compile time constants.
	public mutating func useLazy<Feature>(
		_ featureType: Feature.Type = Feature.self,
		implementation: StaticString = #function,
		load: @escaping (Feature.Context, Features) throws -> Feature,
		loadingCompletion: @escaping (Feature, Features) throws -> Void = noop,
		cacheRemoval: @escaping (Feature) throws -> Void = noop,
		file: StaticString = #fileID,
		line: UInt = #line
	) where Feature: LoadableFeature {
		self.use(
			featureType,
			.lazyLoaded(
				featureType,
				implementation: implementation,
				load: load,
				loadingCompletion: loadingCompletion,
				cacheRemoval: cacheRemoval,
				file: file,
				line: line
			)
		)
	}

	/// Set implementation for a feature.
	///
	/// Associate provided implementation with given feature.
	/// If there was already defined implementation for the same
	/// feature it will be replaced with the new one.
	///
	/// This method is equivalent of ``FeatureLoader.disposable`` implementation.
	///
	/// - Parameters:
	///   - featureType: Type of feature.
	///   - implementation: Name of given implementation used to identify feature implementation.
	///   By default it is name of a function enclosing invocation of this function.
	///   - load: Function which produces new instances of given feature.
	///   - loadingCompletion: Function allowing to execute initial operations after loading
	///   instance of feature. It can be also used to resolve circular dependencies.
	///   Default implementation does nothing.
	///   - file: Source code file identifier used to identify feature implementation.
	///   Filled automatically based on compile time constants.
	///   - line: Line in given source code file used to identify feature implementation.
	///   Filled automatically based on compile time constants.
	public mutating func useDisposable<Feature>(
		_ featureType: Feature.Type = Feature.self,
		implementation: StaticString = #function,
		load: @escaping (Feature.Context, Features) throws -> Feature,
		loadingCompletion: @escaping (Feature, Features) throws -> Void = noop,
		file: StaticString = #fileID,
		line: UInt = #line
	) where Feature: LoadableFeature {
		self.use(
			featureType,
			.disposable(
				featureType,
				implementation: implementation,
				load: load,
				loadingCompletion: loadingCompletion,
				file: file,
				line: line
			)
		)
	}

	/// Set implementation for a feature.
	///
	/// Associate provided implementation with given feature.
	/// If there was already defined implementation for the same
	/// feature it will be replaced with the new one.
	///
	/// This method is equivalent of ``FeatureLoader.lazyLoaded`` implementation.
	///
	/// - Parameters:
	///   - featureType: Type of feature.
	///   - implementation: Name of given implementation used to identify feature implementation.
	///   By default it is name of a function enclosing invocation of this function.
	///   - load: Function which produces new instances of given feature.
	///   - loadingCompletion: Function allowing to execute initial operations after loading
	///   instance of feature. It can be also used to resolve circular dependencies.
	///   If loading completion fails (throws) then feature won't be cached
	///   nor returned from container. Default implementation does nothing.
	///   - cacheRemoval: Function called when instance of feature is going to be removed from cache.
	///   If this function will be called whenever instance of given feature will be removed from a cache.
	///   First instance of feature that will be created in given ``Features`` container will be cached.
	///   - file: Source code file identifier used to identify feature implementation.
	///   Filled automatically based on compile time constants.
	///   - line: Line in given source code file used to identify feature implementation.
	///   Filled automatically based on compile time constants.
	public mutating func useLazy<Feature, Tag>(
		_ featureType: Feature.Type = Feature.self,
		implementation: StaticString = #function,
		load: @escaping (Features) throws -> Feature,
		loadingCompletion: @escaping (Feature, Features) throws -> Void = noop,
		cacheRemoval: @escaping (Feature) throws -> Void = noop,
		file: StaticString = #fileID,
		line: UInt = #line
	) where Feature: LoadableFeature, Feature.Context == TagFeatureContext<Tag> {
		self.use(
			featureType,
			.lazyLoaded(
				featureType,
				implementation: implementation,
				load: load,
				loadingCompletion: loadingCompletion,
				cacheRemoval: cacheRemoval,
				file: file,
				line: line
			)
		)
	}

	/// Set implementation for a feature.
	///
	/// Associate provided implementation with given feature.
	/// If there was already defined implementation for the same
	/// feature it will be replaced with the new one.
	///
	/// This method is equivalent of ``FeatureLoader.disposable`` implementation.
	///
	/// - Parameters:
	///   - featureType: Type of feature.
	///   - implementation: Name of given implementation used to identify feature implementation.
	///   By default it is name of a function enclosing invocation of this function.
	///   - load: Function which produces new instances of given feature.
	///   - loadingCompletion: Function allowing to execute initial operations after loading
	///   instance of feature. It can be also used to resolve circular dependencies.
	///   Default implementation does nothing.
	///   - file: Source code file identifier used to identify feature implementation.
	///   Filled automatically based on compile time constants.
	///   - line: Line in given source code file used to identify feature implementation.
	///   Filled automatically based on compile time constants.
	public mutating func useDisposable<Feature, Tag>(
		_ featureType: Feature.Type = Feature.self,
		implementation: StaticString = #function,
		load: @escaping (Features) throws -> Feature,
		loadingCompletion: @escaping (Feature, Features) throws -> Void = noop,
		file: StaticString = #fileID,
		line: UInt = #line
	) where Feature: LoadableFeature, Feature.Context == TagFeatureContext<Tag> {
		self.use(
			featureType,
			.disposable(
				featureType,
				implementation: implementation,
				load: load,
				loadingCompletion: loadingCompletion,
				file: file,
				line: line
			)
		)
	}

	/// Set implementation for a feature.
	///
	/// Associate provided feature instance with given feature.
	/// If there was already defined implementation for the same
	/// feature it will be replaced with the new one.
	///
	/// This method is equivalent of ``FeatureLoader.constant`` implementation.
	///
	/// - Note: Only features which ``Context`` is ``TagFeatureContext`` can be constants.
	///
	/// - Parameters:
	///   - featureType: Type of feature.
	///   - implementation: Name of given implementation used to identify feature implementation.
	///   By default it is name of a function enclosing invocation of this function.
	///   - instance: Instance of a feature to be used as its implementation. It is wrapped
	///   by autoclosure to lazily initialize the instance. Feature will be initialized only on demand. The same instance will be used for all feature instance requests.
	///   - loadingCompletion: Function allowing to execute initial operations after loading
	///   instance of feature. This function will be called only once
	///   after first request for the feature instance.
	///   Default implementation does nothing.
	///   - file: Source code file identifier used to identify feature implementation.
	///   Filled automatically based on compile time constants.
	///   - line: Line in given source code file used to identify feature implementation.
	///   Filled automatically based on compile time constants.
	public mutating func useConstant<Feature, Tag>(
		_ featureType: Feature.Type = Feature.self,
		implementation: StaticString = #function,
		instance: @autoclosure @escaping () -> Feature,
		loadingCompletion: @escaping (Feature) -> Void = noop,
		file: StaticString = #fileID,
		line: UInt = #line
	) where Feature: LoadableFeature, Feature.Context == TagFeatureContext<Tag> {
		self.use(
			Feature.self,
			.constant(
				Feature.self,
				implementation: implementation,
				instance: instance(),
				loadingCompletion: loadingCompletion,
				file: file,
				line: line
			)
		)
	}
}

extension ScopedFeaturesRegistry where Scope == RootFeaturesScope {

	/// Define scope features for given scope.
	///
	/// Register a scope to be used in this features container tree.
	/// Registered scope has to define its features which will be available
	/// on this scope. If a feature is defined in given container scope and
	/// parent container scope also defines the same scope local instance will be used.
	/// If feature is not defined in given container scope but parent container
	/// has defined the feature parent instance will be used.
	///
	/// - Note: If given scope was already defined it will be replaced after defining it again.
	///
	/// - Parameters:
	///   - scope: Features scope which will be defined.
	///   - registrySetup: Function used to setup the scope feature implementations.
	public mutating func defineScope<DefinedScope>(
		_ scope: DefinedScope.Type = DefinedScope.self,
		registrySetup: ScopedFeaturesRegistry<DefinedScope>.SetupFunction
	) where DefinedScope: FeaturesScope {
		var registry: ScopedFeaturesRegistry<DefinedScope> = .init()
		registrySetup(&registry)

		self.useConstant(
			instance: FeaturesRegistryForScope<DefinedScope>(
				featuresRegistry: registry
			)
		)
	}
}
