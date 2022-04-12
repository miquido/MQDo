import MQ

internal struct LoadableFeatureLoader {

	internal typealias Identifier = LoadableFeatureLoaderIdentifier
	internal typealias Load = (_ context: LoadableFeatureContext, _ container: Features) throws -> AnyFeature
	internal typealias LoadingCompletion = (
		_ instance: AnyFeature, _ context: LoadableFeatureContext, _ container: Features
	)
		-> Void
	internal typealias Unload = (_ instance: AnyFeature) -> Void

	#if DEBUG
		internal let debugContext: SourceCodeContext
	#endif
	internal let identifier: Identifier
	internal let load: Load
	internal let loadingCompletion: LoadingCompletion
	// feature will be cached if this function is not none
	internal let unload: Unload?
}

// swift-format-ignore: AllPublicDeclarationsHaveDocumentation
extension LoadableFeatureLoader: CustomStringConvertible {

	internal var description: String {
		"FeatureLoader for \(self.identifier.typeDescription)"
	}
}

// swift-format-ignore: AllPublicDeclarationsHaveDocumentation
extension LoadableFeatureLoader: CustomDebugStringConvertible {

	internal var debugDescription: String {
		#if DEBUG
			"\(self.description)\n\(self.debugContext)"
		#else
			self.description
		#endif
	}
}
