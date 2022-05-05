import MQ

/// Base interface for features which can be dynamically loaded.
///
/// ``LoadableFeature`` is an interface for defining features supporting
/// dynamic loading and optional caching during application lifetime.
/// It extends the ``AnyFeature`` interface by defining ``Context`` allowing
/// additional configuration and distinction of feature instances.
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

	/// Type of additional data required by the feature.
	///
	/// ``Context`` type defines additional data that is required
	/// for creating and accessing instances of this feature.
	/// It can be used to configure and distinguish instances.
	/// When ``Context`` is used as a type parameter it can be used to distinguish
	/// types / implementations of the same feature
	/// based on the ``Context`` type (phantom types).
	/// It can be also used to distinguish instances of the exact same type
	/// based on ``LoadableFeatureContext`` protocol implementation.
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
	associatedtype Context: LoadableFeatureContext
}

extension LoadableFeature {

	// Internal identifier for loadable feature loaders.
	internal typealias LoaderIdentifier = LoadableFeatureLoaderIdentifier

	internal static func loaderIdentifier(
		contextSpecifier: Context?
	) -> LoaderIdentifier {
		.loaderIdentifier(
			featureType: Self.self,
			contextSpecifier: contextSpecifier
		)
	}
}

extension LoadableFeature {

	// Internal identifier for loadable features instances.
	internal typealias InstanceIdentifier = LoadableFeatureInstanceIdentifier

	internal static func instanceIdentifier(
		context: Context
	) -> InstanceIdentifier {
		.instanceIdentifier(
			featureType: Self.self,
			context: context
		)
	}
}
