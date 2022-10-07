internal struct FeaturesTreeRegistry {

	internal var staticFeatures: Dictionary<StaticFeatureIdentifier, any StaticFeature> = .init()
	internal var scopeFeatureLoaders: Dictionary<FeaturesScopeIdentifier, FeatureLoaders> = [
		RootFeaturesScope.identifier: .init()
	]

	internal init() {}
}

extension FeaturesTreeRegistry: Sendable {}

extension FeaturesTreeRegistry {

	internal func loader<Feature, Scope>(
		for _: Feature.Type,
		in _: Scope.Type,
		file: StaticString,
		line: UInt
	) throws -> any DisposableFeatureLoader
	where Feature: DisposableFeature, Scope: FeaturesScope {
		guard let scopeFeatures: FeatureLoaders = self.scopeFeatureLoaders[Scope.identifier]
		else {
			throw
				FeaturesScopeUndefined
				.error(
					scope: Scope.self,
					file: file,
					line: line
				)
		}

		if let loader: any DisposableFeatureLoader = scopeFeatures.disposable[Feature.identifier] {
			return loader
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

	internal func loadInstance<Feature, Scope>(
		of _: Feature.Type,
		context: Feature.Context,
		in _: Scope.Type,
		using features: Features,
		file: StaticString,
		line: UInt
	) throws -> Feature
	where Feature: DisposableFeature, Scope: FeaturesScope {
		guard let scopeFeatures: FeatureLoaders = self.scopeFeatureLoaders[Scope.identifier]
		else {
			throw
				FeaturesScopeUndefined
				.error(
					scope: Scope.self,
					file: file,
					line: line
				)
		}

		if let loader: any DisposableFeatureLoader = scopeFeatures.disposable[Feature.identifier] {
			let instance: Feature =
				try loader
				.load(
					Feature.self,
					context: context,
					features: features
				)
			loader
				.completeLoad(
					instance,
					context: context,
					features: features
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

	internal func loader<Feature, Scope>(
		for _: Feature.Type,
		in _: Scope.Type,
		file: StaticString,
		line: UInt
	) throws -> any CacheableFeatureLoader
	where Feature: CacheableFeature, Scope: FeaturesScope {
		guard let scopeFeatures: FeatureLoaders = self.scopeFeatureLoaders[Scope.identifier]
		else {
			throw
				FeaturesScopeUndefined
				.error(
					scope: Scope.self,
					file: file,
					line: line
				)
		}

		if let loader: any CacheableFeatureLoader = scopeFeatures.cacheable[Feature.identifier] {
			return loader
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

	internal func loadInstance<Feature, Scope>(
		of _: Feature.Type,
		context: Feature.Context,
		in _: Scope.Type,
		using features: Features,
		file: StaticString,
		line: UInt
	) throws -> (instance: Feature, unload: @Sendable () -> Void)
	where Feature: CacheableFeature, Scope: FeaturesScope {
		guard let scopeFeatures: FeatureLoaders = self.scopeFeatureLoaders[Scope.identifier]
		else {
			throw
				FeaturesScopeUndefined
				.error(
					scope: Scope.self,
					file: file,
					line: line
				)
		}

		if let loader: any CacheableFeatureLoader = scopeFeatures.cacheable[Feature.identifier] {
			let instance: Feature =
				try loader
				.load(
					Feature.self,
					context: context,
					features: features
				)
			loader
				.completeLoad(
					instance,
					context: context,
					features: features
				)
			return (
				instance: instance,
				unload: { loader.unload(instance, context: context) }
			)
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

	internal func instance<Feature>(
		of _: Feature.Type,
		file: StaticString,
		line: UInt
	) -> Feature
	where Feature: StaticFeature {
		if let instance: any StaticFeature = self.staticFeatures[Feature.identifier] {
			if let instance: Feature = instance as? Feature {
				return instance
			}
			else {
				InternalInconsistency
					.error(
						message: "Type mismatch when accessing static feature, please report a bug."
					)
					.asFatalError()
			}
		}
		else {
			FeatureUndefined
				.error(
					feature: Feature.self,
					file: file,
					line: line
				)
				.asFatalError(message: "All static features has to be defined.")
		}
	}
}
