import MQ

public protocol DisposableFeature<Context> {

	associatedtype Context = Void

	nonisolated static var placeholder: Self { get }
}

extension DisposableFeature {

	@_transparent
	internal nonisolated static func identifier() -> FeatureIdentifier {
		FeatureIdentifier(Self.self)
	}
}
