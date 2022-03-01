import MQ

/// Type providing implementations for ``LoadableFeature``.
///
/// ``FeatureLoader`` is a description used to provide implementations of ``LoadableFeature``.
/// ``Features`` container uses it to load and cache instances of a given feature.
/// It is used to define how to load instances, optionally triggering its initial tasks
/// and allowing cache for a given feature.
/// ``FeatureLoader`` is intended to be a source of all ``LoadableFeature`` implementations
/// allowing to manage and identify concrete implementations and its availability.
public struct FeatureLoader<Feature> where Feature: LoadableFeature {

	#if DEBUG
		internal var debugContext: SourceCodeContext {
			self.loader.debugContext
		}
	#endif
	private let loader: AnyFeatureLoader

	internal init(
		from loader: AnyFeatureLoader
	) {
		guard loader.featureType == Feature.self
		else {
			InternalInconsistency
				.error(message: "FeatureLoader instance is not matching expected type")
				.with(loader, for: "loader")
				.with(Feature.self, for: "expected")
				.with(loader.featureType, for: "received")
				.asFatalError()
		}
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
	/// dynamically, lazily loaded and cached. Each time the instance is requested
	/// the same instance within the same scope will be provided.
	///
	/// - Parameters:
	///   - featureType: Type of the feature provided by created loader.
	///   - implementation: Name of given implementation used to identify feature implementation.
	///   By default it is name of a function enclosing invocation of this function.
	///   - load: Function which produces new instances of given feature.
	///   - loadingCompletion: Function allowing to execute initial operations after loading
	///   instance of feature. It can be also used to resolve circular dependencies.
	///   If loading completion fails (throws) then feature won't be cached
	///   nor returned from container. Default implementation does nothing.
	///   - cacheRemoval: Function called when instance of feature is going to be removed from cache.
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
		load: @escaping (Feature.Context, Features) throws -> Feature,
		loadingCompletion: @escaping (Feature, Features) throws -> Void = noop,
		cacheRemoval: @escaping (Feature) throws -> Void = noop,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self {
		func featureLoad(
			context: Any?,
			within features: Features
		) throws -> AnyFeature {
			guard let context: Feature.Context = context as? Feature.Context
			else {
				InternalInconsistency
					.error(message: "Feature context is not matching expected type")
					.with(Feature.Context.self, for: "expected")
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
			return try load(context, features)
		}

		func featureLoadingCompletion(
			_ feature: AnyFeature,
			within features: Features
		) throws {
			guard let feature: Feature = feature as? Feature
			else {
				InternalInconsistency
					.error(message: "Feature is not matching expected type")
					.with(Feature.self, for: "expected")
					.with(type(of: feature), for: "received")
					.appending(
						.message(
							"FeatureLoader is invalid",
							file: file,
							line: line
						)
					)
					.asFatalError()
			}
			try loadingCompletion(feature, features)
		}

		func featureCacheRemoval(
			of feature: AnyFeature
		) throws {
			guard let feature: Feature = feature as? Feature
			else {
				InternalInconsistency
					.error(message: "Feature is not matching expected type")
					.with(Feature.self, for: "expected")
					.with(type(of: feature), for: "received")
					.appending(
						.message(
							"FeatureLoader is invalid",
							file: file,
							line: line
						)
					)
					.asFatalError()
			}
			try cacheRemoval(feature)
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
					.with(true, for: "cache instances"),
					featureType: Feature.self,
					load: featureLoad(context:within:),
					loadingCompletion: featureLoadingCompletion(_:within:),
					cacheRemoval: featureCacheRemoval(of:)
				)
			)
		#else
			return Self(
				from: AnyFeatureLoader(
					featureType: Feature.self,
					load: featureLoad(context:within:),
					loadingCompletion: featureLoadingCompletion(_:within:),
					cacheRemoval: featureCacheRemoval(of:)
				)
			)
		#endif
	}

	/// Make instance of loader for disposable feature.
	///
	/// Disposable feature loader provides implementation of a features which are
	/// dynamically, lazily loaded and not cached. Each time the instance is requested
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
		load: @escaping (Feature.Context, Features) throws -> Feature,
		loadingCompletion: @escaping (Feature, Features) throws -> Void = noop,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self {
		func featureLoad(
			context: Any?,
			within features: Features
		) throws -> AnyFeature {
			guard let context: Feature.Context = context as? Feature.Context
			else {
				InternalInconsistency
					.error(message: "Feature context is not matching expected type")
					.with(Feature.Context.self, for: "expected")
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
			return try load(context, features)
		}

		func featureLoadingCompletion(
			_ feature: AnyFeature,
			within features: Features
		) throws {
			guard let feature: Feature = feature as? Feature
			else {
				InternalInconsistency
					.error(message: "Feature is not matching expected type")
					.with(Feature.self, for: "expected")
					.with(type(of: feature), for: "received")
					.appending(
						.message(
							"FeatureLoader is invalid",
							file: file,
							line: line
						)
					)
					.asFatalError()
			}
			try loadingCompletion(feature, features)
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
					.with(false, for: "cache instances"),
					featureType: Feature.self,
					load: featureLoad(context:within:),
					loadingCompletion: featureLoadingCompletion(_:within:),
					cacheRemoval: .none
				)
			)
		#else
			return Self(
				from: AnyFeatureLoader(
					featureType: Feature.self,
					load: featureLoad(context:within:),
					loadingCompletion: featureLoadingCompletion(_:within:),
					cacheRemoval: .none
				)
			)
		#endif
	}
}

extension FeatureLoader {

	/// Make instance of loader for lazy loaded feature.
	///
	/// Lazy loaded feature loader provides implementation of a features which are
	/// dynamically, lazily loaded and cached.
	///
	/// - Parameters:
	///   - featureType: Type of the feature provided by created loader.
	///   - implementation: Name of given implementation used to identify feature implementation.
	///   By default it is name of a function enclosing invocation of this function.
	///   - load: Function which produces new instances of given feature.
	///   - loadingCompletion: Function allowing to execute initial operations after loading
	///   instance of feature. It can be also used to resolve circular dependencies.
	///   If loading completion fails (throws) then feature won't be cached
	///   nor returned from container. Default implementation does nothing.
	///   - cacheRemoval: Function called when instance of feature is going to be removed from cache.
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
		load: @escaping (Features) throws -> Feature,
		loadingCompletion: @escaping (Feature, Features) throws -> Void = noop,
		cacheRemoval: @escaping (Feature) throws -> Void = noop,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self
	where Feature.Context == TagFeatureContext<Tag> {
		lazyLoaded(
			featureType,
			implementation: implementation,
			load: { (_: Any, features: Features) throws -> Feature in
				try load(features)
			},
			loadingCompletion: loadingCompletion,
			cacheRemoval: cacheRemoval,
			file: file,
			line: line
		)
	}

	/// Make instance of loader for disposable feature.
	///
	/// Disposable feature loader provides implementation of a features which are
	/// dynamically, lazily loaded and not cached. Each time the instance is requested
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
		load: @escaping (Features) throws -> Feature,
		loadingCompletion: @escaping (Feature, Features) throws -> Void = noop,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self
	where Feature.Context == TagFeatureContext<Tag> {
		disposable(
			featureType,
			implementation: implementation,
			load: { (_: Any, features: Features) throws -> Feature in
				try load(features)
			},
			loadingCompletion: loadingCompletion,
			file: file,
			line: line
		)
	}
}

extension FeatureLoader {

	/// Make instance of loader for lazily loaded constant feature.
	///
	/// Lazy constant feature loader provides implementation of features which instances are
	/// constant but lazily loaded during application lifetime. Constant features are never
	/// cached inside ``Features`` container but it always returns the same instance of a feature.
	///
	/// - Note: Only features which ``Context`` is ``TagFeatureContext`` can be constants.
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
	where Feature.Context == TagFeatureContext<Tag> {
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
					.with(false, for: "cache instances"),
					featureType: Feature.self,
					load: always(lazyInstance),
					loadingCompletion: noop,
					cacheRemoval: noop
				)
			)
		#else
			return Self(
				from: AnyFeatureLoader(
					featureType: Feature.self,
					load: always(lazyInstance),
					loadingCompletion: noop,
					cacheRemoval: noop
				)
			)
		#endif
	}
}

#if DEBUG
	extension FeatureLoader {

		/// Make instance of loader for feature placeholder.
		///
		/// Placeholder feature loader provides implementation of a features which
		/// always returns placeholder implementation for given feature.
		///
		/// - Parameters:
		///   - featureType: Type of the feature provided by created loader.
		///   - file: Source code file identifier used to identify feature implementation.
		///   Filled automatically based on compile time constants.
		///   - line: Line in given source code file used to identify feature implementation.
		///   Filled automatically based on compile time constants.
		/// - Returns: Instance of ``FeatureLoader`` providing placeholder implementation of given feature.
		public static func placeholder(
			_ featureType: Feature.Type = Feature.self,
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
					.with(false, for: "cache instances"),
					featureType: Feature.self,
					load: { (context: Any, features: Features) throws -> Feature in
						featureType.placeholder
					},
					loadingCompletion: noop,
					cacheRemoval: .none
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
	internal func load(
		context: Feature.Context,
		within features: Features
	) throws -> Feature {
		let loadedFeature: AnyFeature = try self.loader.load(context, features)
		guard let feature: Feature = loadedFeature as? Feature
		else {
			InternalInconsistency
				.error(message: "Feature is not matching expected type")
				.with(Feature.self, for: "expected")
				.with(type(of: loadedFeature), for: "received")
				.asFatalError()
		}
		return feature
	}

	@inline(__always)
	internal func loadingCompletion(
		feature: Feature,
		within features: Features
	) throws {
		try self.loader.loadingCompletion(feature, features)
	}

	@inline(__always)
	internal var cacheRemoval: FeaturesCache.Removal? {
		self.loader.cacheRemoval
	}
}
