/// Feature context allowing to distinguish instances of the same feature type.
///
/// ``IdentifiableFeatureContext`` is a type used for defining
/// contexts for features. It allows to distinguish two feature
/// instances of the exact same type by its context value.
/// Two features of the same type which has different context identifiers
/// are treated as a separate features similarly to those of different type.
///
/// - Note: Contexts with matching ``identifier`` but different
/// actual value should be avoided. It might
/// result in undefined or unexpected behavior.
public protocol IdentifiableFeatureContext: Sendable {

	associatedtype Identifier: Hashable & Sendable

	/// Identifier used to distinguish contexts of a feature.
	///
	/// Feature distinction for the same type of feature is made by using this property.
	/// Its value cannot change over time and should be different for values that are
	/// expected to distinguish feature instances.
	///
	/// ``Hashable`` contexts have a default implementation using
	/// context itself to provide this value.
	///
	/// - Warning: Value of ``identifier`` should not change over time.
	/// Once the context becomes initialized it should be constant for its lifetime.
	/// Changing it might result in undefined behavior.
	nonisolated var identifier: Identifier { get }
}

// swift-format-ignore: AllPublicDeclarationsHaveDocumentation
extension IdentifiableFeatureContext
where Self: Hashable {

	// default implementation
	public nonisolated var identifier: Self {
		self
	}
}

extension IdentifiableFeatureContext {

	internal nonisolated var description: String {
		"\(self)"  // it will use CustomStringConvertible if able
	}

	internal nonisolated var erasedIdentifier: AnyIdentifiableFeatureContextIdentifier {
		.init(self.identifier)
	}
}
