internal struct FeaturesFactory {

	private let registry: DynamicFeaturesRegistry

	internal init(
		using registry: DynamicFeaturesRegistry
	) {
		self.registry = registry
	}
}

extension FeaturesFactory: Sendable {}

extension FeaturesFactory {

	@inline(__always)
	@Sendable internal func load<Feature>(
		_ featureType: Feature.Type,
		context: Feature.Context,
		within container: FeaturesContainer,
		cache: @Sendable (FeaturesCache.Entry) -> Void,
		file: StaticString,
		line: UInt
	) throws -> Feature
	where Feature: DynamicFeature {
		do {
			let featureLoader: FeatureLoader<Feature> =
				try self
				.registry
				.loader(
					for: featureType,
					context: context,
					file: file,
					line: line
				)

			let feature: Feature =
				try featureLoader
				.loadInstance(
					context: context,
					container: container
				)

			if let unload: DynamicFeatureLoader.Unload = featureLoader.erasedUnload {
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
									.with(context, for: "context")
									.with(container.branchDescription, for: "branch")
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
			}  // else ignore cache

			featureLoader
				.instanceLoadingCompletion(
					feature,
					context: context,
					container: container
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
				.with(container.branchDescription, for: "branch")
		}
	}

	#if DEBUG
		@inline(__always)
		@Sendable internal func loaderDebugContext<Feature>(
			for featureType: Feature.Type,
			context: Feature.Context
		) -> SourceCodeContext?
		where Feature: DynamicFeature {
			self.registry.debugContext(
				for: featureType,
				context: context
			)
		}
	#endif
}
