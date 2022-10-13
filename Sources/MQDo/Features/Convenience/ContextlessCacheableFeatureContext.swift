/// Placeholder allowing to ignore feature context.
///
/// ``ContextlessFeatureContext`` is a placeholder
/// which allows to ignore feature context types and values.
public struct ContextlessCacheableFeatureContext {

	internal static var context: Self { .init() }

	private init() {}
}

extension ContextlessCacheableFeatureContext: Sendable {}

// swift-format-ignore: AllPublicDeclarationsHaveDocumentation
extension ContextlessCacheableFeatureContext: CacheableFeatureContext {

	public var identifier: ObjectIdentifier {
		ObjectIdentifier(Self.self)
	}
}

// swift-format-ignore: AllPublicDeclarationsHaveDocumentation
extension ContextlessCacheableFeatureContext: CustomStringConvertible {

	public var description: String {
		"\(Self.self)"
	}
}

// swift-format-ignore: AllPublicDeclarationsHaveDocumentation
extension ContextlessCacheableFeatureContext: CustomDebugStringConvertible {

	public var debugDescription: String {
		"\(Self.self)"
	}
}

// swift-format-ignore: AllPublicDeclarationsHaveDocumentation
extension ContextlessCacheableFeatureContext: CustomLeafReflectable {

	public var customMirror: Mirror {
		.init(
			self,
			children: [],
			displayStyle: .none
		)
	}
}
