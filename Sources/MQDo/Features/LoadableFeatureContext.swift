/// Feature context allowing to distinguish instances of the same feature type.
///
/// ``LoadableFeatureContext`` is a type used for defining
/// contexts for features. It allows to distinguish two feature
/// instances of the exact same type by its context value.
/// Two features of the same type which has different context identifiers
/// are treated as separate features similarly to those of different type.
public protocol LoadableFeatureContext {

	/// Identifier used to distinguish contexts of a feature.
	///
	/// Feature distinction for the same type of feature is made by using this property.
	/// Its value cannot change over time and should be different for values that are
	/// expected to distinguish feature instances.
	///
	/// If the type conforming to ``AnyFeatureContext`` is itself ``Hashable``
	/// default implementation of this property uses it to provide this property value.
	///
	/// - Warning: Value of ``identifier`` should not change over time.
	/// Once the context becomes initialized it should be constant for its lifetime.
	/// Changing it might result in undefined behavior.
	var identifier: AnyHashable { get }
}

// swift-format-ignore: AllPublicDeclarationsHaveDocumentation
extension LoadableFeatureContext where Self: Hashable {

	public var identifier: AnyHashable {
		self as AnyHashable
	}
}

extension LoadableFeatureContext {

	internal static var typeDescription: String {
		"\(Self.self)"
	}

	internal var typeDescription: String {
		Self.typeDescription
	}

	internal var description: String {
		"\(self)"  // it will use CustomStringConvertible if able
	}
}
