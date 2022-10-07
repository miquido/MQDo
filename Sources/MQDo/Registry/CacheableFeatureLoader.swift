public protocol CacheableFeatureLoader<Feature>: Sendable {

	associatedtype Feature: CacheableFeature

	typealias Load = @Sendable (_ context: Feature.Context, _ container: Features) throws -> Feature
	typealias LoadingCompletion = @Sendable (_ instance: Feature, _ context: Feature.Context, _ container: Features) ->
		Void
	typealias Unload = @Sendable (_ instance: Feature, _ context: Feature.Context) -> Void

	#if DEBUG
		var debugMeta: SourceCodeMeta { get }
	#endif
	var load: Load { get }
	var loadingCompletion: LoadingCompletion { get }
	var unload: Unload { get }
}

extension CacheableFeatureLoader {

	internal func load<RequestedFeature>(
		_: RequestedFeature.Type,
		context: RequestedFeature.Context,
		features: Features
	) throws -> RequestedFeature
	where RequestedFeature: CacheableFeature {
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
	) where RequestedFeature: CacheableFeature {
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

	internal func unload<RequestedFeature>(
		_ instance: RequestedFeature,
		context: RequestedFeature.Context
	) where RequestedFeature: CacheableFeature {
		if Feature.self == RequestedFeature.self,
			let context: Feature.Context = context as? Feature.Context,
			let instance: Feature = instance as? Feature
		{
			self.unload(instance, context)
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
