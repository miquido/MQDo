public protocol DisposableFeatureLoader<Feature>: Sendable {

	associatedtype Feature: DisposableFeature

	typealias Load = @Sendable (_ context: Feature.Context, _ container: Features) throws -> Feature
	typealias LoadingCompletion = @Sendable (_ instance: Feature, _ context: Feature.Context, _ container: Features) ->
		Void

	#if DEBUG
		var debugMeta: SourceCodeMeta { get }
	#endif
	var load: Load { get }
	var loadingCompletion: LoadingCompletion { get }
}

extension DisposableFeatureLoader {

	internal func load<RequestedFeature>(
		_: RequestedFeature.Type,
		context: RequestedFeature.Context,
		features: Features
	) throws -> RequestedFeature
	where RequestedFeature: DisposableFeature {
		if Feature.self == RequestedFeature.self,
			let context: Feature.Context = context as? Feature.Context,
			let instance: RequestedFeature = try self.load(context, features) as? RequestedFeature
		{
			return instance
		}
		else {
			throw
				InternalInconsistency
				.error(
					message: "Type mismatch in cacheable feature loader, please report a bug."
				)
				.asRuntimeWarning()
		}
	}

	internal func completeLoad<RequestedFeature>(
		_ instance: RequestedFeature,
		context: RequestedFeature.Context,
		features: Features
	) where RequestedFeature: DisposableFeature {
		if Feature.self == RequestedFeature.self,
			let context: Feature.Context = context as? Feature.Context,
			let instance: Feature = instance as? Feature
		{
			self.loadingCompletion(instance, context, features)
		}
		else {
			InternalInconsistency
				.error(
					message: "Type mismatch in cacheable feature loader, please report a bug."
				)
				.asFatalError()
		}
	}
}
