public protocol ImplementationOfStaticFeature<Feature> {

	associatedtype Feature: StaticFeature
	associatedtype Configuration = Void

	@Sendable nonisolated init(with configuration: Configuration)

	nonisolated var instance: Feature { get }
}
