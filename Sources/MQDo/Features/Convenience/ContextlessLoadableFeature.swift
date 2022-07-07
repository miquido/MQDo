/// Base interface for features which can be dynamically loaded without context.
///
/// ``ContextlessLoadableFeature`` is an interface for defining ``LoadableFeature``
/// types that has no context.
public protocol ContextlessLoadableFeature: LoadableFeature
where Context == ContextlessFeatureContext {}
// warning: ContextlessLoadableFeature should not be used internally. It defines different type
// from regular LoadableFeature with Context of ContextlessFeatureContext which can lead to some compilation issues.
// It is intended to be used only externally as a convenience shortcut.
