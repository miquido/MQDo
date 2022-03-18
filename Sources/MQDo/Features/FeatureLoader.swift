import MQ

public struct FeatureLoader<Feature>
where Feature: AnyFeature {

	#if DEBUG
		internal var debugContext: SourceCodeContext {
			self.loader.debugContext
		}
	#endif
	private let loader: AnyFeatureLoader

	fileprivate init(
		from loader: AnyFeatureLoader
	) {
		runtimeAssert(
			loader.featureType == Feature.self,
			message: "FeatureLoader instance is not matching expected type, please report a bug."
		)
		self.loader = loader
	}
}

// swift-format-ignore: AllPublicDeclarationsHaveDocumentation
extension FeatureLoader: CustomStringConvertible {

	public var description: String {
		"FeatureLoader<\(Feature.self)>"
	}
}

// swift-format-ignore: AllPublicDeclarationsHaveDocumentation
extension FeatureLoader: CustomDebugStringConvertible {

	public var debugDescription: String {
		#if DEBUG
			"\(self.description)\n\(self.debugContext)"
		#else
			self.description
		#endif
	}
}

extension FeatureLoader
where Feature: LoadableFeature {

	// TODO: add docs
	public static func lazyLoaded(
		_ featureType: Feature.Type = Feature.self,
		implementation: StaticString = #function,
		load: @escaping @MainActor (FeaturesContainer) throws -> Feature,
		loadingCompletion: @escaping @MainActor (Feature, FeaturesContainer) throws -> Void = noop,
		unload: @escaping (Feature) -> Void = noop,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self {
		@MainActor func featureLoad(
			in _: Any,  // placeholder for context
			using features: FeaturesContainer
		) throws -> AnyFeature {
			try load(features)
		}

		@MainActor func featureLoadingCompletion(
			_ feature: AnyFeature,
			in _: Any,  // placeholder for context
			using features: FeaturesContainer
		) throws {
			guard let feature: Feature = feature as? Feature
			else {
				throw
					InternalInconsistency
					.error(message: "Feature is not matching expected type")
					.with(Feature.self, for: "expected")
					.with(type(of: feature), for: "received")
					.appending(
						.message(
							"FeatureLoader is invalid.",
							file: file,
							line: line
						)
					)
					.asAssertionFailure()
			}

			try loadingCompletion(feature, features)
		}

		func featureUnload(
			_ feature: AnyFeature
		) {
			guard let feature: Feature = feature as? Feature
			else {
				InternalInconsistency
					.error(message: "Feature is not matching expected type, please report a bug.")
					.with(Feature.self, for: "expected")
					.with(type(of: feature), for: "received")
					.appending(
						.message(
							"FeatureLoader is invalid.",
							file: file,
							line: line
						)
					)
					.asAssertionFailure()

				return  // ignore error in release builds
			}

			unload(feature)
		}

		#if DEBUG
			return Self(
				from: AnyFeatureLoader(
					debugContext: .context(
						message: "FeatureLoader.lazyLoaded",
						file: file,
						line: line
					)
					.with(featureType, for: "feature")
					.with(implementation, for: "implementation")
					.with(true, for: "cache"),
					featureType: Feature.self,
					load: featureLoad(in:using:),
					loadingCompletion: featureLoadingCompletion(_:in:using:),
					unload: featureUnload(_:)
				)
			)
		#else
			return Self(
				from: AnyFeatureLoader(
					featureType: Feature.self,
					load: featureLoad(in:using:),
					loadingCompletion: featureLoadingCompletion(_:in:using:),
					unload: featureUnload(_:)
				)
			)
		#endif
	}

	// TODO: add docs
	public static func disposable(
		_ featureType: Feature.Type = Feature.self,
		implementation: StaticString = #function,
		load: @escaping @MainActor (FeaturesContainer) throws -> Feature,
		loadingCompletion: @escaping @MainActor (Feature, FeaturesContainer) throws -> Void = noop,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self {
		@MainActor func featureLoad(
			in _: Any,  // placeholder for context
			using features: FeaturesContainer
		) throws -> AnyFeature {
			try load(features)
		}

		@MainActor func featureLoadingCompletion(
			_ feature: AnyFeature,
			in _: Any,  // placeholder for context
			using features: FeaturesContainer
		) throws {
			guard let feature: Feature = feature as? Feature
			else {
				throw
					InternalInconsistency
					.error(message: "Feature is not matching expected type")
					.with(Feature.self, for: "expected")
					.with(type(of: feature), for: "received")
					.appending(
						.message(
							"FeatureLoader is invalid.",
							file: file,
							line: line
						)
					)
					.asAssertionFailure()
			}

			try loadingCompletion(feature, features)
		}

		#if DEBUG
			return Self(
				from: AnyFeatureLoader(
					debugContext: .context(
						message: "FeatureLoader.disposable",
						file: file,
						line: line
					)
					.with(featureType, for: "feature")
					.with(implementation, for: "implementation")
					.with(false, for: "cache"),
					featureType: Feature.self,
					load: featureLoad(in:using:),
					loadingCompletion: featureLoadingCompletion(_:in:using:),
					unload: .none
				)
			)
		#else
			return Self(
				from: AnyFeatureLoader(
					featureType: Feature.self,
					load: featureLoad(in:using:),
					loadingCompletion: featureLoadingCompletion(_:in:using:),
					unload: .none
				)
			)
		#endif
	}

	// TODO: add docs
	public static func constant(
		_ featureType: Feature.Type = Feature.self,
		implementation: StaticString = #function,
		instance: @autoclosure @escaping () -> Feature,
		loadingCompletion: @escaping (Feature) -> Void = noop,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self {
		lazy var lazyInstance: Feature = {
			let feature: Feature = instance()
			loadingCompletion(feature)
			return feature
		}()

		#if DEBUG
			return Self(
				from: AnyFeatureLoader(
					debugContext: .context(
						message: "FeatureLoader.constant",
						file: file,
						line: line
					)
					.with(featureType, for: "feature")
					.with(implementation, for: "implementation")
					.with(true, for: "cache"),
					featureType: Feature.self,
					load: always(lazyInstance),
					loadingCompletion: noop,
					unload: noop
				)
			)
		#else
			return Self(
				from: AnyFeatureLoader(
					featureType: Feature.self,
					load: featureLoad(in:using:),
					loadingCompletion: featureLoadingCompletion(_:in:using:),
					unload: featureUnload(_:)
				)
			)
		#endif
	}
}

extension FeatureLoader
where Feature: LoadableContextualFeature {

	// TODO: add docs
	public static func lazyLoaded(
		_ featureType: Feature.Type = Feature.self,
		implementation: StaticString = #function,
		load: @escaping @MainActor (Feature.Context, FeaturesContainer) throws -> Feature,
		loadingCompletion: @escaping @MainActor (Feature, Feature.Context, FeaturesContainer) throws -> Void = noop,
		unload: @escaping (Feature) -> Void = noop,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self {
		@MainActor func featureLoad(
			in context: Any,
			using features: FeaturesContainer
		) throws -> AnyFeature {
			guard let context: Feature.Context = context as? Feature.Context
			else {
				throw
					InternalInconsistency
					.error(message: "Feature context is not matching expected type, please report a bug.")
					.with(Feature.Context.self, for: "expected")
					.with(type(of: context), for: "received")
					.appending(
						.message(
							"FeatureLoader is invalid.",
							file: file,
							line: line
						)
					)
					.asAssertionFailure()
			}
			return try load(context, features)
		}

		@MainActor func featureLoadingCompletion(
			_ feature: AnyFeature,
			in context: Any,
			using features: FeaturesContainer
		) throws {
			guard let feature: Feature = feature as? Feature
			else {
				throw
					InternalInconsistency
					.error(message: "Feature is not matching expected type")
					.with(Feature.self, for: "expected")
					.with(type(of: feature), for: "received")
					.appending(
						.message(
							"FeatureLoader is invalid.",
							file: file,
							line: line
						)
					)
					.asAssertionFailure()
			}

			guard let context: Feature.Context = context as? Feature.Context
			else {
				throw
					InternalInconsistency
					.error(message: "Feature context is not matching expected type, please report a bug.")
					.with(Feature.Context.self, for: "expected")
					.with(type(of: context), for: "received")
					.appending(
						.message(
							"FeatureLoader is invalid.",
							file: file,
							line: line
						)
					)
					.asAssertionFailure()
			}

			try loadingCompletion(feature, context, features)
		}

		func featureUnload(
			_ feature: AnyFeature
		) {
			guard let feature: Feature = feature as? Feature
			else {
				InternalInconsistency
					.error(message: "Feature is not matching expected type, please report a bug.")
					.with(Feature.self, for: "expected")
					.with(type(of: feature), for: "received")
					.appending(
						.message(
							"FeatureLoader is invalid.",
							file: file,
							line: line
						)
					)
					.asAssertionFailure()

				return  // ignore error in release builds
			}

			unload(feature)
		}

		#if DEBUG
			return Self(
				from: AnyFeatureLoader(
					debugContext: .context(
						message: "FeatureLoader.lazyLoaded",
						file: file,
						line: line
					)
					.with(featureType, for: "feature")
					.with(implementation, for: "implementation")
					.with(true, for: "cache"),
					featureType: Feature.self,
					load: featureLoad(in:using:),
					loadingCompletion: featureLoadingCompletion(_:in:using:),
					unload: featureUnload(_:)
				)
			)
		#else
			return Self(
				from: AnyFeatureLoader(
					featureType: Feature.self,
					load: featureLoad(in:using:),
					loadingCompletion: featureLoadingCompletion(_:in:using:),
					unload: featureUnload(_:)
				)
			)
		#endif
	}

	// TODO: add docs
	public static func disposable(
		_ featureType: Feature.Type = Feature.self,
		implementation: StaticString = #function,
		load: @escaping @MainActor (Feature.Context, FeaturesContainer) throws -> Feature,
		loadingCompletion: @escaping @MainActor (Feature, Feature.Context, FeaturesContainer) throws -> Void = noop,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self {
		@MainActor func featureLoad(
			in context: Any,
			using features: FeaturesContainer
		) throws -> AnyFeature {
			guard let context: Feature.Context = context as? Feature.Context
			else {
				throw
					InternalInconsistency
					.error(message: "Feature context is not matching expected type, please report a bug.")
					.with(Feature.Context.self, for: "expected")
					.with(type(of: context), for: "received")
					.appending(
						.message(
							"FeatureLoader is invalid.",
							file: file,
							line: line
						)
					)
					.asAssertionFailure()
			}
			return try load(context, features)
		}

		@MainActor func featureLoadingCompletion(
			_ feature: AnyFeature,
			in context: Any,
			using features: FeaturesContainer
		) throws {
			guard let feature: Feature = feature as? Feature
			else {
				throw
					InternalInconsistency
					.error(message: "Feature is not matching expected type")
					.with(Feature.self, for: "expected")
					.with(type(of: feature), for: "received")
					.appending(
						.message(
							"FeatureLoader is invalid.",
							file: file,
							line: line
						)
					)
					.asAssertionFailure()
			}

			guard let context: Feature.Context = context as? Feature.Context
			else {
				throw
					InternalInconsistency
					.error(message: "Feature context is not matching expected type, please report a bug.")
					.with(Feature.Context.self, for: "expected")
					.with(type(of: context), for: "received")
					.appending(
						.message(
							"FeatureLoader is invalid.",
							file: file,
							line: line
						)
					)
					.asAssertionFailure()
			}

			try loadingCompletion(feature, context, features)
		}

		#if DEBUG
			return Self(
				from: AnyFeatureLoader(
					debugContext: .context(
						message: "FeatureLoader.disposable",
						file: file,
						line: line
					)
					.with(featureType, for: "feature")
					.with(implementation, for: "implementation")
					.with(false, for: "cache"),
					featureType: Feature.self,
					load: featureLoad(in:using:),
					loadingCompletion: featureLoadingCompletion(_:in:using:),
					unload: .none
				)
			)
		#else
			return Self(
				from: AnyFeatureLoader(
					featureType: Feature.self,
					load: featureLoad(in:using:),
					loadingCompletion: featureLoadingCompletion(_:in:using:),
					unload: .none
				)
			)
		#endif
	}
}

#if DEBUG
	extension FeatureLoader {

		// TODO: add docs
		public static func placeholder(
			_ featureType: Feature.Type = Feature.self,
			instance: Feature,
			file: StaticString = #fileID,
			line: UInt = #line
		) -> Self {
			Self(
				from: AnyFeatureLoader(
					debugContext: .context(
						message: "FeatureLoader.placeholder",
						file: file,
						line: line
					)
					.with(featureType.self, for: "feature")
					.with("placeholder", for: "implementation")
					.with(true, for: "cache instances"),
					featureType: Feature.self,
					load: always(instance),
					loadingCompletion: noop,
					unload: noop
				)
			)
		}
	}
#endif

extension FeatureLoader {

	@inline(__always)
	internal var asAnyLoader: AnyFeatureLoader {
		self.loader
	}

	@inline(__always)
	@MainActor internal func load(
		using features: FeaturesContainer
	) throws -> Feature
	where Feature: LoadableFeature {
		let loadedFeature: AnyFeature = try self.loader.load(void, features)

		guard let feature: Feature = loadedFeature as? Feature
		else {
			throw
				InternalInconsistency
				.error(message: "Feature is not matching expected type, please report a bug.")
				.with(Feature.self, for: "expected")
				.with(type(of: loadedFeature), for: "received")
				.asAssertionFailure()
		}
		return feature
	}

	@inline(__always)
	@MainActor internal func load(
		using features: FeaturesContainer,
		in context: Feature.Context
	) throws -> Feature
	where Feature: LoadableContextualFeature {
		let loadedFeature: AnyFeature = try self.loader.load(context, features)

		guard let feature: Feature = loadedFeature as? Feature
		else {
			throw
				InternalInconsistency
				.error(message: "Feature is not matching expected type, please report a bug.")
				.with(Feature.self, for: "expected")
				.with(type(of: loadedFeature), for: "received")
				.asAssertionFailure()
		}
		return feature
	}

	@inline(__always)
	@MainActor internal func loadingCompletion(
		of feature: Feature,
		using features: FeaturesContainer
	) throws
	where Feature: LoadableFeature {
		try self.loader.loadingCompletion(feature, void, features)
	}

	@inline(__always)
	@MainActor internal func loadingCompletion(
		of feature: Feature,
		in context: Feature.Context,
		using features: FeaturesContainer
	) throws
	where Feature: LoadableContextualFeature {
		try self.loader.loadingCompletion(feature, context, features)
	}

	@inline(__always)
	internal var featureUnload: AnyFeatureLoader.Unload? {
		self.loader.unload
	}
}

extension AnyFeatureLoader {

	internal func asLoader<Feature>(
		for featureType: Feature.Type,
		file: StaticString = #fileID,
		line: UInt = #line
	) throws -> FeatureLoader<Feature>
	where Feature: AnyFeature {
		guard self.featureType == Feature.self
		else {
			throw
				InternalInconsistency
				.error(message: "FeatureLoader instance is not matching expected type, please report a bug.")
				.with(self, for: "loader")
				.with(Feature.self, for: "expected")
				.with(self.featureType, for: "received")
				.appending(
					.message(
						"FeatureLoader is invalid",
						file: file,
						line: line
					)
				)
				.asAssertionFailure()
		}

		return .init(from: self)
	}
}
