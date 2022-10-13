internal struct FeatureLoaders {

	internal var disposable: Dictionary<DisposableFeatureIdentifier, any DisposableFeatureLoader> = .init()
	internal var cacheable: Dictionary<CacheableFeatureIdentifier, any CacheableFeatureLoader> = .init()
}

extension FeatureLoaders: Sendable {}
