/// Feature context allowing to distinguish instances of the same feature type.
///
/// ``IdentifiableFeatureContext`` is a type of feature context
/// which allows to distinguish two feature instances of the exact same type
/// by its context value. Any feature context not conforming to this protocol won't
/// distinguish two instances of feature. Two features of the same type which
/// context conform to this protocol and its value identifiers are not equal
/// are treated as separate features similarly to those of different type.
public protocol IdentifiableFeatureContext {

	/// Identifier used to distinguish contexts of a feature.
	///
	/// Feature distinction for the same type of feature is made by using this property.
	/// Its value cannot change over time and should be different for values that are
	/// expected to distinguish feature instances.
	///
	/// If the type conforming to ``IdentifiableFeatureContext`` is itself ``Hashable``
	/// default implementation of this property uses it to provide this property value.
	///
	/// - Warning: Value of ``identifier`` should not change over time.
	/// Once the context becomes initialized it should be constant for its lifetime.
	/// Changing it might result in undefined behavior.
	var identifier: AnyHashable { get }
}

// swift-format-ignore: AllPublicDeclarationsHaveDocumentation
extension IdentifiableFeatureContext
where Self: Hashable {

	public var identifier: AnyHashable {
		self as AnyHashable
	}
}
