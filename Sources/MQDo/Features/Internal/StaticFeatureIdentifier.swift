internal struct StaticFeatureIdentifier {

	private let typeIdentifier: AnyFeature.TypeIdentifier

	private init<Feature>(
		featureType: Feature.Type
	) where Feature: StaticFeature {
		self.typeIdentifier = featureType.typeIdentifier
	}
}

extension StaticFeatureIdentifier: @unchecked Sendable {}
extension StaticFeatureIdentifier: Hashable {}

extension StaticFeatureIdentifier {

	internal static func identifier<Feature>(
		for featureType: Feature.Type
	) -> Self
	where Feature: StaticFeature {
		.init(featureType: featureType)
	}
}
