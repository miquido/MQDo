/// Type erased, base protocol for implementing features.
///
/// ``AnyFeature`` is a type erased base for implementing features.
/// It should not be used directly to implement features though.
/// Please use ``LoadableFeature`` for implementing lazy loaded features.
///
/// Feature is an abstract piece of encapsulated, logically connected functions and state.
/// It can be treated as a fundamental building block for application in object-oriented style.
/// Features should be defined as an interface backed by structure instead of protocol.
/// It allows preparing well defined yet flexible interfaces with superior access control
/// (internal feature state cannot be accessed at all without use of any access modifiers),
/// mocking (ad-hoc replace of selected parts) and ability to easily provide multiple implementations.
/// All of the values and functions for feature structure should
/// be defined as a functions providing required functionalities.
/// The only exception are the values that are constant through the lifetime of the feature
/// which can be defined as a let constants.
///
/// ```swift
/// struct DiceRoll: LoadableFeature {
///   ...
///   // this value is constant for the lifetime of feature
///   let diceSides: Int
///   // this is the function required by this interface
///   var roll: () -> Int
/// }
/// ```
///
/// Feature struct should expose initializer for all of its fields
/// without any concrete implementation or modifications.
/// Concrete instance implementations should be defined depending on actual feature type.
/// For ``LoadableFeature`` it should be provided by ``FeatureLoader`` implementation.
/// However environmental features or adapters wrapping external dependencies might provide
/// concrete implementations that are defined outside of ``FeatureLoader``.
public protocol AnyFeature {}

extension AnyFeature {

	// Internal identifier for feature types.
	internal typealias TypeIdentifier = AnyHashable

	internal static var typeIdentifier: TypeIdentifier {
		ObjectIdentifier(Self.self)
	}

	internal static var typeDescription: String {
		"\(Self.self)"
	}

	internal var typeDescription: String {
		Self.typeDescription
	}
}
