internal struct FeaturesScopeRegistry<Scope>
where Scope: FeaturesScope {

	internal var dynamicFeatureLoaders: Dictionary<FeatureIdentifier, FeatureLoader>
	internal var asyncDynamicFeatureLoaders: Dictionary<FeatureIdentifier, AsyncFeatureLoader>

	internal init(
		for scope: Scope.Type,
		dynamicFeatureLoaders: Dictionary<FeatureIdentifier, FeatureLoader>,
		asyncDynamicFeatureLoaders: Dictionary<FeatureIdentifier, AsyncFeatureLoader>
	) {
		self.dynamicFeatureLoaders = dynamicFeatureLoaders
		self.asyncDynamicFeatureLoaders = asyncDynamicFeatureLoaders
	}
}

extension FeaturesScopeRegistry: Sendable {}

extension FeaturesScopeRegistry {

	@_transparent
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

	@_transparent
	@Sendable internal func loadInstance<Feature>(
		of _: Feature.Type,
		context: Feature.Context,
		using features: Features,
		file: StaticString,
		line: UInt
	) async throws -> Feature
	where Feature: AsyncDisposableFeature {
		if let loader: AsyncFeatureLoader = self.asyncDynamicFeatureLoaders[Feature.identifier()] {
			let instance: Feature =
				try await loader
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

	@_transparent
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
