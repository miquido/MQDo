import MQ

/// Scope for grouping access to feature implementations.
///
/// ``FeaturesScope`` allows easy management of multiple implementations
/// and scoping access to certain features.
///
/// Scopes define features available in given ``Features`` container branch.
/// When an instance of ``Features`` container is deallocated associated features
/// will be also deallocated allowing granulated control
/// over lifetime of features using scopes.
/// Actual features used by the scope are defined using ``ScopedFeaturesRegistry``.
public protocol FeaturesScope {}

extension FeaturesScope {

	internal typealias Identifier = FeaturesScopeIdentifier

	internal static var identifier: Identifier {
		Identifier(scope: Self.self)
	}
}

/// Root scope of all feature containers.
///
/// Scope type always used by root ``Features`` container instances.
/// It cannot be used as a container branch.
public enum RootFeaturesScope: FeaturesScope {}
