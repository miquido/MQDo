import MQ

public protocol CacheableFeature<Context>: Sendable {

	associatedtype Context: CacheableFeatureContext = CacheableFeatureVoidContext

	nonisolated static var placeholder: Self { get }
}

public typealias CacheableFeatureContext = Hashable & Sendable

public struct CacheableFeatureVoidContext: CacheableFeatureContext {

	public static let void: Self = .init()
}

extension CacheableFeature {

	@_transparent
	internal nonisolated static func identifier() -> FeatureIdentifier {
		FeatureIdentifier(Self.self)
	}
}
