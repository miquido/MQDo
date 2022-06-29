/// Base interface for features which can be dynamically loaded without context.
///
/// ``DynamicContextlessFeature`` is an interface for defining ``DynamicFeature``
/// types that has no context.
public protocol DynamicContextlessFeature: DynamicFeature
where Context == ContextlessFeatureContext {}
// warning: DynamicContextlessFeature should not be used internally. It defines different type
// from regular DynamicFeature with Context of ContextlessFeatureContext which can lead to some compilation issues.
// It is intended to be used only externally as a convenience shortcut.
