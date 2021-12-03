internal struct FeaturesRegistry {

	private var featureLoaders: Dictionary<AnyFeature.Identifier, AnyFeatureLoader>

	internal init(
		loaders: Set<AnyFeatureLoader> = .init()
	) {
		self.featureLoaders = .init()
		self.featureLoaders.reserveCapacity(loaders.count)
		for loader: AnyFeatureLoader in loaders {
			self.featureLoaders[loader.featureType.identifier] = loader
		}
	}

	internal init(
		from registry: FeaturesRegistry
	) {
		self.featureLoaders = registry.featureLoaders
	}

	internal init<Scope>(
		from registry: ScopedFeaturesRegistry<Scope>
	) where Scope: FeaturesScope {
		self.init(from: registry.registry)
	}
}

extension FeaturesRegistry {

	@inline(__always)
	internal func loader<Feature>(
		for featureType: Feature.Type = Feature.self,
		file: StaticString,
		line: UInt
	) throws -> FeatureLoader<Feature>
	where Feature: LoadableFeature {
		guard let anyLoader: AnyFeatureLoader = self.featureLoaders[featureType.identifier]
		else {
			throw
				FeatureUndefined
				.error(
					message: "Requested feature loader is not defined",
					feature: featureType,
					file: file,
					line: line
				)
		}

		guard let loader: FeatureLoader<Feature> = anyLoader.asLoader(for: featureType)
		else {
			let error: TheError =
				InternalInconsistency
				.error(message: "FeatureLoader is not matching expected type")
				.with(anyLoader, for: "loader")
				.with(Feature.self, for: "expected")
				.with(anyLoader.featureType, for: "received")
				.appending(
					.message(
						"Requested FeatureLoader is invalid",
						file: file,
						line: line
					)
				)
			error.asAssertionFailure()
			throw error
		}

		return loader
	}

	@inline(__always)
	internal mutating func use(
		loader: AnyFeatureLoader
	) {
		self.featureLoaders[loader.featureType.identifier] = loader
	}

	@inline(__always)
	internal mutating func removeLoader(
		for featureType: AnyFeature.Type
	) {
		self.featureLoaders[featureType.identifier] = .none
	}

	#if DEBUG
		@inline(__always)
		internal func debugContext(
			for featureType: AnyFeature.Type
		) -> SourceCodeContext? {
			self.featureLoaders[featureType.identifier]?.debugContext
		}
	#endif
}
