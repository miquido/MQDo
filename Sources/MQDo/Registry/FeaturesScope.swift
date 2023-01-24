import MQ

public protocol FeaturesScope {

	associatedtype Context: Sendable = Void
}

internal typealias FeaturesScopeIdentifier = ObjectIdentifier

extension FeaturesScope {

	@inline(__always)
	internal nonisolated static func identifier() -> FeaturesScopeIdentifier {
		FeaturesScopeIdentifier(Self.self)
	}
}
