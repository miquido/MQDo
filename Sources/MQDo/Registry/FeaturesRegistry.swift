public struct FeaturesRegistry<Scope>
where Scope: FeaturesScope {

	public typealias Setup = (inout Self) -> Void

	private let scopeIdentifier: FeaturesScopeIdentifier
	private let treeRegistryUpdate: ((inout FeaturesTreeRegistry) -> Void) -> Void

	internal init(
		treeRegistryUpdate: @escaping ((inout FeaturesTreeRegistry) -> Void) -> Void
	) {
		self.scopeIdentifier = Scope.identifier()
		self.treeRegistryUpdate = treeRegistryUpdate
	}

	public mutating func use(
		_ loader: FeatureLoader,
		file: StaticString = #fileID,
		line: UInt = #line
	) {
		self.treeRegistryUpdate { (treeRegistry: inout FeaturesTreeRegistry) in
			#if DEBUG
				if treeRegistry.scopedDynamicFeatureLoaders[self.scopeIdentifier]?[loader.identifier] != nil {
					InternalInconsistency
						.error(
							message: "Overriding feature implementation in features registry - this us usually a bug.",
							file: file,
							line: line
						)
						.asRuntimeWarning()
				}  // else noop
			#endif
			treeRegistry.scopedDynamicFeatureLoaders[self.scopeIdentifier]?[loader.identifier] = loader
		}
	}

	public mutating func use<Implementation>(
		_ implementation: Implementation.Type,
		file: StaticString = #fileID,
		line: UInt = #line
	) where Implementation: ImplementationOfDisposableFeature {
		self.treeRegistryUpdate { (treeRegistry: inout FeaturesTreeRegistry) in
			let loader: FeatureLoader =
				Implementation
				.loader(
					file: file,
					line: line
				)
			#if DEBUG
				if treeRegistry.scopedDynamicFeatureLoaders[self.scopeIdentifier]?[loader.identifier] != nil {
					InternalInconsistency
						.error(
							message: "Overriding feature implementation in features registry - this us usually a bug.",
							file: file,
							line: line
						)
						.asRuntimeWarning()
				}  // else noop
			#endif
			treeRegistry.scopedDynamicFeatureLoaders[self.scopeIdentifier]?[loader.identifier] = loader
		}
	}

	public mutating func use<Implementation>(
		_ implementation: Implementation.Type,
		file: StaticString = #fileID,
		line: UInt = #line
	) where Implementation: ImplementationOfCacheableFeature {
		self.treeRegistryUpdate { (treeRegistry: inout FeaturesTreeRegistry) in
			let loader: FeatureLoader =
				Implementation
				.loader(
					file: file,
					line: line
				)
			#if DEBUG
				if treeRegistry.scopedDynamicFeatureLoaders[self.scopeIdentifier]?[loader.identifier] != nil {
					InternalInconsistency
						.error(
							message: "Overriding feature implementation in features registry - this us usually a bug.",
							file: file,
							line: line
						)
						.asRuntimeWarning()
				}  // else noop
			#endif
			treeRegistry.scopedDynamicFeatureLoaders[self.scopeIdentifier]?[loader.identifier] = loader
		}
	}
}

extension FeaturesRegistry
where Scope == RootFeaturesScope {

	internal init() {
		self.scopeIdentifier = Scope.identifier()
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
				if treeRegistry.scopedDynamicFeatureLoaders[DefinedScope.identifier()] != nil {
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
			treeRegistry.scopedDynamicFeatureLoaders[DefinedScope.identifier()] = .init()
		}
		var scopeRegistry: FeaturesRegistry<DefinedScope> = .init(treeRegistryUpdate: self.treeRegistryUpdate)
		registrySetup(&scopeRegistry)
	}

	public mutating func use<Feature>(
		_ instance: Feature,
		file: StaticString = #fileID,
		line: UInt = #line
	) where Feature: StaticFeature {
		self.treeRegistryUpdate { (treeRegistry: inout FeaturesTreeRegistry) in
			#if DEBUG
				if treeRegistry.staticFeatures[Feature.identifier()] != nil {
					InternalInconsistency
						.error(
							message: "Overriding feature implementation in features registry - this us usually a bug.",
							file: file,
							line: line
						)
						.asRuntimeWarning()
				}  // else noop
			#endif
			treeRegistry.staticFeatures[Feature.identifier()] = instance
		}
	}

	public mutating func use<Implementation>(
		_ implementation: Implementation.Type,
		file: StaticString = #fileID,
		line: UInt = #line
	) where Implementation: ImplementationOfStaticFeature {
		self.use(
			Implementation().instance,
			file: file,
			line: line
		)
	}
}
