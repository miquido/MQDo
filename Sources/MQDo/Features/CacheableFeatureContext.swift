public protocol CacheableFeatureContext: Sendable {

	associatedtype Identifier: Hashable & Sendable

	nonisolated var identifier: Identifier { get }
}

// swift-format-ignore: AllPublicDeclarationsHaveDocumentation
extension CacheableFeatureContext
where Self: Hashable {

	// default implementation
	public nonisolated var identifier: Self {
		self
	}
}
