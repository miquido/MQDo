import MQ

/// Scoped registry of feature implementations.
///
/// ``ScopedFeaturesRegistry`` is a container for defining feature implementations.
/// It is used to associate concrete implementations with a given feature interfaces.
/// ``Features`` container initializes and branches with scoped registry which defines
/// features available for that container branch. ``ScopedFeaturesRegistry`` is strongly
/// associated with ``FeaturesScope`` which is used to distinguish available
/// feature implementations for defined scopes preventing unwanted usage of features.
public struct ScopedFeaturesRegistry<Scope>
where Scope: FeaturesScope {

	/// Typealias for functions used to adjust and setup
	/// instances of ``ScopedFeaturesRegistry``.
	public typealias SetupFunction = (inout ScopedFeaturesRegistry<Scope>) -> Void

	internal private(set) var registry: FeaturesRegistry
	// to be used only by RootRegistry
	internal private(set) var staticFeatures: Dictionary<StaticFeatureIdentifier, StaticFeatureInstance> = .init()
	private var scopesFeatures: Dictionary<FeaturesScopeIdentifier, FeaturesRegistry> = .init()

	internal init(
		scope: Scope.Type = Scope.self,
		registry: FeaturesRegistry
	) {
		self.registry = registry
	}

	internal init(
		scope: Scope.Type = Scope.self
	) {
		self.init(
			scope: scope,
			registry: .init(dynamicFeaturesLoaders: .init())
		)
	}
}

extension ScopedFeaturesRegistry {

	/// Set implementation for a feature.
	///
	/// Associate provided ``FeatureLoader`` implementation with given feature interface.
	/// If there was already defined implementation for the same
	/// feature it will be replaced with the new one.
	///
	/// - Parameters
	/// - featureType: Type of registered feature.
	///  - loader: Loader aka implementation of a feature that will
	///   be used in this registry
	public mutating func use<Feature>(
		_ featureType: Feature.Type = Feature.self,
		_ loader: FeatureLoader<Feature>
	) where Feature: DynamicFeature {
		self.registry.use(loader: loader.asAnyLoader)
	}

	/// Remove implementation of a feature.
	///
	/// Remove given feature from the registry if able.
	/// This function has no effect if the feature was not
	/// registered before.
	///
	/// - Parameters
	///   - featureType: Type of feature which implementation
	///   will be removed.
	///   - contextSpecifier: Optional context specification, allows to select context
	///   specified implementation based on context value if any specified loader was defined.
	///   If set to none it will refer to general, default loader. Default is none.
	public mutating func remove<Feature>(
		_ featureType: Feature.Type,
		contextSpecifier: Feature.Context? = .none
	) where Feature: DynamicFeature {
		self.registry.removeLoader(
			for: .loaderIdentifier(
				featureType: featureType,
				contextSpecifier: contextSpecifier
			)
		)
	}
}

extension ScopedFeaturesRegistry
where Scope == RootFeaturesScope {

	/// Define new features scope within ``FeaturesContainer`` tree.
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
		_ scope: DefinedScope.Type,
		registrySetup: ScopedFeaturesRegistry<DefinedScope>.SetupFunction
	) where DefinedScope: FeaturesScope {
		var scopeRegistry: ScopedFeaturesRegistry<DefinedScope> = .init()
		registrySetup(&scopeRegistry)

		self.scopesFeatures[DefinedScope.identifier] = scopeRegistry.registry
	}

	public mutating func use<Feature>(
		_ implementation: StaticString = #function,
		static instance: Feature,
		file: StaticString = #file,
		line: UInt = #line
	) where Feature: StaticFeature {
		self.staticFeatures[instance.identifier] = .init(
			instance: instance,
			implementation: implementation,
			file: file,
			line: line
		)
	}

	internal var scopesRegistries: Dictionary<FeaturesScopeIdentifier, FeaturesRegistry> {
		self.scopesFeatures
	}
}
