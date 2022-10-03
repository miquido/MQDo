import MQ

/// Base interface for features which can be dynamically loaded.
///
/// ``DynamicFeature`` is an interface for defining features supporting
/// dynamic loading and optional caching during application lifetime.
/// It extends the ``AnyFeature`` interface by defining ``Context`` allowing
/// additional configuration and distinction of feature instances.
/// Features implementing ``DynamicFeature`` protocol are allowed
/// to have implementations defined by ``FeatureLoader``, become dynamically loaded
/// and resolve its dependencies through ``Features`` container.
///
/// Features which does not require any context can be implemented by using
/// ``DynamicContextlessFeature`` protocol which is a shortcut for implementing
/// it without additional boilerplate code.
public protocol DynamicFeature: AnyFeature {

	/// Type of additional data required by the feature.
	///
	/// ``Context`` type defines additional data that is required
	/// for creating and accessing instances of this feature.
	/// It can be used to configure and distinguish instances.
	/// When ``Context`` is used as a type parameter it can be used to distinguish
	/// types / implementations of the same feature
	/// based on the ``Context`` type (phantom types).
	/// It can be also used to distinguish instances of the exact same type
	/// when ``Context`` implementation is based on
	/// ``IdentifiableFeatureContext`` protocol.
	/// It allows to i.e. cache multiple instances of the same feature based on the value of used context.
	///
	/// Features which does not require any context can be implemented by using
	/// ``DynamicContextlessFeature`` protocol which is a shortcut for implementing
	/// it without additional boilerplate code.
	associatedtype Context: Sendable

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

extension DynamicFeature {

	// Internal identifier for loadable feature loaders.
	internal typealias LoaderIdentifier = DynamicFeatureLoaderIdentifier

	@Sendable internal nonisolated static func loaderIdentifier() -> LoaderIdentifier {
		.loaderIdentifier(featureType: Self.self)
	}
}

extension DynamicFeature {

	// Internal identifier for loadable features instances.
	internal typealias InstanceIdentifier = DynamicFeatureInstanceIdentifier

	@Sendable internal nonisolated static func instanceIdentifier(
		context: Context
	) -> InstanceIdentifier {
		.init(featureType: Self.self)
	}

	@Sendable internal nonisolated func instanceIdentifier(
		context: Context
	) -> InstanceIdentifier {
		.init(featureType: Self.self)
	}
}

extension DynamicFeature
where Context: IdentifiableFeatureContext {

	@Sendable internal nonisolated static func instanceIdentifier(
		context: Context
	) -> InstanceIdentifier {
		.init(
			featureType: Self.self,
			context: context
		)
	}

	@Sendable internal nonisolated func instanceIdentifier(
		context: Context
	) -> InstanceIdentifier {
		.init(
			featureType: Self.self,
			context: context
		)
	}
}
