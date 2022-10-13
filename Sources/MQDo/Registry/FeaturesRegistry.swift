public struct FeaturesRegistry<Scope>
where Scope: FeaturesScope {

	public typealias Setup = (inout Self) -> Void

	private let treeRegistryUpdate: ((inout FeaturesTreeRegistry) -> Void) -> Void

	internal init(
		treeRegistryUpdate: @escaping ((inout FeaturesTreeRegistry) -> Void) -> Void
	) {
		self.treeRegistryUpdate = treeRegistryUpdate
	}

	public mutating func use<Feature>(
		_ loader: some DisposableFeatureLoader<Feature>
	) where Feature: DisposableFeature {
		self.treeRegistryUpdate { (treeRegistry: inout FeaturesTreeRegistry) in
			treeRegistry.scopeFeatureLoaders[Scope.identifier]?.disposable[Feature.identifier] = loader
		}
	}

	public mutating func use<Feature>(
		_ loader: some CacheableFeatureLoader<Feature>
	) where Feature: CacheableFeature {
		self.treeRegistryUpdate { (treeRegistry: inout FeaturesTreeRegistry) in
			treeRegistry.scopeFeatureLoaders[Scope.identifier]?.cacheable[Feature.identifier] = loader
		}
	}
}

extension FeaturesRegistry
where Scope == RootFeaturesScope {

	internal init() {
		var treeRegistry: FeaturesTreeRegistry = .init()
		self.treeRegistryUpdate = { (update: (inout FeaturesTreeRegistry) -> Void) -> Void in
			update(&treeRegistry)
		}
	}

	internal var treeRegistry: FeaturesTreeRegistry {
		var registry: FeaturesTreeRegistry!
		self.treeRegistryUpdate { (treeRegistry: inout FeaturesTreeRegistry) -> Void in
			registry = treeRegistry
		}
		return registry
	}

	public mutating func defineScope<DefinedScope>(
		_ scope: DefinedScope.Type,
		registrySetup: FeaturesRegistry<DefinedScope>.Setup
	) where DefinedScope: FeaturesScope {
		self.treeRegistryUpdate { (treeRegistry: inout FeaturesTreeRegistry) in
			treeRegistry.scopeFeatureLoaders[DefinedScope.identifier] = .init()
		}
		var scopeRegistry: FeaturesRegistry<DefinedScope> = .init(treeRegistryUpdate: self.treeRegistryUpdate)
		registrySetup(&scopeRegistry)
	}

	public mutating func use<Feature>(
		static instance: Feature
	) where Feature: StaticFeature {
		self.treeRegistryUpdate { (treeRegistry: inout FeaturesTreeRegistry) in
			treeRegistry.staticFeatures[Feature.identifier] = instance
		}
	}
}
