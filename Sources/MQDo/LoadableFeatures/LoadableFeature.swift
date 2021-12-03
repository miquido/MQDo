import MQ

/// Base interface for features which can be dynamically loaded.
///
/// ``LoadableFeature`` is an interface for defining features supporting
/// dynamic loading and optional caching during application lifetime.
/// It extends the ``AnyFeature`` interface by adding ``Context`` allowing
/// additional configuration and optional distinction of feature instances.
/// Features implementing ``LoadableFeature`` protocol are allowed
/// to have implementations defined by ``FeatureLoader``, become dynamically loaded
/// and resolve its dependencies through ``Features`` container.
///
/// Features using ``Context`` only as a phantom type (to tag types) and ignore
/// its value (or can't have any value) can use ``TaggedLoadableFeature`` protocol
/// as a shortcut for defining it without additional boilerplate code.
///
/// Features which does not require any context can be implemented by using
/// ``ContextlessLoadableFeature`` protocol which is a shortcut for implementing
/// it without additional boilerplate code.
public protocol LoadableFeature: AnyFeature {

	/// Type of additional data required by feature.
	///
	/// ``Context`` type defines additional data that is required for creating
	/// instances of this feature. It can be used to configure or distinguish instances.
	/// When ``Context`` is used as a type parameter it can be used to distinguish
	/// types / implementations of the same feature based on the ``Context`` type
	/// regardless of actual value usage (phantom types).
	/// It can be also used to distinguish instances of the exact same type
	/// of feature if ``Context`` conforms to ``IdentifableFeatureContext`` protocol.
	/// It allows to i.e. cache multiple instances of the same feature based on the value of used context.
	/// This can be used i.e. to prepare fine granulated access to key/value storage
	/// by creating individual instances of storage for each used key.
	///
	/// Features using ``Context`` only as a phantom type (to tag types) and ignore
	/// its value (or can't have any value) can use ``TaggedLoadableFeature`` protocol
	/// as a shortcut for defining it without additional boilerplate code.
	///
	/// Features which does not require any context can be implemented by using
	/// ``ContextlessLoadableFeature`` protocol which is a shortcut for implementing
	/// it without additional boilerplate code.
	associatedtype Context

	#if DEBUG
		/// Placeholder implementation for development and testing.
		///
		/// Placeholder instance should implement all required functions
		/// by throwing or crashing with an error indicating lack of the feature.
		/// Using ``MQ.unimplemented`` placeholder is preferred way of
		/// implementing all required functions.
		///
		/// Placeholder instances are used to provide default implementations of features
		/// for ``Features`` containers dedicated for testing.
		static var placeholder: Self { get }
	#endif
}
