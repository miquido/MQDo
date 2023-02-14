internal struct FeaturesCache {

	private var values: Dictionary<Key, any CacheableFeature> = .init()
}

extension FeaturesCache: Sendable {}

extension FeaturesCache {

	@inline(__always)
	internal subscript<Feature>(
		_ feature: Feature.Type,
		_ context: Feature.Context
	) -> Feature?
	where Feature: CacheableFeature {
		get {
			let key: Key = .init(
				for: Feature.self,
				context: context
			)
			#if DEBUG
				guard let feature: any CacheableFeature = self.values[key]
				else { return .none }

				if let feature: Feature = feature as? Feature {
					return feature
				}
				else {
					InternalInconsistency
						.error(
							message: "Ignoring invalid cache entry."
						)
						.asRuntimeWarning(
							message: "Type mismatch in features cache, please report a bug."
						)
					return .none
				}
			#else
				return self.values[key] as? Feature
			#endif
		}
		set {
			let key: Key = .init(
				for: Feature.self,
				context: context
			)
			self.values[key] = newValue
		}
	}
}

extension FeaturesCache {

	fileprivate struct Key: Hashable, @unchecked Sendable {

		private let typeIdentifier: AnyHashable
		private let contextIdentifier: AnyHashable

		fileprivate init<Feature>(
			for _: Feature.Type,
			context: Feature.Context
		) where Feature: CacheableFeature {
			self.typeIdentifier = ObjectIdentifier(Feature.self)
			self.contextIdentifier = context
		}
	}
}
