/// Base interface for scopes which has no context.
///
/// ``FeaturesContextlessScope`` is an interface for defining ``FeaturesScope``
/// types that has no context.
public protocol FeaturesContextlessScope: FeaturesScope
where Context == Void {}
// warning: FeaturesContextlessScope should not be used internally. It defines different type
// from regular FeaturesScope with Context of Void which can lead to some compilation issues.
// It is intended to be used only externally as a convenience shortcut.
