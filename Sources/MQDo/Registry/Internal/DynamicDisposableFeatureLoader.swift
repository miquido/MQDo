internal struct DynamicDisposableFeatureLoader<Feature>: DisposableFeatureLoader
where Feature: DisposableFeature {

	typealias Load = @Sendable (_ context: Feature.Context, _ container: Features) throws -> Feature
	typealias LoadingCompletion = @Sendable (_ instance: Feature, _ context: Feature.Context) ->
		Void
	#if DEBUG
		internal let debugMeta: SourceCodeMeta
	#endif
	internal let loadImplementation: Load
	internal let loadingCompletionImplementation: LoadingCompletion

	#if DEBUG
		internal init(
			debugMeta: SourceCodeMeta,
			load: @escaping Load,
			loadingCompletion: @escaping LoadingCompletion
		) {
			self.debugMeta = debugMeta
			self.loadImplementation = load
			self.loadingCompletionImplementation = loadingCompletion
		}
	#else
		internal init(
			load: @escaping Load,
			loadingCompletion: @escaping LoadingCompletion
		) {
			self.loadImplementation = load
			self.loadingCompletionImplementation = loadingCompletion
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
}
