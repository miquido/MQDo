import MQ

/// Type providing implementations for ``LoadableFeature``.
///
/// ``FeatureLoader`` is a description used to provide implementations of ``LoadableFeature``.
/// ``Features`` container uses it to load and cache instances of a given feature.
/// It is used to define how to load instances, optionally triggering its initial tasks
/// and allowing cache for a given feature.
/// ``FeatureLoader`` is intended to be a source of all ``LoadableFeature`` implementations
/// allowing to manage and identify concrete implementations and its availability.
public struct FeatureLoader<Feature>
where Feature: LoadableFeature {

	#if DEBUG
		internal var debugContext: SourceCodeContext {
			self.loader.debugContext
		}
	#endif
	private let loader: LoadableFeatureLoader

	fileprivate init(
		from loader: LoadableFeatureLoader
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
	///   - contextSpecifier: Optional context specification, allows to use
	///   different implementation based on context value. If set to none
	///   loader will be used as a general default implementation for the
	///   features with any context value (except those specified which
	///   have priority). Default is none.
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
		contextSpecifier: Feature.Context? = .none,
		implementation: StaticString = #function,
		load: @escaping @MainActor (_ context: Feature.Context, _ container: Features) throws -> Feature,
		loadingCompletion: @escaping @MainActor (_ instance: Feature, _ context: Feature.Context, _ container: Features) ->
			Void =
			noop,
		unload: @escaping (_ instance: Feature) -> Void = noop,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self
	where Feature: LoadableFeature {
		@MainActor func featureLoad(
			context: LoadableFeatureContext,
			using features: Features
		) throws -> AnyFeature {
			guard let context: Feature.Context = context as? Feature.Context
			else {
				throw
					InternalInconsistency
					.error(message: "Feature context is not matching expected type, please report a bug.")
					.with(Feature.Context.typeDescription, for: "expected")
					.with(context.typeDescription, for: "received")
					.appending(
						.message(
							"FeatureLoader is invalid",
							file: file,
							line: line
						)
					)
					.asAssertionFailure()
			}

			guard contextSpecifier.map({ $0.identifier == context.identifier }) ?? true
			else {
				throw
					InternalInconsistency
					.error(message: "Feature context value is not matching expected, please report a bug.")
					.with(contextSpecifier, for: "expected")
					.with(context, for: "received")
					.appending(
						.message(
							"FeatureLoader is invalid",
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
			context: LoadableFeatureContext,
			using features: Features
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
					.with(context.typeDescription, for: "received")
					.appending(
						.message(
							"FeatureLoader is invalid",
							file: file,
							line: line
						)
					)
					.asFatalError()
			}

			loadingCompletion(feature, context, features)
		}

		func featureUnload(
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
				from: LoadableFeatureLoader(
					debugContext: .context(
						message: "FeatureLoader.lazyLoaded",
						file: file,
						line: line
					)
					.with(featureType, for: "feature")
					.with(implementation, for: "implementation")
					.with(true, for: "cache"),
					identifier: .init(
						featureType: Feature.self,
						contextSpecifier: contextSpecifier
					),
					load: featureLoad(context:using:),
					loadingCompletion: featureLoadingCompletion(_:context:using:),
					unload: featureUnload(_:)
				)
			)
		#else
			return Self(
				from: LoadableFeatureLoader(
					identifier: .init(
						featureType: Feature.self,
						contextSpecifier: contextSpecifier
					),
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
	///   - contextSpecifier: Optional context specification, allows to use
	///   different implementation based on context value. If set to none
	///   loader will be used as a general default implementation for the
	///   features with any context value (except those specified which
	///   have priority). Default is none.
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
		contextSpecifier: Feature.Context? = .none,
		implementation: StaticString = #function,
		load: @escaping @MainActor (_ context: Feature.Context, _ container: Features) throws -> Feature,
		loadingCompletion: @escaping @MainActor (_ instance: Feature, _ context: Feature.Context, _ container: Features) ->
			Void =
			noop,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self
	where Feature: LoadableFeature {
		@MainActor func featureLoad(
			context: LoadableFeatureContext,
			using features: Features
		) throws -> AnyFeature {
			guard let context: Feature.Context = context as? Feature.Context
			else {
				throw
					InternalInconsistency
					.error(message: "Feature context is not matching expected type, please report a bug.")
					.with(Feature.Context.typeDescription, for: "expected")
					.with(context.typeDescription, for: "received")
					.appending(
						.message(
							"FeatureLoader is invalid",
							file: file,
							line: line
						)
					)
					.asAssertionFailure()
			}

			guard contextSpecifier.map({ $0.identifier == context.identifier }) ?? true
			else {
				throw
					InternalInconsistency
					.error(message: "Feature context value is not matching expected, please report a bug.")
					.with(contextSpecifier, for: "expected")
					.with(context, for: "received")
					.appending(
						.message(
							"FeatureLoader is invalid",
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
			context: LoadableFeatureContext,
			using features: Features
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
					.with(context.typeDescription, for: "received")
					.appending(
						.message(
							"FeatureLoader is invalid",
							file: file,
							line: line
						)
					)
					.asFatalError()
			}

			loadingCompletion(feature, context, features)
		}

		#if DEBUG
			return Self(
				from: LoadableFeatureLoader(
					debugContext: .context(
						message: "FeatureLoader.disposable",
						file: file,
						line: line
					)
					.with(featureType, for: "feature")
					.with(implementation, for: "implementation")
					.with(false, for: "cache"),
					identifier: .init(
						featureType: Feature.self,
						contextSpecifier: contextSpecifier
					),
					load: featureLoad(context:using:),
					loadingCompletion: featureLoadingCompletion(_:context:using:),
					unload: .none
				)
			)
		#else
			return Self(
				from: LoadableFeatureLoader(
					identifier: .init(
						featureType: Feature.self,
						contextSpecifier: contextSpecifier
					),
					load: featureLoad(context:using:),
					loadingCompletion: featureLoadingCompletion(_:context:using:),
					unload: .none
				)
			)
		#endif
	}

	/// Make instance of loader for lazily loaded constant feature.
	///
	/// Lazy constant feature loader provides implementation of features which instances are
	/// constant but lazily loaded during application lifetime. Constant features are always
	/// cached inside ``Features`` container but it always returns the same instance of a feature anyway.
	///
	/// - Note: ``Context`` is used to identify instances based
	/// on its value. Make sure that you define constant for each
	/// required context value.
	///
	/// - Parameters:
	///   - featureType: Type of the feature provided by created loader.
	///   - contextSpecifier: Feature context value for which constant will be used.
	///   - implementation: Name of given implementation used to identify feature implementation.
	///   By default it is name of a function enclosing invocation of this function.
	///   - instance: Instance of a feature to be used as its implementation. It is wrapped
	///   by autoclosure to lazily initialize the instance. Feature will be initialized only on demand. The same instance will be used for all feature instance requests.
	///   - loadingCompletion: Function allowing to execute initial operations after loading
	///   instance of feature. This function will be called only once
	///   after first request for the feature instance.
	///   Default implementation does nothing.
	///   - file: Source code file identifier used to identify feature implementation.
	///   Filled automatically based on compile time constants.
	///   - line: Line in given source code file used to identify feature implementation.
	///   Filled automatically based on compile time constants.
	/// - Returns: Instance of ``FeatureLoader`` providing constant implementation of a given feature.
	@_disfavoredOverload public static func constant(
		_ featureType: Feature.Type = Feature.self,
		contextSpecifier: Feature.Context,
		implementation: StaticString = #function,
		instance: @autoclosure @escaping () -> Feature,
		loadingCompletion: @escaping (_ instance: Feature) -> Void = noop,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self
	where Feature: LoadableFeature {
		lazy var lazyInstance: Feature = {
			let feature: Feature = instance()
			loadingCompletion(feature)
			return feature
		}()

		#if DEBUG
			return Self(
				from: LoadableFeatureLoader(
					debugContext: .context(
						message: "FeatureLoader.constant",
						file: file,
						line: line
					)
					.with(featureType, for: "feature")
					.with(implementation, for: "implementation")
					.with(true, for: "cache"),
					identifier: .init(
						featureType: Feature.self,
						contextSpecifier: contextSpecifier
					),
					load: always(lazyInstance),
					loadingCompletion: noop,
					unload: noop  // cache is not required but speeds up access
				)
			)
		#else
			return Self(
				from: LoadableFeatureLoader(
					identifier: .init(
						featureType: Feature.self,
						contextSpecifier: contextSpecifier
					),
					load: always(lazyInstance),
					loadingCompletion: noop,
					unload: noop  // cache is not required but speeds up access
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
	public static func lazyLoaded<Tag>(
		_ featureType: Feature.Type = Feature.self,
		implementation: StaticString = #function,
		load: @escaping @MainActor (_ container: Features) throws -> Feature,
		loadingCompletion: @escaping @MainActor (_ instance: Feature, _ container: Features) -> Void = noop,
		unload: @escaping (_ instance: Feature) -> Void = noop,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self
	where Feature: LoadableFeature, Feature.Context == TagFeatureContext<Tag> {
		@MainActor func featureLoad(
			context _: LoadableFeatureContext,  // placeholder
			using features: Features
		) throws -> AnyFeature {
			try load(features)
		}

		@MainActor func featureLoadingCompletion(
			_ feature: AnyFeature,
			context _: LoadableFeatureContext,  // placeholder
			using features: Features
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

			loadingCompletion(feature, features)
		}

		func featureUnload(
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
				from: LoadableFeatureLoader(
					debugContext: .context(
						message: "FeatureLoader.lazyLoaded",
						file: file,
						line: line
					)
					.with(featureType, for: "feature")
					.with(implementation, for: "implementation")
					.with(true, for: "cache"),
					identifier: .init(
						featureType: Feature.self,
						contextSpecifier: .context
					),
					load: featureLoad(context:using:),
					loadingCompletion: featureLoadingCompletion(_:context:using:),
					unload: featureUnload(_:)
				)
			)
		#else
			return Self(
				from: LoadableFeatureLoader(
					identifier: .init(
						featureType: Feature.self,
						contextSpecifier: .context
					),
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
	public static func disposable<Tag>(
		_ featureType: Feature.Type = Feature.self,
		implementation: StaticString = #function,
		load: @escaping @MainActor (_ container: Features) throws -> Feature,
		loadingCompletion: @escaping @MainActor (_ instance: Feature, _ container: Features) -> Void = noop,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self
	where Feature: LoadableFeature, Feature.Context == TagFeatureContext<Tag> {
		@MainActor func featureLoad(
			context _: LoadableFeatureContext,  // placeholder
			using features: Features
		) throws -> AnyFeature {
			try load(features)
		}

		@MainActor func featureLoadingCompletion(
			_ feature: AnyFeature,
			context _: LoadableFeatureContext,  // placeholder
			using features: Features
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

			loadingCompletion(feature, features)
		}

		#if DEBUG
			return Self(
				from: LoadableFeatureLoader(
					debugContext: .context(
						message: "FeatureLoader.disposable",
						file: file,
						line: line
					)
					.with(featureType, for: "feature")
					.with(implementation, for: "implementation")
					.with(false, for: "cache"),
					identifier: .init(
						featureType: Feature.self,
						contextSpecifier: .context
					),
					load: featureLoad(context:using:),
					loadingCompletion: featureLoadingCompletion(_:context:using:),
					unload: .none
				)
			)
		#else
			return Self(
				from: LoadableFeatureLoader(
					identifier: .init(
						featureType: Feature.self,
						contextSpecifier: .context
					),
					load: featureLoad(context:using:),
					loadingCompletion: featureLoadingCompletion(_:context:using:),
					unload: .none
				)
			)
		#endif
	}

	/// Make instance of loader for lazily loaded constant feature.
	///
	/// Lazy constant feature loader provides implementation of features which instances are
	/// constant but lazily loaded during application lifetime. Constant features are always
	/// cached inside ``Features`` container but it always returns the same instance of a feature anyway.
	///
	///
	/// - Parameters:
	///   - featureType: Type of the feature provided by created loader.
	///   - implementation: Name of given implementation used to identify feature implementation.
	///   By default it is name of a function enclosing invocation of this function.
	///   - instance: Instance of a feature to be used as its implementation. It is wrapped
	///   by autoclosure to lazily initialize the instance. Feature will be initialized only on demand. The same instance will be used for all feature instance requests.
	///   - loadingCompletion: Function allowing to execute initial operations after loading
	///   instance of feature. This function will be called only once
	///   after first request for the feature instance.
	///   Default implementation does nothing.
	///   - file: Source code file identifier used to identify feature implementation.
	///   Filled automatically based on compile time constants.
	///   - line: Line in given source code file used to identify feature implementation.
	///   Filled automatically based on compile time constants.
	/// - Returns: Instance of ``FeatureLoader`` providing constant implementation of a given feature.
	public static func constant<Tag>(
		_ featureType: Feature.Type = Feature.self,
		implementation: StaticString = #function,
		instance: @autoclosure @escaping () -> Feature,
		loadingCompletion: @escaping (Feature) -> Void = noop,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self
	where Feature: LoadableFeature, Feature.Context == TagFeatureContext<Tag> {
		lazy var lazyInstance: Feature = {
			let feature: Feature = instance()
			loadingCompletion(feature)
			return feature
		}()

		#if DEBUG
			return Self(
				from: LoadableFeatureLoader(
					debugContext: .context(
						message: "FeatureLoader.constant",
						file: file,
						line: line
					)
					.with(featureType, for: "feature")
					.with(implementation, for: "implementation")
					.with(true, for: "cache"),
					identifier: .init(
						featureType: Feature.self,
						contextSpecifier: .context
					),
					load: always(lazyInstance),
					loadingCompletion: noop,
					unload: noop  // cache is not required but speeds up access
				)
			)
		#else
			return Self(
				from: LoadableFeatureLoader(
					identifier: .init(
						featureType: Feature.self,
						contextSpecifier: .context
					),
					load: always(lazyInstance),
					loadingCompletion: noop,
					unload: noop  // cache is not required but speeds up access
				)
			)
		#endif
	}
}

extension FeatureLoader {

	@inline(__always)
	internal var asAnyLoader: LoadableFeatureLoader {
		self.loader
	}

	@inline(__always)
	@MainActor internal func loadInstance(
		context: Feature.Context,
		features: Features
	) throws -> Feature
	where Feature: LoadableFeature {
		let loadedFeature: AnyFeature = try self.loader.load(context, features)

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
	@MainActor internal func instanceLoadingCompletion(
		_ instance: Feature,
		context: Feature.Context,
		features: Features
	) where Feature: LoadableFeature {
		self.loader.loadingCompletion(instance, context, features)
	}

	internal var erasedUnload: LoadableFeatureLoader.Unload? {
		self.loader.unload
	}
}

extension LoadableFeatureLoader {

	internal func asLoader<Feature>(
		for featureType: Feature.Type,
		context: Feature.Context,
		file: StaticString = #fileID,
		line: UInt = #line
	) throws -> FeatureLoader<Feature>
	where Feature: LoadableFeature {
		guard self.identifier.matches(featureType: Feature.self, contextSpecifier: context)
		else {
			throw
				InternalInconsistency
				.error(message: "Feature loader is not matching expected, please report a bug.")
				.with(Feature.typeDescription, for: "expected")
				.with(self.identifier.typeDescription, for: "received")
				.with(context, for: "expected context")
				.with(self.identifier.contextDescription, for: "received context")
				.asAssertionFailure()
		}

		return .init(from: self)
	}
}
