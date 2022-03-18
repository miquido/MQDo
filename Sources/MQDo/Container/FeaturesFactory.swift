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
	@MainActor internal func load<Feature>(
		_ featureType: Feature.Type,
		using features: FeaturesContainer,
		cache: @MainActor (FeaturesCache.Entry) -> Void,
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
				.load(using: features)

			if let unload: FeaturesCache.Removal = featureLoader.featureUnload {
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
							removal: unload
						)
					)
				#else
					cache(
						.init(
							feature: feature,
							removal: unload
						)
					)
				#endif
			}
			else {
				noop()
			}

			try featureLoader
				.loadingCompletion(
					of: feature,
					using: features
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
		}
	}

	@inline(__always)
	@MainActor internal func load<Feature>(
		_ featureType: Feature.Type,
		in context: Feature.Context,
		using features: FeaturesContainer,
		cache: @MainActor (FeaturesCache.Entry) -> Void,
		file: StaticString,
		line: UInt
	) throws -> Feature
	where Feature: LoadableContextualFeature {
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
				.load(using: features, in: context)

			if let unload: FeaturesCache.Removal = featureLoader.featureUnload {
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
							removal: unload
						)
					)
				#else
					cache(
						.init(
							feature: feature,
							removal: unload
						)
					)
				#endif
			}
			else {
				noop()
			}

			try featureLoader
				.loadingCompletion(
					of: feature,
					in: context,
					using: features
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
