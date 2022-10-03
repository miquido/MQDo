internal struct DynamicFeatureLoaderIdentifier {

	internal let typeIdentifier: AnyFeature.TypeIdentifier
	internal let typeDescription: String

	internal init<Feature>(
		featureType: Feature.Type
	) where Feature: AnyFeature {
		self.typeIdentifier = featureType.typeIdentifier
		self.typeDescription = featureType.typeDescription
	}
}

extension DynamicFeatureLoaderIdentifier: Sendable {}
extension DynamicFeatureLoaderIdentifier: Hashable {}

extension DynamicFeatureLoaderIdentifier {

	@Sendable internal static func loaderIdentifier<Feature>(
		featureType: Feature.Type
	) -> Self
	where Feature: AnyFeature {
		.init(featureType: featureType)
	}

	@Sendable internal func matches<Feature>(
		featureType: Feature.Type
	) -> Bool
	where Feature: AnyFeature {
		self.typeIdentifier == featureType.typeIdentifier
	}
}
