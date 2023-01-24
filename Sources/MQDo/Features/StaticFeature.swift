import MQ

public protocol StaticFeature: Sendable {

	nonisolated static var placeholder: Self { get }
}

extension StaticFeature {

	@inline(__always)
	internal nonisolated static func identifier() -> FeatureIdentifier {
		FeatureIdentifier(Self.self)
	}
}
