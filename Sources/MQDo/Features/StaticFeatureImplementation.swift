public protocol StaticFeatureImplementation {

	associatedtype Feature: StaticFeature

	init()

	func instance() -> Feature
}
