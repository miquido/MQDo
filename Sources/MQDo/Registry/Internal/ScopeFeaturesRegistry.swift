// Feature used to provide feature registry for a scope within a container tree.
// Always registered and provided by tree root.
internal struct ScopeFeaturesRegistry {

	internal let featuresRegistry: FeaturesRegistry
}

extension ScopeFeaturesRegistry: LoadableFeature {

	typealias Context = FeaturesScope.Identifier
}
