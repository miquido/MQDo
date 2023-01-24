import MQ

public protocol DisposableFeature<Context> {

	associatedtype Context = Void

	nonisolated static var placeholder: Self { get }
}

extension DisposableFeature {

	@inline(__always)
	internal nonisolated static func identifier() -> FeatureIdentifier {
		FeatureIdentifier(Self.self)
	}
}
