public protocol CacheableFeatureLoader<Feature>: Sendable {

	associatedtype Feature: CacheableFeature

	#if DEBUG
		var debugMeta: SourceCodeMeta { get }
	#endif

	@Sendable func load(
		with context: Feature.Context,
		using features: Features
	) throws -> Feature
	@Sendable func loadingCompletion(
		of instance: Feature,
		with context: Feature.Context
	)
	@Sendable func unload(
		_ instance: Feature,
		with context: Feature.Context
	)
}

extension CacheableFeatureLoader {

	internal func loadInstance<RequestedFeature>(
		_: RequestedFeature.Type,
		context: RequestedFeature.Context,
		features: Features
	) throws -> RequestedFeature
	where RequestedFeature: CacheableFeature {
		if Feature.self == RequestedFeature.self,
			let context: Feature.Context = context as? Feature.Context,
			let instance: RequestedFeature = try self.load(with: context, using: features) as? RequestedFeature
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

	internal func completeLoading<RequestedFeature>(
		_ instance: RequestedFeature,
		context: RequestedFeature.Context
	) where RequestedFeature: CacheableFeature {
		if Feature.self == RequestedFeature.self,
			let context: Feature.Context = context as? Feature.Context,
			let instance: Feature = instance as? Feature
		{
			self.loadingCompletion(of: instance, with: context)
		}
		else {
			InternalInconsistency
				.error(
					message: "Type mismatch in cacheable feature loader, please report a bug."
				)
				.asFatalError()
		}
	}

	internal func unloadInstance<RequestedFeature>(
		_ instance: RequestedFeature,
		context: RequestedFeature.Context
	) where RequestedFeature: CacheableFeature {
		if Feature.self == RequestedFeature.self,
			let context: Feature.Context = context as? Feature.Context,
			let instance: Feature = instance as? Feature
		{
			self.unload(instance, with: context)
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
