internal struct MQCacheableFeatureLoader<Feature>: CacheableFeatureLoader
where Feature: CacheableFeature {

	typealias Load = @Sendable (_ context: Feature.Context, _ container: Features) throws -> Feature
	typealias LoadingCompletion = @Sendable (_ instance: Feature, _ context: Feature.Context, _ container: Features) ->
		Void
	typealias Unload = @Sendable (_ instance: Feature, _ context: Feature.Context) -> Void

	#if DEBUG
		internal let debugMeta: SourceCodeMeta
	#endif
	internal let load: Load
	internal let loadingCompletion: Self.LoadingCompletion
	internal let unload: Self.Unload

	#if DEBUG
		internal init(
			debugMeta: SourceCodeMeta,
			load: @escaping Load,
			loadingCompletion: @escaping LoadingCompletion,
			unload: @escaping Unload
		) {
			self.debugMeta = debugMeta
			self.load = load
			self.loadingCompletion = loadingCompletion
			self.unload = unload
		}
	#else
		internal init(
			load: @escaping Load,
			loadingCompletion: @escaping LoadingCompletion,
			unload: @escaping Unload
		) {
			self.load = load
			self.loadingCompletion = loadingCompletion
			self.unload = unload
		}
	#endif
}
