import MQ

internal struct DynamicFeatureLoader {

	internal typealias Identifier = DynamicFeatureLoaderIdentifier
	internal typealias Load = @Sendable (
		_ context: Any,
		_ container: FeaturesContainer
	) throws -> AnyFeature
	internal typealias LoadingCompletion = @Sendable (
		_ instance: AnyFeature,
		_ context: Any,
		_ container: FeaturesContainer
	) -> Void
	internal typealias Unload = @Sendable (
		_ instance: AnyFeature
	) -> Void

	#if DEBUG
		internal let debugContext: SourceCodeContext
	#endif
	internal let identifier: Identifier
	internal let load: Load
	internal let loadingCompletion: LoadingCompletion
	// feature will be cached if this function is not none
	internal let unload: Unload?
}

extension DynamicFeatureLoader: Sendable {}

// swift-format-ignore: AllPublicDeclarationsHaveDocumentation
extension DynamicFeatureLoader: CustomStringConvertible {

	internal var description: String {
		"FeatureLoader for \(self.identifier.typeDescription)"
	}
}

// swift-format-ignore: AllPublicDeclarationsHaveDocumentation
extension DynamicFeatureLoader: CustomDebugStringConvertible {

	internal var debugDescription: String {
		#if DEBUG
			"\(self.description)\n\(self.debugContext)"
		#else
			self.description
		#endif
	}
}
