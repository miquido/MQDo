internal struct LoadableFeatureLoaderIdentifier {

	internal let typeIdentifier: AnyFeature.TypeIdentifier
	internal let typeDescription: String
	internal let contextDescription: String
	private let contextIdentifier: AnyHashable?

	internal init<Feature>(
		featureType: Feature.Type,
		// .none will match type regardless of context
		// .some will match only with same context value
		contextSpecifier: Feature.Context?
	) where Feature: LoadableFeature {
		self.typeIdentifier = featureType.typeIdentifier
		self.typeDescription = featureType.typeDescription
		self.contextDescription = contextSpecifier?.description ?? "none"
		self.contextIdentifier = contextSpecifier?.identifier
	}
}

extension LoadableFeatureLoaderIdentifier: Hashable {}

extension LoadableFeatureLoaderIdentifier {

	internal static func loaderIdentifier<Feature>(
		featureType: Feature.Type,
		contextSpecifier: Feature.Context?
	) -> Self
	where Feature: LoadableFeature {
		.init(
			featureType: featureType,
			contextSpecifier: contextSpecifier
		)
	}

	internal func matches<Feature>(
		featureType: Feature.Type
	) -> Bool
	where Feature: LoadableFeature {
		self.typeIdentifier == featureType.typeIdentifier
	}

	internal func matches<Feature>(
		featureType: Feature.Type,
		contextSpecifier: Feature.Context
	) -> Bool
	where Feature: LoadableFeature {
		self.typeIdentifier == featureType.typeIdentifier
			&& self.contextIdentifier.map { $0 == contextSpecifier.identifier } ?? true
	}
}
