internal protocol FeaturesTreeNode: FeaturesContainer {

	var featuresTree: FeaturesTree { get }
}

extension RootFeatures: FeaturesTreeNode {}
extension ScopedFeatures: FeaturesTreeNode {}
