public protocol LoadableContextualFeature: AnyFeature {

	associatedtype Context: IdentifiableFeatureContext
}
