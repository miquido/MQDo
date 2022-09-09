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

	/// Make instance of default implementation.
	///
	/// Default instance of ``StaticFeature`` will be used
	/// if not registered manually on ``RootScope`` features registry. This function does not have to return the same instance.
	/// Treat it more like a factory method instead to avoid
	/// unnecessary initialization before it is actually needed.
	/// If ``defaultImplementation`` should not be available
	/// leave it unimplemented (using default implementation).
	///
	/// Default implementation will not be used in test features
	/// container. Test feature containers will always use
	/// placeholder as a default implementation.
	///
	/// - Note: Using ``defaultImplementation`` will result in
	/// lazy loading of feature while registering it manually
	/// requires providing an already existing instance.
	///
	/// - Warning: Do not access any ``StaticFeature`` by its
	/// defaultImplementation. It is not required to always return
	/// the same instance and doing so might cause it to become a singleton.
	///
	/// - Parameters:
	///   - file: Source code file identifier used to track potential error.
	///   - line: Line in given source code file used to track potential error.
	@Sendable static func defaultImplementation(
		file: StaticString,
		line: UInt
	) -> Self

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

extension StaticFeature {

	@Sendable public static func defaultImplementation(
		file: StaticString,
		line: UInt
	) -> Self {
		Unimplemented
			.error(
				message:
					"Static feature without default implementation.",
				file: file,
				line: line
			)
			.with("\(Self.self)", for: "feature")
			.asFatalError(
				message:
					"Static features has to be defined when creating Features container. Please define it or implement `defaultImplementation` returning a valid instance. Remember to not access `defaultImplementation` directly."
			)
	}
}

extension StaticFeature {

	internal static var identifier: StaticFeatureIdentifier {
		.identifier(for: Self.self)
	}

	internal var identifier: StaticFeatureIdentifier {
		.identifier(for: Self.self)
	}
}
