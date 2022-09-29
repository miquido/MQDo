import MQ

/// Base interface for features which are defined statically.
///
/// ``StaticFeature`` is an interface for defining features
/// available for the lifetime of the application/container tree.
/// Features implementing ``StaticFeature`` protocol can't
/// relay on other features and have to be be defined when
/// preparing root of the ``Features`` container. All static
/// features have to be defined on the ``RootScope``.
public protocol StaticFeature: AnyFeature {

	#if DEBUG
		/// Placeholder instance.
		///
		/// Placeholder can be used to create instance of
		/// missing features when instance is required
		/// but never used. It can be also used as a base
		/// for preparing mocks in unit tests. When using
		/// ``TestingScope`` (aka testing ``Features`` container)
		/// placeholder instances are automatically created for
		/// missing features.
		///
		/// Placeholder instance should either use some default,
		/// immutable values and behaviors or (which is preferred)
		/// crash on any use except creating instance.
		///
		/// Note: Placeholder implementation should not be
		/// available in release builds.
		nonisolated static var placeholder: Self { get }
	#endif
}

extension StaticFeature {

	internal nonisolated static var identifier: StaticFeatureIdentifier {
		.identifier(for: Self.self)
	}

	internal nonisolated var identifier: StaticFeatureIdentifier {
		.identifier(for: Self.self)
	}
}
