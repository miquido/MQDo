public protocol ImplementationOfAsyncDisposableFeature<Feature> {

	associatedtype Feature: AsyncDisposableFeature

	@Sendable nonisolated init(
		with context: Feature.Context,
		using features: Features
	) async throws

	nonisolated var instance: Feature { get }
}

extension ImplementationOfAsyncDisposableFeature {

	public nonisolated static func loader(
		file: StaticString = #fileID,
		line: UInt = #line
	) -> AsyncFeatureLoader {
		.asyncDisposable(
			Self.Feature.self,
			implementation: "\(Self.self)",
			load: { (context: Feature.Context, container: Features) throws -> Feature in
				try await Self(
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
