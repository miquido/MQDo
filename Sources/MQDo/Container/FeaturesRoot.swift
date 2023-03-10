public func FeaturesRoot(
	registrySetup: FeaturesRegistry<RootFeaturesScope>.Setup,
	file: StaticString = #fileID,
	line: UInt = #line
) -> FeaturesContainer {
	var rootFeaturesRegistry: FeaturesRegistry<RootFeaturesScope> = .init()
	registrySetup(&rootFeaturesRegistry)
	let featuresTreeRegistry: FeaturesTreeRegistry = rootFeaturesRegistry.registry
	do {
		return try RootFeatures(
			featuresTree: .init(
				featuresRegistry: featuresTreeRegistry
			),
			featuresRegistry:
				featuresTreeRegistry
				.registry(
					for: RootFeaturesScope.self,
					file: file,
					line: line
				)
		)
	}
	catch {
		unreachable("It is not possible that RootFeaturesScope is not defined.")
	}
}
