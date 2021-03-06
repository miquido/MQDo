/// Feature context allowing to distinguish feature types while ignoring context value.
///
/// ``TagFeatureContext`` is a type of feature context
/// which allows to distinguish two feature types based on context type
/// while ignoring context value. ``Tag`` type will be used only as a phantom type
/// to distinguish types but its value will be ignored when accessing features.
public struct TagFeatureContext<Tag> {

	/// Get instance of ``TagFeatureContext`` with give ``Tag``.
	///
	/// You can use context instance as a placeholder
	/// for feature context when using ``TaggedLoadableFeature``
	/// or ``ContextlessLoadableFeature``.
	/// All instances of the ``TagFeatureContext`` with
	/// the same ``Tag`` type are treated as equal.
	public static var context: Self { .init() }

	private init() {}
}

// swift-format-ignore: AllPublicDeclarationsHaveDocumentation
extension TagFeatureContext: LoadableFeatureContext {

	public var identifier: AnyHashable {
		ObjectIdentifier(Self.self)
	}
}

// swift-format-ignore: AllPublicDeclarationsHaveDocumentation
extension TagFeatureContext: CustomStringConvertible {

	public var description: String {
		"Tag<\(Tag.self)>"
	}
}

// swift-format-ignore: AllPublicDeclarationsHaveDocumentation
extension TagFeatureContext: CustomDebugStringConvertible {

	public var debugDescription: String {
		"Tag<\(Tag.self)>"
	}
}

// swift-format-ignore: AllPublicDeclarationsHaveDocumentation
extension TagFeatureContext: CustomLeafReflectable {

	public var customMirror: Mirror {
		.init(
			self,
			children: [],
			displayStyle: .none
		)
	}
}
