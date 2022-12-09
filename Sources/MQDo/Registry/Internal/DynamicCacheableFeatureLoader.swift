internal struct DynamicCacheableFeatureLoader<Feature>: CacheableFeatureLoader
where Feature: CacheableFeature {

	typealias Load = @Sendable (_ context: Feature.Context, _ container: Features) throws -> Feature
	typealias LoadingCompletion = @Sendable (_ instance: Feature, _ context: Feature.Context) ->
		Void
	typealias Unload = @Sendable (_ instance: Feature, _ context: Feature.Context) -> Void

	#if DEBUG
		internal let debugMeta: SourceCodeMeta
	#endif
	internal let loadImplementation: Load
	internal let loadingCompletionImplementation: Self.LoadingCompletion
	internal let unloadImplementation: Self.Unload

	#if DEBUG
		internal init(
			debugMeta: SourceCodeMeta,
			load: @escaping Load,
			loadingCompletion: @escaping LoadingCompletion,
			unload: @escaping Unload
		) {
			self.debugMeta = debugMeta
			self.loadImplementation = load
			self.loadingCompletionImplementation = loadingCompletion
			self.unloadImplementation = unload
		}
	#else
		internal init(
			load: @escaping Load,
			loadingCompletion: @escaping LoadingCompletion,
			unload: @escaping Unload
		) {
			self.loadImplementation = load
			self.loadingCompletionImplementation = loadingCompletion
			self.unloadImplementation = unload
		}
	#endif

	@Sendable internal func load(
		with context: Feature.Context,
		using features: Features
	) throws -> Feature {
		try self.loadImplementation(context, features)
	}

	@Sendable internal func loadingCompletion(
		of instance: Feature,
		with context: Feature.Context
	) {
		self.loadingCompletionImplementation(instance, context)
	}

	@Sendable internal func unload(
		_ instance: Feature,
		with context: Feature.Context
	) {
		self.unloadImplementation(instance, context)
	}
}
