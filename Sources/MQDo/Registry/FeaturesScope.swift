import MQ

/// Scope for application features.
///
/// ``FeaturesScope`` allows easy management of multiple implementations
/// and scoping access to certain features.
///
/// Scopes define available features in given ``Features`` container context.
/// It can be use to provide implementations and access to certain features within container.
/// When an instance of ``Features`` container is deallocated associated features
/// will be also deallocated allowing granulated control over lifetime of application
/// parts using scopes. Actual features used by the scope are defined using ``ScopedFeaturesRegistry``.
public protocol FeaturesScope {}

extension FeaturesScope {

	internal typealias Identifier = FeaturesScopeIdentifier

	internal static var identifier: Identifier {
		Identifier(scope: Self.self)
	}
}
