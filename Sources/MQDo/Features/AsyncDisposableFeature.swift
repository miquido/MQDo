import MQ

public protocol AsyncDisposableFeature<Context> {

	associatedtype Context = Void

	nonisolated static var placeholder: Self { get }
}

extension AsyncDisposableFeature {

	@_transparent
	internal nonisolated static func identifier() -> FeatureIdentifier {
		FeatureIdentifier(Self.self)
	}
}
