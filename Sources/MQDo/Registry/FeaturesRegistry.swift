public struct FeaturesRegistry<Scope>
where Scope: FeaturesScope {

	public typealias Setup = (inout Self) -> Void

	private let scopeIdentifier: FeaturesScopeIdentifier
	private let treeRegistry: MutableTreeRegistry

	fileprivate init(
		treeRegistry: MutableTreeRegistry
	) {
		self.scopeIdentifier = Scope.identifier()
		self.treeRegistry = treeRegistry
	}

	public mutating func use(
		_ loader: FeatureLoader,
		file: StaticString = #fileID,
		line: UInt = #line
	) {
		#if DEBUG
		if self.treeRegistry.state.scopedDynamicFeatureLoaders[self.scopeIdentifier]?[loader.identifier] != nil {
			InternalInconsistency
				.error(
					message: "Overriding feature implementation in features registry - this us usually a bug.",
					file: file,
					line: line
				)
				.asRuntimeWarning()
		}  // else noop
		#endif
		self.treeRegistry.state.scopedDynamicFeatureLoaders[self.scopeIdentifier]?[loader.identifier] = loader
	}

	public mutating func use<Implementation>(
		_ implementation: Implementation.Type,
		file: StaticString = #fileID,
		line: UInt = #line
	) where Implementation: ImplementationOfDisposableFeature {
		let loader: FeatureLoader =
			Implementation
			.loader(
				file: file,
				line: line
			)
		#if DEBUG
		if self.treeRegistry.state.scopedDynamicFeatureLoaders[self.scopeIdentifier]?[loader.identifier] != nil {
			InternalInconsistency
				.error(
					message: "Overriding feature implementation in features registry - this us usually a bug.",
					file: file,
					line: line
				)
				.asRuntimeWarning()
		}  // else noop
		#endif
		self.treeRegistry.state.scopedDynamicFeatureLoaders[self.scopeIdentifier]?[loader.identifier] = loader
	}

	public mutating func use<Implementation>(
		_ implementation: Implementation.Type,
		file: StaticString = #fileID,
		line: UInt = #line
	) where Implementation: ImplementationOfCacheableFeature {
		let loader: FeatureLoader =
			Implementation
			.loader(
				file: file,
				line: line
			)
		#if DEBUG
		if self.treeRegistry.state.scopedDynamicFeatureLoaders[self.scopeIdentifier]?[loader.identifier] != nil {
			InternalInconsistency
				.error(
					message: "Overriding feature implementation in features registry - this us usually a bug.",
					file: file,
					line: line
				)
				.asRuntimeWarning()
		}  // else noop
		#endif
		self.treeRegistry.state.scopedDynamicFeatureLoaders[self.scopeIdentifier]?[loader.identifier] = loader
	}
}

extension FeaturesRegistry
where Scope == RootFeaturesScope {

	internal init() {
		self.scopeIdentifier = Scope.identifier()
		self.treeRegistry = .init()
	}

	@_transparent
	internal var registry: FeaturesTreeRegistry {
		self.treeRegistry.state
	}

	public mutating func defineScope<DefinedScope>(
		_ scope: DefinedScope.Type,
		file: StaticString = #fileID,
		line: UInt = #line,
		registrySetup: FeaturesRegistry<DefinedScope>.Setup
	) where DefinedScope: FeaturesScope {
		#if DEBUG
		if self.treeRegistry.state.scopedDynamicFeatureLoaders[DefinedScope.identifier()] != nil {
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
		self.treeRegistry.state.scopedDynamicFeatureLoaders[DefinedScope.identifier()] = .init()
		var scopeRegistry: FeaturesRegistry<DefinedScope> = .init(treeRegistry: self.treeRegistry)
		registrySetup(&scopeRegistry)
	}

	public mutating func use<Feature>(
		_ instance: Feature,
		file: StaticString = #fileID,
		line: UInt = #line
	) where Feature: StaticFeature {
		#if DEBUG
		if self.treeRegistry.state.staticFeatures[Feature.identifier()] != nil {
			InternalInconsistency
				.error(
					message: "Overriding feature implementation in features registry - this us usually a bug.",
					file: file,
					line: line
				)
				.asRuntimeWarning()
		}  // else noop
		#endif
		self.treeRegistry.state.staticFeatures[Feature.identifier()] = instance
	}

	public mutating func use<Implementation>(
		_ implementation: Implementation.Type,
		with configuration: Implementation.Configuration,
		file: StaticString = #fileID,
		line: UInt = #line
	) where Implementation: ImplementationOfStaticFeature {
		self.use(
			Implementation(with: configuration).instance,
			file: file,
			line: line
		)
	}

	public mutating func use<Implementation>(
		_ implementation: Implementation.Type,
		file: StaticString = #fileID,
		line: UInt = #line
	) where Implementation: ImplementationOfStaticFeature, Implementation.Configuration == Void {
		self.use(
			Implementation(with: Void()).instance,
			file: file,
			line: line
		)
	}
}

private final class MutableTreeRegistry {

	fileprivate var state: FeaturesTreeRegistry

	fileprivate init(
		_ state: FeaturesTreeRegistry = .init()
	) {
		self.state = state
	}
}
