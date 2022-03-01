import MQ

internal struct AnyFeatureLoader {

	internal typealias Load = (_ context: Any?, Features) throws -> AnyFeature
	internal typealias LoadingCompletion = (AnyFeature, Features) throws -> Void

	#if DEBUG
		internal let debugContext: SourceCodeContext
	#endif
	internal let featureType: AnyFeature.Type
	internal let load: Load
	internal let loadingCompletion: LoadingCompletion
	// feature will be cached if this function is not none
	internal let cacheRemoval: FeaturesCache.Removal?
}

extension AnyFeatureLoader: Hashable {

	internal static func == (
		_ lhs: AnyFeatureLoader,
		_ rhs: AnyFeatureLoader
	) -> Bool {
		// two loaders are treated as the same for the same feature type
		lhs.featureType == rhs.featureType
	}

	internal func hash(
		into hasher: inout Hasher
	) {
		hasher.combine(ObjectIdentifier(self.featureType))
	}
}

// swift-format-ignore: AllPublicDeclarationsHaveDocumentation
extension AnyFeatureLoader: CustomStringConvertible {

	internal var description: String {
		"AnyFeatureLoader for \(self.featureType)"
	}
}

// swift-format-ignore: AllPublicDeclarationsHaveDocumentation
extension AnyFeatureLoader: CustomDebugStringConvertible {

	internal var debugDescription: String {
		#if DEBUG
			"\(self.description)\n\(self.debugContext)"
		#else
			self.description
		#endif
	}
}

extension AnyFeatureLoader {

	internal func asLoader<Feature>(
		for featureType: Feature.Type
	) -> FeatureLoader<Feature>?
	where Feature: LoadableFeature {
		return .init(from: self)
	}
}
