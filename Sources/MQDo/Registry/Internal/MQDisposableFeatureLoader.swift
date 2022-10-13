internal struct MQDisposableFeatureLoader<Feature>: DisposableFeatureLoader
where Feature: DisposableFeature {

	typealias Load = @Sendable (_ context: Feature.Context, _ container: Features) throws -> Feature
	typealias LoadingCompletion = @Sendable (_ instance: Feature, _ context: Feature.Context, _ container: Features) ->
		Void

	#if DEBUG
		internal let debugMeta: SourceCodeMeta
	#endif
	internal let load: Load
	internal let loadingCompletion: LoadingCompletion

	#if DEBUG
		internal init(
			debugMeta: SourceCodeMeta,
			load: @escaping Load,
			loadingCompletion: @escaping LoadingCompletion
		) {
			self.debugMeta = debugMeta
			self.load = load
			self.loadingCompletion = loadingCompletion
		}
	#else
		internal init(
			load: @escaping Load,
			loadingCompletion: @escaping LoadingCompletion
		) {
			self.load = load
			self.loadingCompletion = loadingCompletion
		}
	#endif
}
