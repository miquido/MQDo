import MQ

/// Type providing implementations for ``DynamicFeature``.
///
/// ``FeatureLoader`` is a description used to provide implementations of ``DynamicFeature``.
/// ``Features`` container uses it to load and cache instances of a given feature.
/// It is used to define how to load instances, optionally triggering its initial tasks
/// and allowing cache for a given feature.
/// ``FeatureLoader`` is intended to be a source of all ``DynamicFeature`` implementations
/// allowing to manage and identify concrete implementations and its availability.
public struct FeatureLoader<Feature>: Sendable
where Feature: DynamicFeature {

	#if DEBUG
		internal var debugContext: SourceCodeContext {
			self.loader.debugContext
		}
	#endif
	private let loader: DynamicFeatureLoader

	fileprivate init(
		from loader: DynamicFeatureLoader
	) {
		runtimeAssert(
			loader.identifier.matches(featureType: Feature.self),
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

extension FeatureLoader {

	/// Make instance of loader for lazy loaded feature.
	///
	/// Lazy loaded feature loader provides implementation of a features which are
	/// dynamically, lazily loaded and cached. Each time an instance is requested
	/// the same instance within the same features container will be provided.
	///
	/// - Parameters:
	///   - featureType: Type of the feature provided by created loader.
	///   - implementation: Name of given implementation used to identify feature implementation.
	///   By default it is name of a function enclosing invocation of this function.
	///   - load: Function which produces new instances of given feature.
	///   - loadingCompletion: Function allowing to execute initial operations after loading
	///   instance of feature. It can be also used to resolve circular dependencies.
	///  Default implementation does nothing.
	///   - unload: Function called when instance of feature is going to be removed from cache.
	///   If this function will be called whenever instance of given feature will be removed from a cache.
	///   First instance of feature that will be created in given ``Features`` container will be cached.
	///   - file: Source code file identifier used to identify feature implementation.
	///   Filled automatically based on compile time constants.
	///   - line: Line in given source code file used to identify feature implementation.
	///   Filled automatically based on compile time constants.
	/// - Returns: Instance of ``FeatureLoader`` providing lazy loaded implementation of given feature.
	@_disfavoredOverload public static func lazyLoaded(
		_ featureType: Feature.Type = Feature.self,
		implementation: StaticString = #function,
		load: @escaping @Sendable (_ context: Feature.Context, _ container: Features) throws -> Feature,
		loadingCompletion: @escaping @Sendable (_ instance: Feature, _ context: Feature.Context, _ container: Features) ->
			Void =
			noop,
		unload: @escaping (_ instance: Feature) -> Void = noop,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self
	where Feature: DynamicFeature {
		@Sendable func featureLoad(
			context: Any,  // DynamicFeatureContext
			using container: FeaturesContainer
		) throws -> AnyFeature {
			guard let context: Feature.Context = context as? Feature.Context
			else {
				throw
					InternalInconsistency
					.error(message: "Feature context is not matching expected type, please report a bug.")
					.with(Feature.Context.typeDescription, for: "expected")
					.with(type(of: context), for: "received")
					.appending(
						.message(
							"FeatureLoader is invalid",
							file: file,
							line: line
						)
					)
					.asAssertionFailure()
			}

			return try load(context, container.features)
		}

		@Sendable func featureLoadingCompletion(
			_ feature: AnyFeature,
			context: Any,  // DynamicFeatureContext
			using container: FeaturesContainer
		) {
			guard let feature: Feature = feature as? Feature
			else {
				InternalInconsistency
					.error(message: "Feature instance is not matching expected type, please report a bug.")
					.with(Feature.typeDescription, for: "expected")
					.with(feature.typeDescription, for: "received")
					.appending(
						.message(
							"FeatureLoader is invalid",
							file: file,
							line: line
						)
					)
					.asFatalError()
			}

			guard let context: Feature.Context = context as? Feature.Context
			else {
				InternalInconsistency
					.error(message: "Feature context is not matching expected type, please report a bug.")
					.with(Feature.Context.typeDescription, for: "expected")
					.with(type(of: context), for: "received")
					.appending(
						.message(
							"FeatureLoader is invalid",
							file: file,
							line: line
						)
					)
					.asFatalError()
			}

			loadingCompletion(feature, context, container.features)
		}

		@Sendable func featureUnload(
			_ feature: AnyFeature
		) {
			guard let feature: Feature = feature as? Feature
			else {
				InternalInconsistency
					.error(message: "Feature instance is not matching expected type, please report a bug.")
					.with(Feature.typeDescription, for: "expected")
					.with(feature.typeDescription, for: "received")
					.appending(
						.message(
							"FeatureLoader is invalid",
							file: file,
							line: line
						)
					)
					.asFatalError()
			}

			unload(feature)
		}

		#if DEBUG
			return Self(
				from: DynamicFeatureLoader(
					debugContext: .context(
						message: "FeatureLoader.lazyLoaded",
						file: file,
						line: line
					)
					.with(featureType, for: "feature")
					.with(implementation, for: "implementation")
					.with(true, for: "cache"),
					identifier: .init(
						featureType: Feature.self
					),
					load: featureLoad(context:using:),
					loadingCompletion: featureLoadingCompletion(_:context:using:),
					unload: featureUnload(_:)
				)
			)
		#else
			return Self(
				from: DynamicFeatureLoader(
					identifier: .init(featureType: Feature.self),
					load: featureLoad(context:using:),
					loadingCompletion: featureLoadingCompletion(_:context:using:),
					unload: featureUnload(_:)
				)
			)
		#endif
	}

	/// Make instance of loader for disposable feature.
	///
	/// Disposable feature loader provides implementation of a features which are
	/// dynamically, lazily loaded and not cached. Each time an instance is requested
	/// the new instance will be provided.
	///
	/// - Parameters:
	///   - featureType: Type of the feature provided by created loader.
	///   - implementation: Name of given implementation used to identify feature implementation.
	///   By default it is name of a function enclosing invocation of this function.
	///   - load: Function which produces new instances of given feature.
	///   - loadingCompletion: Function allowing to execute initial operations after loading
	///   instance of feature. It can be also used to resolve circular dependencies.
	///   Default implementation does nothing.
	///   - file: Source code file identifier used to identify feature implementation.
	///   Filled automatically based on compile time constants.
	///   - line: Line in given source code file used to identify feature implementation.
	///   Filled automatically based on compile time constants.
	/// - Returns: Instance of ``FeatureLoader`` providing disposable implementation of given feature.
	@_disfavoredOverload public static func disposable(
		_ featureType: Feature.Type = Feature.self,
		implementation: StaticString = #function,
		load: @escaping @Sendable (_ context: Feature.Context, _ container: Features) throws -> Feature,
		loadingCompletion: @escaping @Sendable (_ instance: Feature, _ context: Feature.Context, _ container: Features) ->
			Void =
			noop,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self
	where Feature: DynamicFeature {
		@Sendable func featureLoad(
			context: Any,  // DynamicFeatureContext
			using container: FeaturesContainer
		) throws -> AnyFeature {
			guard let context: Feature.Context = context as? Feature.Context
			else {
				throw
					InternalInconsistency
					.error(message: "Feature context is not matching expected type, please report a bug.")
					.with(Feature.Context.typeDescription, for: "expected")
					.with(type(of: context), for: "received")
					.appending(
						.message(
							"FeatureLoader is invalid",
							file: file,
							line: line
						)
					)
					.asAssertionFailure()
			}

			return try load(context, container.features)
		}

		@Sendable func featureLoadingCompletion(
			_ feature: AnyFeature,
			context: Any,  // DynamicFeatureContext
			using container: FeaturesContainer
		) {
			guard let feature: Feature = feature as? Feature
			else {
				InternalInconsistency
					.error(message: "Feature instance is not matching expected type, please report a bug.")
					.with(Feature.typeDescription, for: "expected")
					.with(feature.typeDescription, for: "received")
					.appending(
						.message(
							"FeatureLoader is invalid",
							file: file,
							line: line
						)
					)
					.asFatalError()
			}

			guard let context: Feature.Context = context as? Feature.Context
			else {
				InternalInconsistency
					.error(message: "Feature context is not matching expected type, please report a bug.")
					.with(Feature.Context.typeDescription, for: "expected")
					.with(type(of: context), for: "received")
					.appending(
						.message(
							"FeatureLoader is invalid",
							file: file,
							line: line
						)
					)
					.asFatalError()
			}

			loadingCompletion(feature, context, container.features)
		}

		#if DEBUG
			return Self(
				from: DynamicFeatureLoader(
					debugContext: .context(
						message: "FeatureLoader.disposable",
						file: file,
						line: line
					)
					.with(featureType, for: "feature")
					.with(implementation, for: "implementation")
					.with(false, for: "cache"),
					identifier: .init(
						featureType: Feature.self
					),
					load: featureLoad(context:using:),
					loadingCompletion: featureLoadingCompletion(_:context:using:),
					unload: .none
				)
			)
		#else
			return Self(
				from: DynamicFeatureLoader(
					identifier: .init(featureType: Feature.self),
					load: featureLoad(context:using:),
					loadingCompletion: featureLoadingCompletion(_:context:using:),
					unload: .none
				)
			)
		#endif
	}
}

extension FeatureLoader {

	/// Make instance of loader for lazy loaded feature.
	///
	/// Lazy loaded feature loader provides implementation of a features which are
	/// dynamically, lazily loaded and cached. Each time an instance is requested
	/// the same instance within the same features container will be provided.
	///
	/// - Parameters:
	///   - featureType: Type of the feature provided by created loader.
	///   - implementation: Name of given implementation used to identify feature implementation.
	///   By default it is name of a function enclosing invocation of this function.
	///   - load: Function which produces new instances of given feature.
	///   - loadingCompletion: Function allowing to execute initial operations after loading
	///   instance of feature. It can be also used to resolve circular dependencies.
	///  Default implementation does nothing.
	///   - unload: Function called when instance of feature is going to be removed from cache.
	///   If this function will be called whenever instance of given feature will be removed from a cache.
	///   First instance of feature that will be created in given ``Features`` container will be cached.
	///   - file: Source code file identifier used to identify feature implementation.
	///   Filled automatically based on compile time constants.
	///   - line: Line in given source code file used to identify feature implementation.
	///   Filled automatically based on compile time constants.
	/// - Returns: Instance of ``FeatureLoader`` providing lazy loaded implementation of given feature.
	public static func lazyLoaded(
		_ featureType: Feature.Type = Feature.self,
		implementation: StaticString = #function,
		load: @escaping @Sendable (_ container: Features) throws -> Feature,
		loadingCompletion: @escaping @Sendable (_ instance: Feature, _ container: Features) -> Void = noop,
		unload: @escaping (_ instance: Feature) -> Void = noop,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self
	where Feature: DynamicFeature, Feature.Context == ContextlessFeatureContext {
		@Sendable func featureLoad(
			context _: Any,  // placeholder
			using container: FeaturesContainer
		) throws -> AnyFeature {
			try load(container.features)
		}

		@Sendable func featureLoadingCompletion(
			_ feature: AnyFeature,
			context _: Any,  // placeholder
			using container: FeaturesContainer
		) {
			guard let feature: Feature = feature as? Feature
			else {
				InternalInconsistency
					.error(message: "Feature instance is not matching expected type, please report a bug.")
					.with(Feature.typeDescription, for: "expected")
					.with(feature.typeDescription, for: "received")
					.appending(
						.message(
							"FeatureLoader is invalid",
							file: file,
							line: line
						)
					)
					.asFatalError()
			}

			loadingCompletion(feature, container.features)
		}

		@Sendable func featureUnload(
			_ feature: AnyFeature
		) {
			guard let feature: Feature = feature as? Feature
			else {
				InternalInconsistency
					.error(message: "Feature instance is not matching expected type, please report a bug.")
					.with(Feature.typeDescription, for: "expected")
					.with(feature.typeDescription, for: "received")
					.appending(
						.message(
							"FeatureLoader is invalid",
							file: file,
							line: line
						)
					)
					.asFatalError()
			}

			unload(feature)
		}

		#if DEBUG
			return Self(
				from: DynamicFeatureLoader(
					debugContext: .context(
						message: "FeatureLoader.lazyLoaded",
						file: file,
						line: line
					)
					.with(featureType, for: "feature")
					.with(implementation, for: "implementation")
					.with(true, for: "cache"),
					identifier: .init(
						featureType: Feature.self
					),
					load: featureLoad(context:using:),
					loadingCompletion: featureLoadingCompletion(_:context:using:),
					unload: featureUnload(_:)
				)
			)
		#else
			return Self(
				from: DynamicFeatureLoader(
					identifier: .init(featureType: Feature.self),
					load: featureLoad(context:using:),
					loadingCompletion: featureLoadingCompletion(_:context:using:),
					unload: featureUnload(_:)
				)
			)
		#endif
	}

	/// Make instance of loader for disposable feature.
	///
	/// Disposable feature loader provides implementation of a features which are
	/// dynamically, lazily loaded and not cached. Each time an instance is requested
	/// the new instance will be provided.
	///
	/// - Parameters:
	///   - featureType: Type of the feature provided by created loader.
	///   - implementation: Name of given implementation used to identify feature implementation.
	///   By default it is name of a function enclosing invocation of this function.
	///   - load: Function which produces new instances of given feature.
	///   - loadingCompletion: Function allowing to execute initial operations after loading
	///   instance of feature. It can be also used to resolve circular dependencies.
	///   Default implementation does nothing.
	///   - file: Source code file identifier used to identify feature implementation.
	///   Filled automatically based on compile time constants.
	///   - line: Line in given source code file used to identify feature implementation.
	///   Filled automatically based on compile time constants.
	/// - Returns: Instance of ``FeatureLoader`` providing disposable implementation of given feature.
	public static func disposable(
		_ featureType: Feature.Type = Feature.self,
		implementation: StaticString = #function,
		load: @escaping @Sendable (_ container: Features) throws -> Feature,
		loadingCompletion: @escaping @Sendable (_ instance: Feature, _ container: Features) -> Void = noop,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self
	where Feature: DynamicFeature, Feature.Context == ContextlessFeatureContext {
		@Sendable func featureLoad(
			context _: Any,  // placeholder
			using container: FeaturesContainer
		) throws -> AnyFeature {
			try load(container.features)
		}

		@Sendable func featureLoadingCompletion(
			_ feature: AnyFeature,
			context _: Any,  // placeholder
			using container: FeaturesContainer
		) {
			guard let feature: Feature = feature as? Feature
			else {
				InternalInconsistency
					.error(message: "Feature instance is not matching expected type, please report a bug.")
					.with(Feature.typeDescription, for: "expected")
					.with(feature.typeDescription, for: "received")
					.appending(
						.message(
							"FeatureLoader is invalid",
							file: file,
							line: line
						)
					)
					.asFatalError()
			}

			loadingCompletion(feature, container.features)
		}

		#if DEBUG
			return Self(
				from: DynamicFeatureLoader(
					debugContext: .context(
						message: "FeatureLoader.disposable",
						file: file,
						line: line
					)
					.with(featureType, for: "feature")
					.with(implementation, for: "implementation")
					.with(false, for: "cache"),
					identifier: .init(
						featureType: Feature.self
					),
					load: featureLoad(context:using:),
					loadingCompletion: featureLoadingCompletion(_:context:using:),
					unload: .none
				)
			)
		#else
			return Self(
				from: DynamicFeatureLoader(
					identifier: .init(featureType: Feature.self),
					load: featureLoad(context:using:),
					loadingCompletion: featureLoadingCompletion(_:context:using:),
					unload: .none
				)
			)
		#endif
	}
}

extension FeatureLoader {

	@inline(__always)
	internal var asAnyLoader: DynamicFeatureLoader {
		self.loader
	}

	@inline(__always)
	@Sendable internal func loadInstance(
		context: Feature.Context,
		container: FeaturesContainer
	) throws -> Feature
	where Feature: DynamicFeature {
		let loadedFeature: AnyFeature = try self.loader.load(context, container)

		guard let feature: Feature = loadedFeature as? Feature
		else {
			throw
				InternalInconsistency
				.error(message: "Feature instance is not matching expected type, please report a bug.")
				.with(Feature.typeDescription, for: "expected")
				.with(loadedFeature.typeDescription, for: "received")
				.asAssertionFailure()
		}

		return feature
	}

	@inline(__always)
	@Sendable internal func instanceLoadingCompletion(
		_ instance: Feature,
		context: Feature.Context,
		container: FeaturesContainer
	) where Feature: DynamicFeature {
		self.loader
			.loadingCompletion(
				instance,
				context,
				container
			)
	}

	internal var erasedUnload: DynamicFeatureLoader.Unload? {
		self.loader.unload
	}
}

extension DynamicFeatureLoader {

	@Sendable internal func asLoader<Feature>(
		for featureType: Feature.Type,
		context: Feature.Context,
		file: StaticString = #fileID,
		line: UInt = #line
	) throws -> FeatureLoader<Feature>
	where Feature: DynamicFeature {
		guard self.identifier.matches(featureType: Feature.self)
		else {
			throw
				InternalInconsistency
				.error(message: "Feature loader is not matching expected, please report a bug.")
				.with(Feature.typeDescription, for: "expected")
				.with(self.identifier.typeDescription, for: "received")
				.asAssertionFailure()
		}

		return .init(from: self)
	}
}
