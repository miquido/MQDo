internal struct FeaturesNodeRegistry<Scope>
where Scope: FeaturesScope {

	internal var dynamicFeatureLoaders: Dictionary<FeatureIdentifier, FeatureLoader>

	internal init(
		for scope: Scope.Type,
		dynamicFeatureLoaders: Dictionary<FeatureIdentifier, FeatureLoader>
	) {
		self.dynamicFeatureLoaders = dynamicFeatureLoaders
	}
}

extension FeaturesNodeRegistry: Sendable {}

extension FeaturesNodeRegistry {

	@inline(__always)
	@Sendable internal func loadInstance<Feature>(
		of _: Feature.Type,
		context: Feature.Context,
		using features: Features,
		file: StaticString,
		line: UInt
	) throws -> Feature
	where Feature: DisposableFeature {
		if let loader: FeatureLoader = self.dynamicFeatureLoaders[Feature.identifier()] {
			let instance: Feature =
				try loader
				.loadInstance(
					of: Feature.self,
					context: context,
					using: features
				)
			return instance
		}
		else {
			throw
				FeatureUndefined
				.error(
					feature: Feature.self,
					file: file,
					line: line
				)
		}
	}

	@inline(__always)
	@Sendable internal func loadInstance<Feature>(
		of _: Feature.Type,
		context: Feature.Context,
		using features: Features,
		file: StaticString,
		line: UInt
	) throws -> Feature
	where Feature: CacheableFeature {
		if let loader: FeatureLoader = self.dynamicFeatureLoaders[Feature.identifier()] {
			let instance: Feature =
				try loader
				.loadInstance(
					of: Feature.self,
					context: context,
					using: features
				)
			return instance
		}
		else {
			throw
				FeatureUndefined
				.error(
					feature: Feature.self,
					file: file,
					line: line
				)
		}
	}
}
