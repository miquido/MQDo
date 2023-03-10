import MQ

public protocol StaticFeature: Sendable {

	nonisolated static var placeholder: Self { get }
}

extension StaticFeature {

	@_transparent
	internal nonisolated static func identifier() -> FeatureIdentifier {
		FeatureIdentifier(Self.self)
	}
}
