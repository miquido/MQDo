internal struct CacheableFeatureInstanceIdentifier {

	private let typeIdentifier: AnyHashable
	private let contextIdentifier: AnyHashable

	internal init<Feature>(
		for _: Feature.Type,
		context: Feature.Context
	) where Feature: CacheableFeature {
		self.typeIdentifier = Feature.identifier
		self.contextIdentifier = context.identifier
	}
}

extension CacheableFeatureInstanceIdentifier: @unchecked Sendable {}

extension CacheableFeatureInstanceIdentifier: Hashable {}
