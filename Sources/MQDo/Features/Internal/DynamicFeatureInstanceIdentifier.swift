internal struct DynamicFeatureInstanceIdentifier {

	private let typeIdentifier: AnyFeature.TypeIdentifier
	private let contextIdentifier: AnyIdentifiableFeatureContextIdentifier

	internal init<Feature>(
		featureType: Feature.Type,
		context: Feature.Context
	) where Feature: DynamicFeature, Feature.Context: IdentifiableFeatureContext {
		self.typeIdentifier = featureType.typeIdentifier
		self.contextIdentifier = context.erasedIdentifier
	}

	internal init<Feature>(
		featureType: Feature.Type
	) where Feature: DynamicFeature {
		self.typeIdentifier = featureType.typeIdentifier
		self.contextIdentifier = ContextlessFeatureContext.context.erasedIdentifier
	}
}

extension DynamicFeatureInstanceIdentifier: @unchecked Sendable {}
extension DynamicFeatureInstanceIdentifier: Hashable {}
