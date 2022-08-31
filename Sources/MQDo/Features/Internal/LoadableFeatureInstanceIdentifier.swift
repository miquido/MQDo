internal struct DynamicFeatureInstanceIdentifier {

	private let typeIdentifier: AnyFeature.TypeIdentifier
	private let contextIdentifier: AnyHashable

	private init<Feature>(
		featureType: Feature.Type,
		context: Feature.Context
	) where Feature: DynamicFeature {
		self.typeIdentifier = featureType.typeIdentifier
		self.contextIdentifier = context.identifier
	}
}

extension DynamicFeatureInstanceIdentifier: @unchecked Sendable {}
extension DynamicFeatureInstanceIdentifier: Hashable {}

extension DynamicFeatureInstanceIdentifier {

	internal static func instanceIdentifier<Feature>(
		featureType: Feature.Type,
		context: Feature.Context
	) -> Self
	where Feature: DynamicFeature {
		.init(
			featureType: featureType,
			context: context
		)
	}
}
