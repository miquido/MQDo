import MQ

public protocol FeaturesScope {

	associatedtype Context: Sendable = Void
}

internal typealias FeaturesScopeIdentifier = ObjectIdentifier

extension FeaturesScope {

	@_transparent
	internal nonisolated static func identifier() -> FeaturesScopeIdentifier {
		FeaturesScopeIdentifier(Self.self)
	}
}
