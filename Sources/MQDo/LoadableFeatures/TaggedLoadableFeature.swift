/// Base interface for features which can be dynamically loaded and use its context as type tags.
///
/// ``TaggedLoadableFeature`` is an interface for defining ``LoadableFeature``
/// types that use context only as a type tag ignoring its values.
public protocol TaggedLoadableFeature: LoadableFeature
where Context == TagFeatureContext<Tag> {

	/// Type of context tag.
	///
	/// Tag is used to specify ``Context`` type which ignores values.
	/// It is directly used as a tag type for ``TagFeatureContext``
	/// used as this feature ``Context`` type.
	associatedtype Tag
}
// warning: TaggedLoadableFeature should not be used internally. It defines different type
// from regular LoadableFeature with Context of TagFeatureContext which can lead to some compilation issues.
// It is intended to be used only externally as a convenience shortcut.

// swift-format-ignore: AllPublicDeclarationsHaveDocumentation
extension TaggedLoadableFeature {

	// Swift 5.5 compiler puts a warning on this line but it has problems to properly
	// resolve types without it, despite that type constraint is already added
	public typealias Context = TagFeatureContext<Tag>
}
