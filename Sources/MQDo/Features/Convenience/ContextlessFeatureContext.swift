/// Placeholder allowing to ignore feature context.
///
/// ``ContextlessFeatureContext`` is a placeholder
/// which allows to ignore feature context types and values.
public struct ContextlessFeatureContext {

	internal static var context: Self { .init() }

	private init() {}
}

extension ContextlessFeatureContext: Sendable {}

// swift-format-ignore: AllPublicDeclarationsHaveDocumentation
extension ContextlessFeatureContext: DynamicFeatureContext {

	public var identifier: ObjectIdentifier {
		ObjectIdentifier(Self.self)
	}
}

// swift-format-ignore: AllPublicDeclarationsHaveDocumentation
extension ContextlessFeatureContext: CustomStringConvertible {

	public var description: String {
		"\(Self.self)"
	}
}

// swift-format-ignore: AllPublicDeclarationsHaveDocumentation
extension ContextlessFeatureContext: CustomDebugStringConvertible {

	public var debugDescription: String {
		"\(Self.self)"
	}
}

// swift-format-ignore: AllPublicDeclarationsHaveDocumentation
extension ContextlessFeatureContext: CustomLeafReflectable {

	public var customMirror: Mirror {
		.init(
			self,
			children: [],
			displayStyle: .none
		)
	}
}
