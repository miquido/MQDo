import MQ

internal struct FeaturesRegistry {

	private var dynamicFeaturesLoaders: Dictionary<DynamicFeatureLoaderIdentifier, DynamicFeatureLoader>

	internal init(
		dynamicFeaturesLoaders: Array<DynamicFeatureLoader> = .init()
	) {
		self.dynamicFeaturesLoaders = .init()
		self.dynamicFeaturesLoaders.reserveCapacity(dynamicFeaturesLoaders.count)
		for loader: DynamicFeatureLoader in dynamicFeaturesLoaders {
			self.dynamicFeaturesLoaders[loader.identifier] = loader
		}
	}

	internal init<Scope>(
		from scoped: ScopedFeaturesRegistry<Scope>
	) where Scope: FeaturesScope {
		self.dynamicFeaturesLoaders = scoped.registry.dynamicFeaturesLoaders
	}
}

extension FeaturesRegistry {

	@inline(__always)
	internal func loader<Feature>(
		for featureType: Feature.Type = Feature.self,
		context: Feature.Context,
		file: StaticString,
		line: UInt
	) throws -> FeatureLoader<Feature>
	where Feature: DynamicFeature {
		let matchingLoader: DynamicFeatureLoader? =
			// look for a context specific loader
			self.dynamicFeaturesLoaders[
				.loaderIdentifier(
					featureType: featureType,
					contextSpecifier: context
				)
			]
			// fallback to general loader if any
			?? self.dynamicFeaturesLoaders[
				.loaderIdentifier(
					featureType: featureType,
					contextSpecifier: .none
				)
			]

		guard let loader: DynamicFeatureLoader = matchingLoader
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
			try loader
			.asLoader(
				for: featureType,
				context: context,
				file: file,
				line: line
			)
	}

	@inline(__always)
	internal mutating func use(
		loader: DynamicFeatureLoader
	) {
		self.dynamicFeaturesLoaders[loader.identifier] = loader
	}

	@inline(__always)
	internal mutating func removeLoader(
		for identifier: DynamicFeatureLoaderIdentifier
	) {
		self.dynamicFeaturesLoaders[identifier] = .none
	}

	#if DEBUG
		@inline(__always)
		internal func debugContext<Feature>(
			for featureType: Feature.Type = Feature.self,
			context: Feature.Context
		) -> SourceCodeContext?
		where Feature: DynamicFeature {
			// look for a context specific loader
			(self.dynamicFeaturesLoaders[
				.loaderIdentifier(
					featureType: featureType,
					contextSpecifier: context
				)
			]
				// fallback to general loader if any
				?? self.dynamicFeaturesLoaders[
					.loaderIdentifier(
						featureType: featureType,
						contextSpecifier: .none
					)
				])?
				.debugContext
		}
	#endif

	internal mutating func merge(
		_ other: FeaturesRegistry
	) {
		self.dynamicFeaturesLoaders.merge(
			other.dynamicFeaturesLoaders,
			uniquingKeysWith: { $1 }  // always use other
		)
	}
}
