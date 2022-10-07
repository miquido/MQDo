import MQ

/// Base interface for lazy loaded, cacheable features.
///
/// ``CacheableFeature`` TODO: to complete...
public protocol CacheableFeature: Sendable {

	/// TODO: to complete...
	associatedtype Context: CacheableFeatureContext = ContextlessCacheableFeatureContext

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
		/// immutable values and behaviors but failing in unit tests
		/// or crash on any use except creating instance.
		///
		/// Note: Placeholder implementation should not be
		/// available in release builds.
		nonisolated static var placeholder: Self { get }
	#endif
}

internal typealias CacheableFeatureIdentifier = ObjectIdentifier

extension CacheableFeature {

	internal nonisolated static var identifier: CacheableFeatureIdentifier {
		ObjectIdentifier(Self.self)
	}
}
