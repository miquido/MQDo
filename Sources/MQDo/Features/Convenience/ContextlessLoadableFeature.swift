/// Base interface for features which can be dynamically loaded without context.
///
/// ``ContextlessLoadableFeature`` is an interface for defining ``LoadableFeature``
/// types that has no context.
public protocol ContextlessLoadableFeature: TaggedLoadableFeature
where Tag == Never {}
// warning: ContextlessLoadableFeature should not be used internally. It defines different type
// from regular LoadableFeature with Context of TagFeatureContext<Never> which can lead to some compilation issues.
// It is intended to be used only externally as a convenience shortcut.

// swift-format-ignore: AllPublicDeclarationsHaveDocumentation
extension ContextlessLoadableFeature {

	// Swift 5.5 compiler puts a warning on this line but it has problems to properly
	// resolve types without it, despite that type constraint is already added
	public typealias Tag = Never
}
