public func FeaturesRoot(
	registrySetup: FeaturesRegistry<RootFeaturesScope>.Setup,
	file: StaticString = #fileID,
	line: UInt = #line
) -> FeaturesContainer {
	var rootFeaturesRegistry: FeaturesRegistry<RootFeaturesScope> = .init()
	registrySetup(&rootFeaturesRegistry)
	let featuresTreeRegistry: FeaturesTreeRegistry = rootFeaturesRegistry.treeRegistry
	do {
		return try FeaturesRootNode(
			featuresTree: .init(
				featuresRegistry: featuresTreeRegistry
			),
			featuresRegistry:
				featuresTreeRegistry
				.nodeRegistry(
					for: RootFeaturesScope.self,
					file: file,
					line: line
				)
		)
	}
	catch {
		unreachable("It is not possible to RootFeaturesScope be not defined.")
	}
}
