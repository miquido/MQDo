internal struct FeaturesFactory {

	private let registry: FeaturesRegistry

	internal init(
		using registry: FeaturesRegistry
	) {
		self.registry = registry
	}
}

extension FeaturesFactory {

	@inline(__always)
	internal func load<Feature>(
		_ featureType: Feature.Type,
		context: Feature.Context,
		within features: Features,
		cache: (FeaturesCache.Entry) -> Void,
		file: StaticString,
		line: UInt
	) throws -> Feature
	where Feature: LoadableFeature {
		do {
			let featureLoader: FeatureLoader<Feature> =
				try self
				.registry
				.loader(
					for: featureType,
					file: file,
					line: line
				)

			let feature: Feature =
				try featureLoader
				.load(
					context: context,
					within: features
				)

			if let cacheRemoval: FeaturesCache.Removal = featureLoader.cacheRemoval {
				#if DEBUG
					cache(
						.init(
							feature: feature,
							debugContext: featureLoader
								.debugContext
								.appending(
									.message(
										"Instance loaded",
										file: file,
										line: line
									)
								),
							removal: cacheRemoval
						)
					)
				#else
					cache(
						.init(
							feature: feature,
							removal: cacheRemoval
						)
					)
				#endif
			}
			else {
				noop()
			}

			try featureLoader
				.loadingCompletion(
					feature: feature,
					within: features
				)

			return feature
		}
		catch {
			throw
				FeatureLoadingFailed
				.error(
					message: "Loading feature instance failed",
					feature: Feature.self,
					cause:
						error
						.asTheError()
				)
				.with(Feature.self, for: "feature")
				.with(context, for: "context")
		}
	}

	#if DEBUG
		@inline(__always)
		internal func loaderDebugContext(
			for featureType: AnyFeature.Type
		) -> SourceCodeContext? {
			self.registry.debugContext(for: featureType)
		}
	#endif
}
