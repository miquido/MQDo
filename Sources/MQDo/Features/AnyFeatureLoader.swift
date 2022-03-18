import MQ

internal struct AnyFeatureLoader {

	internal typealias Load = @MainActor (Any, FeaturesContainer) throws -> AnyFeature
	internal typealias LoadingCompletion = @MainActor (AnyFeature, Any, FeaturesContainer) throws -> Void
	internal typealias Unload = (AnyFeature) -> Void

	#if DEBUG
		internal let debugContext: SourceCodeContext
	#endif
	internal let featureType: AnyFeature.Type
	internal let load: Load
	internal let loadingCompletion: LoadingCompletion
	// feature will be cached if this function is not none
	internal let unload: Unload?
}

extension AnyFeatureLoader: CustomStringConvertible {

	internal var description: String {
		"AnyFeatureLoader for \(self.featureType)"
	}
}

extension AnyFeatureLoader: CustomDebugStringConvertible {

	internal var debugDescription: String {
		#if DEBUG
			"\(self.description)\n\(self.debugContext)"
		#else
			self.description
		#endif
	}
}
