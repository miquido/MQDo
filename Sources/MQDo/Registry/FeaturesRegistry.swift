internal struct FeaturesRegistry {

	private var loaders: Dictionary<AnyFeature.Identifier, AnyFeatureLoader>

	internal init(
		loaders: Array<AnyFeatureLoader> = .init()
	) {
		self.loaders = .init()
		self.loaders.reserveCapacity(loaders.count)
		for loader: AnyFeatureLoader in loaders {
			self.loaders[loader.featureType.identifier] = loader
		}
	}

	internal init<Scope>(
		from scoped: ScopedFeaturesRegistry<Scope>
	) where Scope: FeaturesScope {
		self.loaders = scoped.registry.loaders
	}
}

extension FeaturesRegistry {

	@inline(__always)
	internal func loader<Feature>(
		for featureType: Feature.Type = Feature.self,
		file: StaticString,
		line: UInt
	) throws -> FeatureLoader<Feature>
	where Feature: AnyFeature {
		guard let anyLoader: AnyFeatureLoader = self.loaders[featureType.identifier]
		else {
			throw
				FeatureUndefined
				.error(
					message: "Requested feature loader is not defined.",
					feature: featureType,
					file: file,
					line: line
				)
		}

		return
			try anyLoader
			.asLoader(
				for: featureType,
				file: file,
				line: line
			)
	}

	@inline(__always)
	internal mutating func use(
		loader: AnyFeatureLoader
	) {
		self.loaders[loader.featureType.identifier] = loader
	}

	@inline(__always)
	internal mutating func removeLoader(
		for featureType: AnyFeature.Type
	) {
		self.loaders[featureType.identifier] = .none
	}

	#if DEBUG
		@inline(__always)
		internal func debugContext(
			for featureType: AnyFeature.Type
		) -> SourceCodeContext? {
			self.loaders[featureType.identifier]?.debugContext
		}
	#endif
}
