/// Feature context allowing to distinguish instances of the same feature type.
///
/// ``DynamicFeatureContext`` is a type used for defining
/// contexts for features. It allows to distinguish two feature
/// instances of the exact same type by its context value.
/// Two features of the same type which has different context identifiers
/// are treated as separate features similarly to those of different type.
///
/// - Note: Contexts with matching ``identifier`` but different
/// actual value should be avoided when using cached features or
/// when using context specific implementations of features.
/// Cached features use context identifier as a part of its cache key
/// while ignoring actual context value and value itself is not
/// passed to an instance when picking it from cache. It might
/// result in undefined or unexpected behavior. However feature
/// implementations that do not use cache and create new instances
/// on demand can use context value to pass some arguments.
public protocol DynamicFeatureContext: Sendable {

	associatedtype Identifier: Hashable & Sendable

	/// Identifier used to distinguish contexts of a feature.
	///
	/// Feature distinction for the same type of feature is made by using this property.
	/// Its value cannot change over time and should be different for values that are
	/// expected to distinguish feature instances.
	///
	/// Default implementation of this property uses
	/// context itself to provide this value.
	///
	/// - Warning: Value of ``identifier`` should not change over time.
	/// Once the context becomes initialized it should be constant for its lifetime.
	/// Changing it might result in undefined behavior.
	nonisolated var identifier: Identifier { get }
}

// swift-format-ignore: AllPublicDeclarationsHaveDocumentation
extension DynamicFeatureContext
where Self: Hashable {

	// default implementation
	public nonisolated var identifier: Self {
		self
	}
}

extension DynamicFeatureContext {

	internal nonisolated static var typeDescription: String {
		"\(Self.self)"
	}

	internal nonisolated var typeDescription: String {
		Self.typeDescription
	}

	internal nonisolated var description: String {
		"\(self)"  // it will use CustomStringConvertible if able
	}

	internal nonisolated var erasedIdentifier: AnyDynamicFeatureContextIdentifier {
		.init(self.identifier)
	}
}
