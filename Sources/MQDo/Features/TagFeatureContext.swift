/// Feature context allowing to distinguish feature types while ignoring context value.
///
/// ``TagFeatureContext`` is a type of feature context
/// which allows to distinguish two feature types based on context type
/// while ignoring context value. ``Tag`` type will be used only as a phantom type
/// to distinguish types but its value (if any) will be ignored when accessing features.
///
/// ``TagFeatureContext`` is conforming to ``IdentifiableFeatureContext``
/// protocol in order to ensure described behavior.
public struct TagFeatureContext<Tag> {

	internal static var context: Self { .init() }

	private init() {}
}

// swift-format-ignore: AllPublicDeclarationsHaveDocumentation
extension TagFeatureContext: IdentifiableFeatureContext {

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
