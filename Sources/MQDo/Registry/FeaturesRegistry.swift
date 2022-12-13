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
		_ loader: some DisposableFeatureLoader<Feature>,
		file: StaticString = #fileID,
		line: UInt = #line
	) where Feature: DisposableFeature {
		self.treeRegistryUpdate { (treeRegistry: inout FeaturesTreeRegistry) in
			#if DEBUG
				if treeRegistry.scopeFeatureLoaders[Scope.identifier]?.disposable[Feature.identifier] != nil {
					InternalInconsistency
						.error(
							message: "Overriding feature implementation in features registry - this us usually a bug.",
							file: file,
							line: line
						)
						.with(Feature.self, for: "feature")
						.with(Scope.self, for: "scope")
						.asRuntimeWarning()
				}  // else noop
			#endif
			treeRegistry.scopeFeatureLoaders[Scope.identifier]?.disposable[Feature.identifier] = loader
		}
	}

	public mutating func use<Implementation>(
		_ implementation: Implementation.Type,
		file: StaticString = #fileID,
		line: UInt = #line
	) where Implementation: DisposableFeatureImplementation {
		self.treeRegistryUpdate { (treeRegistry: inout FeaturesTreeRegistry) in
			#if DEBUG
				if treeRegistry.scopeFeatureLoaders[Scope.identifier]?.disposable[Implementation.Feature.identifier] != nil {
					InternalInconsistency
						.error(
							message: "Overriding feature implementation in features registry - this us usually a bug.",
							file: file,
							line: line
						)
						.with(Implementation.Feature.self, for: "feature")
						.with(Scope.self, for: "scope")
						.asRuntimeWarning()
				}  // else noop
			#endif
			treeRegistry.scopeFeatureLoaders[Scope.identifier]?.disposable[Implementation.Feature.identifier] =
				DisposableFeatureImplementationLoader<Implementation>()
		}
	}

	public mutating func use<Feature>(
		_ loader: some CacheableFeatureLoader<Feature>,
		file: StaticString = #fileID,
		line: UInt = #line
	) where Feature: CacheableFeature {
		self.treeRegistryUpdate { (treeRegistry: inout FeaturesTreeRegistry) in
			#if DEBUG
				if treeRegistry.scopeFeatureLoaders[Scope.identifier]?.cacheable[Feature.identifier] != nil {
					InternalInconsistency
						.error(
							message: "Overriding feature implementation in features registry - this us usually a bug.",
							file: file,
							line: line
						)
						.with(Feature.self, for: "feature")
						.with(Scope.self, for: "scope")
						.asRuntimeWarning()
				}  // else noop
			#endif
			treeRegistry.scopeFeatureLoaders[Scope.identifier]?.cacheable[Feature.identifier] = loader
		}
	}

	public mutating func use<Implementation>(
		_ implementation: Implementation.Type,
		file: StaticString = #fileID,
		line: UInt = #line
	) where Implementation: CacheableFeatureImplementation {
		self.treeRegistryUpdate { (treeRegistry: inout FeaturesTreeRegistry) in
			#if DEBUG
				if treeRegistry.scopeFeatureLoaders[Scope.identifier]?.cacheable[Implementation.Feature.identifier] != nil {
					InternalInconsistency
						.error(
							message: "Overriding feature implementation in features registry - this us usually a bug.",
							file: file,
							line: line
						)
						.with(Implementation.Feature.self, for: "feature")
						.with(Scope.self, for: "scope")
						.asRuntimeWarning()
				}  // else noop
			#endif
			treeRegistry.scopeFeatureLoaders[Scope.identifier]?.cacheable[Implementation.Feature.identifier] =
				CacheableFeatureImplementationLoader<Implementation>()
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
		file: StaticString = #fileID,
		line: UInt = #line,
		registrySetup: FeaturesRegistry<DefinedScope>.Setup
	) where DefinedScope: FeaturesScope {
		self.treeRegistryUpdate { (treeRegistry: inout FeaturesTreeRegistry) in
			#if DEBUG
				if treeRegistry.scopeFeatureLoaders[DefinedScope.identifier] != nil {
					InternalInconsistency
						.error(
							message: "Overriding features scope in features registry - this us usually a bug.",
							file: file,
							line: line
						)
						.with(Scope.self, for: "scope")
						.asRuntimeWarning()
				}  // else noop
			#endif
			treeRegistry.scopeFeatureLoaders[DefinedScope.identifier] = .init()
		}
		var scopeRegistry: FeaturesRegistry<DefinedScope> = .init(treeRegistryUpdate: self.treeRegistryUpdate)
		registrySetup(&scopeRegistry)
	}

	public mutating func use<Feature>(
		static instance: Feature,
		file: StaticString = #fileID,
		line: UInt = #line
	) where Feature: StaticFeature {
		self.treeRegistryUpdate { (treeRegistry: inout FeaturesTreeRegistry) in
			#if DEBUG
				if treeRegistry.staticFeatures[Feature.identifier] != nil {
					InternalInconsistency
						.error(
							message: "Overriding feature implementation in features registry - this us usually a bug.",
							file: file,
							line: line
						)
						.with(Feature.self, for: "feature")
						.with(Scope.self, for: "scope")
						.asRuntimeWarning()
				}  // else noop
			#endif
			treeRegistry.staticFeatures[Feature.identifier] = instance
		}
	}

	public mutating func use<Implementation>(
		static implementation: Implementation.Type,
		file: StaticString = #fileID,
		line: UInt = #line
	) where Implementation: StaticFeatureImplementation {
		self.treeRegistryUpdate { (treeRegistry: inout FeaturesTreeRegistry) in
			#if DEBUG
				if treeRegistry.staticFeatures[Implementation.Feature.identifier] != nil {
					InternalInconsistency
						.error(
							message: "Overriding feature implementation in features registry - this us usually a bug.",
							file: file,
							line: line
						)
						.with(Implementation.Feature.self, for: "feature")
						.with(Scope.self, for: "scope")
						.asRuntimeWarning()
				}  // else noop
			#endif
			treeRegistry.staticFeatures[Implementation.Feature.identifier] = implementation.init().instance()
		}
	}
}
