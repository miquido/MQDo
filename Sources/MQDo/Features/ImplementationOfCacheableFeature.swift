public protocol ImplementationOfCacheableFeature<Feature> {

	associatedtype Feature: CacheableFeature

	@Sendable nonisolated init(
		with context: Feature.Context,
		using features: Features
	) throws

	nonisolated var instance: Feature { get }
}

extension ImplementationOfCacheableFeature {

	public nonisolated static func loader(
		file: StaticString = #fileID,
		line: UInt = #line
	) -> FeatureLoader {
		.cacheable(
			Self.Feature.self,
			implementation: "\(Self.self)",
			load: { (context: Feature.Context, container: Features) throws -> Feature in
				try Self(
					with: context,
					using: container
				)
				.instance
			},
			file: file,
			line: line
		)
	}
}
