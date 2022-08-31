internal struct DynamicFeatureLoaderIdentifier {

	internal let typeIdentifier: AnyFeature.TypeIdentifier
	internal let typeDescription: String
	internal let contextDescription: String
	private let contextIdentifier: AnyDynamicFeatureContextIdentifier?

	internal init<Feature>(
		featureType: Feature.Type,
		// .none will match type regardless of context
		// .some will match only with same context value
		contextSpecifier: Feature.Context?
	) where Feature: DynamicFeature {
		self.typeIdentifier = featureType.typeIdentifier
		self.typeDescription = featureType.typeDescription
		self.contextDescription = contextSpecifier?.description ?? "none"
		self.contextIdentifier = contextSpecifier?.erasedIdentifier
	}
}

extension DynamicFeatureLoaderIdentifier: Sendable {}
extension DynamicFeatureLoaderIdentifier: Hashable {}

extension DynamicFeatureLoaderIdentifier {

	internal static func loaderIdentifier<Feature>(
		featureType: Feature.Type,
		contextSpecifier: Feature.Context?
	) -> Self
	where Feature: DynamicFeature {
		.init(
			featureType: featureType,
			contextSpecifier: contextSpecifier
		)
	}

	internal func matches<Feature>(
		featureType: Feature.Type
	) -> Bool
	where Feature: DynamicFeature {
		self.typeIdentifier == featureType.typeIdentifier
	}

	internal func matches<Feature>(
		featureType: Feature.Type,
		contextSpecifier: Feature.Context
	) -> Bool
	where Feature: DynamicFeature {
		self.typeIdentifier == featureType.typeIdentifier
			&& self.contextIdentifier.map { $0 == contextSpecifier.erasedIdentifier } ?? true
	}
}
