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
/// Features using ``Context`` only as a phantom type (to tag types) and ignore
/// its value (or can't have any value) can use ``TaggedDynamicFeature`` protocol
/// as a shortcut for defining it without additional boilerplate code.
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
	/// based on ``DynamicFeatureContext`` protocol implementation.
	/// It allows to i.e. cache multiple instances of the same feature based on the value of used context.
	/// This can be used i.e. to prepare fine granulated access to key/value storage
	/// by creating individual instances of storage for each used key.
	///
	/// Features using ``Context`` only as a phantom type (to tag types) and ignore
	/// its value (or can't have any value) can use ``TaggedDynamicFeature`` protocol
	/// as a shortcut for defining it without additional boilerplate code.
	///
	/// Features which does not require any context can be implemented by using
	/// ``DynamicContextlessFeature`` protocol which is a shortcut for implementing
	/// it without additional boilerplate code.
	associatedtype Context: DynamicFeatureContext

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
		static var placeholder: Self { get }
	#endif
}

extension DynamicFeature {

	// Internal identifier for loadable feature loaders.
	internal typealias LoaderIdentifier = DynamicFeatureLoaderIdentifier

	@Sendable internal static func loaderIdentifier(
		contextSpecifier: Context?
	) -> LoaderIdentifier {
		.loaderIdentifier(
			featureType: Self.self,
			contextSpecifier: contextSpecifier
		)
	}
}

extension DynamicFeature {

	// Internal identifier for loadable features instances.
	internal typealias InstanceIdentifier = DynamicFeatureInstanceIdentifier

	@Sendable internal static func instanceIdentifier(
		context: Context
	) -> InstanceIdentifier {
		.instanceIdentifier(
			featureType: Self.self,
			context: context
		)
	}
}
