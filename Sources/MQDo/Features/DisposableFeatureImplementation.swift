public protocol DisposableFeatureImplementation {

	associatedtype Feature: DisposableFeature

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
}

extension DisposableFeatureImplementation {

	public static func loadingCompletion(
		of instance: Feature,
		with context: Feature.Context
	) {
		// noop
	}
}

public protocol DisposableContextlessFeatureImplementation: DisposableFeatureImplementation
where Feature.Context == Void {

	init(
		using features: Features
	) throws

	var implementation: Feature { get }

	static func loadingCompletion(
		of instance: Feature
	)
}

extension DisposableContextlessFeatureImplementation {

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
}

internal struct DisposableFeatureImplementationLoader<Implementation>
where Implementation: DisposableFeatureImplementation {

	internal init() {}
}

extension DisposableFeatureImplementationLoader: DisposableFeatureLoader {

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
}
