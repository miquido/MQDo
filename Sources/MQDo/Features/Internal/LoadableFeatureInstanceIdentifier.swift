internal struct LoadableFeatureInstanceIdentifier {

	private let typeIdentifier: AnyFeature.TypeIdentifier
	private let contextIdentifier: AnyHashable

	private init<Feature>(
		featureType: Feature.Type,
		context: Feature.Context
	) where Feature: LoadableFeature {
		self.typeIdentifier = featureType.typeIdentifier
		self.contextIdentifier = context.identifier
	}
}

extension LoadableFeatureInstanceIdentifier: Hashable {}

extension LoadableFeatureInstanceIdentifier {

	internal static func instanceIdentifier<Feature>(
		featureType: Feature.Type,
		context: Feature.Context
	) -> Self
	where Feature: LoadableFeature {
		.init(
			featureType: featureType,
			context: context
		)
	}
}
