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
public protocol FeaturesScope {

	/// Context associated with the scope.
	///
	/// Scope context is a value associated with
	/// features container using that scope.
	/// It can be accessed by features loading
	/// within that container.
	associatedtype Context
}

extension FeaturesScope {

	internal typealias Identifier = FeaturesScopeIdentifier

	internal nonisolated static var identifier: Identifier {
		Identifier(scope: Self.self)
	}
}
