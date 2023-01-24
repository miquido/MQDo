public protocol ImplementationOfStaticFeature<Feature> {

	associatedtype Feature: StaticFeature

	@Sendable nonisolated init()

	nonisolated var instance: Feature { get }
}
