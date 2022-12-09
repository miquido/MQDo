public protocol CacheableFeatureImplementation {

	associatedtype Feature: CacheableFeature

	#if DEBUG
		static var debugMeta: SourceCodeMeta { get }
	#endif

	init(
		with context: Feature.Context,
		using features: Features
	) throws

	var implementation: Feature { get }

	static func loadingCompletion(
		of instance: Feature,
		with context: Feature.Context
	)

	static func unload(
		of instance: Feature,
		with context: Feature.Context
	)
}

extension CacheableFeatureImplementation {

	public static func loadingCompletion(
		of instance: Feature,
		with context: Feature.Context
	) {
		// noop
	}

	public static func unload(
		of instance: Feature,
		with context: Feature.Context
	) {
		// noop
	}
}

public protocol CacheableContextlessFeatureImplementation: CacheableFeatureImplementation
where Feature.Context == ContextlessCacheableFeatureContext {

	init(
		using features: Features
	) throws

	var implementation: Feature { get }

	static func loadingCompletion(
		of instance: Feature
	)

	static func unload(
		of instance: Feature
	)
}

extension CacheableContextlessFeatureImplementation {

	public init(
		with context: Feature.Context,
		using features: Features
	) throws {
		try self.init(using: features)
	}

	public static func loadingCompletion(
		of instance: Feature
	) {
		// noop
	}

	public static func loadingCompletion(
		of instance: Feature,
		with context: Feature.Context
	) {
		self.loadingCompletion(of: instance)
	}

	public static func unload(
		of instance: Feature
	) {
		// noop
	}

	public static func unload(
		of instance: Feature,
		with context: Feature.Context
	) {
		self.unload(of: instance)
	}
}

internal struct CacheableFeatureImplementationLoader<Implementation>
where Implementation: CacheableFeatureImplementation {

	internal init() {}
}

extension CacheableFeatureImplementationLoader: CacheableFeatureLoader {

	internal typealias Feature = Implementation.Feature

	#if DEBUG
		internal var debugMeta: SourceCodeMeta { Implementation.debugMeta }
	#endif

	@Sendable internal func load(
		with context: Implementation.Feature.Context,
		using features: Features
	) throws -> Implementation.Feature {
		try Implementation(
			with: context,
			using: features
		)
		.implementation
	}

	@Sendable internal func loadingCompletion(
		of instance: Implementation.Feature,
		with context: Implementation.Feature.Context
	) {
		Implementation
			.loadingCompletion(
				of: instance,
				with: context
			)
	}

	@Sendable internal func unload(
		_ instance: Implementation.Feature,
		with context: Implementation.Feature.Context
	) {
		Implementation
			.unload(
				of: instance,
				with: context
			)
	}
}
