public enum FeatureLoader {}

extension FeatureLoader {

	public static func disposable<Feature>(
		_: Feature.Type = Feature.self,
		implementation: StaticString = #function,
		load: @escaping @Sendable (_ container: Features) throws -> Feature,
		loadingCompletion: @escaping @Sendable (_ instance: Feature, _ container: Features) ->
			Void = { _, _ in },
		file: StaticString = #fileID,
		line: UInt = #line
	) -> some DisposableFeatureLoader<Feature>
	where Feature: DisposableFeature, Feature.Context == Void {
		#if DEBUG
			return MQDisposableFeatureLoader<Feature>(
				debugMeta: SourceCodeMeta.message(
					implementation,
					file: file,
					line: line
				),
				load: { (_: Feature.Context, container: Features) throws -> Feature in
					try load(container)
				},
				loadingCompletion: { (instance: Feature, _: Feature.Context, container: Features) in
					loadingCompletion(instance, container)
				}
			)
		#else
			return MQDisposableFeatureLoader<Feature>(
				load: { (_: Feature.Context, container: Features) throws -> Feature in
					try load(container)
				},
				loadingCompletion: { (instance: Feature, _: Feature.Context, container: Features) in
					loadingCompletion(instance, container)
				}
			)
		#endif
	}
}

extension FeatureLoader {

	public static func disposable<Feature>(
		_: Feature.Type = Feature.self,
		implementation: StaticString = #function,
		load: @escaping @Sendable (_ context: Feature.Context, _ container: Features) throws -> Feature,
		loadingCompletion: @escaping @Sendable (_ instance: Feature, _ context: Feature.Context, _ container: Features) ->
			Void = { _, _, _ in },
		file: StaticString = #fileID,
		line: UInt = #line
	) -> some DisposableFeatureLoader<Feature>
	where Feature: DisposableFeature {
		#if DEBUG
			return MQDisposableFeatureLoader<Feature>(
				debugMeta: SourceCodeMeta.message(
					implementation,
					file: file,
					line: line
				),
				load: load,
				loadingCompletion: loadingCompletion
			)
		#else
			return MQDisposableFeatureLoader<Feature>(
				load: load,
				loadingCompletion: loadingCompletion
			)
		#endif
	}
}

extension FeatureLoader {

	public static func cacheable<Feature>(
		_: Feature.Type = Feature.self,
		implementation: StaticString = #function,
		load: @escaping @Sendable (_ container: Features) throws -> Feature,
		loadingCompletion: @escaping @Sendable (_ instance: Feature, _ container: Features) ->
			Void = { _, _ in },
		unload: @escaping @Sendable (_ instance: Feature) -> Void = { _ in },
		file: StaticString = #fileID,
		line: UInt = #line
	) -> some CacheableFeatureLoader<Feature>
	where Feature: CacheableFeature, Feature.Context == ContextlessCacheableFeatureContext {
		#if DEBUG
			return MQCacheableFeatureLoader<Feature>(
				debugMeta: SourceCodeMeta.message(
					implementation,
					file: file,
					line: line
				),
				load: { (_: Feature.Context, container: Features) throws -> Feature in
					try load(container)
				},
				loadingCompletion: { (instance: Feature, _: Feature.Context, container: Features) in
					loadingCompletion(instance, container)
				},
				unload: { (instance: Feature, _: Feature.Context) in
					unload(instance)
				}
			)
		#else
			return MQCacheableFeatureLoader<Feature>(
				load: { (_: Feature.Context, container: Features) throws -> Feature in
					try load(container)
				},
				loadingCompletion: { (instance: Feature, _: Feature.Context, container: Features) in
					loadingCompletion(instance, container)
				},
				unload: { (instance: Feature, _: Feature.Context) in
					unload(instance)
				}
			)
		#endif
	}
}

extension FeatureLoader {

	public static func cacheable<Feature>(
		_: Feature.Type = Feature.self,
		implementation: StaticString = #function,
		load: @escaping @Sendable (_ context: Feature.Context, _ container: Features) throws -> Feature,
		loadingCompletion: @escaping @Sendable (_ instance: Feature, _ context: Feature.Context, _ container: Features) ->
			Void = { _, _, _ in },
		unload: @escaping @Sendable (_ instance: Feature, _ context: Feature.Context) -> Void = { _, _ in },
		file: StaticString = #fileID,
		line: UInt = #line
	) -> some CacheableFeatureLoader<Feature>
	where Feature: CacheableFeature {
		#if DEBUG
			return MQCacheableFeatureLoader<Feature>(
				debugMeta: SourceCodeMeta.message(
					implementation,
					file: file,
					line: line
				),
				load: load,
				loadingCompletion: loadingCompletion,
				unload: unload
			)
		#else
			return MQCacheableFeatureLoader<Feature>(
				load: load,
				loadingCompletion: loadingCompletion,
				unload: unload
			)
		#endif
	}
}
