// Feature used to provide feature registry for a scope within a container tree.
// Always registered and provided by tree root.
internal struct FeaturesRegistryForScope<Scope> where Scope: FeaturesScope {

	internal let featuresRegistry: ScopedFeaturesRegistry<Scope>
}

extension FeaturesRegistryForScope: ContextlessLoadableFeature {

	internal static var placeholder: Self {
		Self(featuresRegistry: .init())
	}
}
