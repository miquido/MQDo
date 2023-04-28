public struct FeatureLoader {

	internal typealias AnyFeature = Any
	internal typealias AnyFeatureContext = Any

	internal let featureType: Any.Type
	internal let identifier: FeatureIdentifier
	fileprivate let loadInstance: @Sendable (AnyFeatureContext, Features) throws -> AnyFeature
	#if DEBUG
	internal let implementation: String
	internal let file: StaticString
	internal let line: UInt
	#endif
}

extension FeatureLoader: Sendable {}

extension FeatureLoader: CustomStringConvertible {

	public var description: String {
		"FeatureLoader<\(self.featureType)>"
	}
}

extension FeatureLoader: CustomDebugStringConvertible {

	public var debugDescription: String {
		#if DEBUG
		"Feature: \(self.featureType)\nImplementation: \(self.implementation)\nSource: \(self.file):\(self.line)"
		#else
		"FeatureLoader<\(self.featureType)>"
		#endif
	}
}

extension FeatureLoader: CustomReflectable {

	public var customMirror: Mirror {
		.init(
			self,
			children: [
				"featureType": self.featureType
			]
		)
	}
}

extension FeatureLoader {

	public func isLoaderFor<Feature>(
		_ type: Feature.Type
	) -> Bool {
		self.featureType == type
	}
}

extension FeatureLoader {

	public func loadInstance<Feature>(
		of _: Feature.Type,
		context: Feature.Context,
		using features: Features,
		file: StaticString = #fileID,
		line: UInt = #line
	) throws -> Feature
	where Feature: DisposableFeature {
		do {
			if self.isLoaderFor(Feature.self),
				let instance: Feature = try self.loadInstance(context, features) as? Feature
			{
				return instance
			}
			else {
				throw
					InternalInconsistency
					.error(
						message: "Type mismatch in disposable feature load."
					)
					.asRuntimeWarning(
						message: "Asking loader for a wrong type is a bug.",
						file: file,
						line: line
					)
			}
		}
		catch {
			throw
				FeatureLoadingFailed
				.error(
					feature: Feature.self,
					cause: error.asTheError(),
					file: file,
					line: line
				)
		}
	}

	public func loadInstance<Feature>(
		of _: Feature.Type,
		context: Feature.Context,
		using features: Features,
		file: StaticString = #fileID,
		line: UInt = #line
	) throws -> Feature
	where Feature: CacheableFeature {
		do {
			if self.isLoaderFor(Feature.self),
				let instance: Feature = try self.loadInstance(context, features) as? Feature
			{
				return instance
			}
			else {
				throw
					InternalInconsistency
					.error(
						message: "Type mismatch in cacheable feature load."
					)
					.asRuntimeWarning(
						message: "Asking loader for a wrong type is a bug.",
						file: file,
						line: line
					)
			}
		}
		catch {
			throw
				FeatureLoadingFailed
				.error(
					feature: Feature.self,
					cause: error.asTheError(),
					file: file,
					line: line
				)
		}
	}
}

extension FeatureLoader {

	public static func unavailable<Feature>(
		_: Feature.Type = Feature.self,
		message: StaticString = "Feature unavailable",
		displayableMessage: DisplayableString = TheErrorDisplayableMessages.message(for: FeatureUnavailable.self),
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self
	where Feature: DisposableFeature {
		#if DEBUG
		return Self(
			featureType: Feature.self,
			identifier: Feature.identifier(),
			loadInstance: { (_: AnyFeatureContext, container: Features) throws -> Feature in
				throw
					FeatureUnavailable
					.error(
						message: message,
						displayableMessage: displayableMessage,
						feature: Feature.self,
						file: file,
						line: line
					)
			},
			implementation: "unavailable",
			file: file,
			line: line
		)
		#else
		return Self(
			featureType: Feature.self,
			identifier: Feature.identifier(),
			loadInstance: { (_: AnyFeatureContext, container: Features) throws -> Feature in
				throw
					FeatureUnavailable
					.error(
						message: message,
						displayableMessage: displayableMessage,
						feature: Feature.self,
						file: file,
						line: line
					)
			}
		)
		#endif
	}

	public static func unavailable<Feature>(
		_: Feature.Type = Feature.self,
		message: StaticString = "Feature unavailable",
		displayableMessage: DisplayableString = TheErrorDisplayableMessages.message(for: FeatureUnavailable.self),
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self
	where Feature: CacheableFeature {
		#if DEBUG
		return Self(
			featureType: Feature.self,
			identifier: Feature.identifier(),
			loadInstance: { (_: AnyFeatureContext, container: Features) throws -> Feature in
				throw
					FeatureUnavailable
					.error(
						message: message,
						displayableMessage: displayableMessage,
						feature: Feature.self,
						file: file,
						line: line
					)
			},
			implementation: "unavailable",
			file: file,
			line: line
		)
		#else
		return Self(
			featureType: Feature.self,
			identifier: Feature.identifier(),
			loadInstance: { (_: AnyFeatureContext, container: Features) throws -> Feature in
				throw
					FeatureUnavailable
					.error(
						message: message,
						displayableMessage: displayableMessage,
						feature: Feature.self,
						file: file,
						line: line
					)
			}
		)
		#endif
	}
}

extension FeatureLoader {

	public static func disposable<Feature>(
		_: Feature.Type = Feature.self,
		implementation: String = #function,
		load: @escaping @Sendable (_ container: Features) throws -> Feature,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self
	where Feature: DisposableFeature, Feature.Context == Void {
		#if DEBUG
		return Self(
			featureType: Feature.self,
			identifier: Feature.identifier(),
			loadInstance: { (_: AnyFeatureContext, container: Features) throws -> Feature in
				try load(container)
			},
			implementation: implementation,
			file: file,
			line: line
		)
		#else
		return Self(
			featureType: Feature.self,
			identifier: Feature.identifier(),
			loadInstance: { (_: AnyFeatureContext, container: Features) throws -> Feature in
				try load(container)
			}
		)
		#endif
	}

	public static func disposable<Feature>(
		_: Feature.Type = Feature.self,
		implementation: String = #function,
		load: @escaping @Sendable (_ context: Feature.Context, _ container: Features) throws -> Feature,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self
	where Feature: DisposableFeature {
		#if DEBUG
		return Self(
			featureType: Feature.self,
			identifier: Feature.identifier(),
			loadInstance: { (context: AnyFeatureContext, container: Features) throws -> Feature in
				if let context: Feature.Context = context as? Feature.Context {
					return try load(context, container)
				}
				else {
					throw
						InternalInconsistency
						.error(
							message: "Invalid feature loader."
						)
						.asAssertionFailure(
							message: "Type mismatch in features loader. Please report a bug."
						)
				}
			},
			implementation: implementation,
			file: file,
			line: line
		)
		#else
		return Self(
			featureType: Feature.self,
			identifier: Feature.identifier(),
			loadInstance: { (context: AnyFeatureContext, container: Features) throws -> Feature in
				if let context: Feature.Context = context as? Feature.Context {
					return try load(context, container)
				}
				else {
					throw
						InternalInconsistency
						.error(
							message: "Invalid feature loader."
						)
						.asAssertionFailure(
							message: "Type mismatch in features loader. Please report a bug."
						)
				}
			}
		)
		#endif
	}
}

extension FeatureLoader {

	public static func cacheable<Feature>(
		_: Feature.Type = Feature.self,
		implementation: String = #function,
		load: @escaping @Sendable (_ container: Features) throws -> Feature,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self
	where Feature: CacheableFeature, Feature.Context == CacheableFeatureVoidContext {
		#if DEBUG
		return Self(
			featureType: Feature.self,
			identifier: Feature.identifier(),
			loadInstance: { (_: AnyFeatureContext, container: Features) throws -> Feature in
				try load(container)
			},
			implementation: implementation,
			file: file,
			line: line
		)
		#else
		return Self(
			featureType: Feature.self,
			identifier: Feature.identifier(),
			loadInstance: { (_: AnyFeatureContext, container: Features) throws -> Feature in
				try load(container)
			}
		)
		#endif
	}

	public static func cacheable<Feature>(
		_: Feature.Type = Feature.self,
		implementation: String = #function,
		load: @escaping @Sendable (_ context: Feature.Context, _ container: Features) throws -> Feature,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self
	where Feature: CacheableFeature {
		#if DEBUG
		return Self(
			featureType: Feature.self,
			identifier: Feature.identifier(),
			loadInstance: { (context: AnyFeatureContext, container: Features) throws -> Feature in
				if let context: Feature.Context = context as? Feature.Context {
					return try load(context, container)
				}
				else {
					throw
						InternalInconsistency
						.error(
							message: "Invalid feature loader."
						)
						.asAssertionFailure(
							message: "Type mismatch in features loader. Please report a bug."
						)
				}
			},
			implementation: implementation,
			file: file,
			line: line
		)
		#else
		return Self(
			featureType: Feature.self,
			identifier: Feature.identifier(),
			loadInstance: { (context: AnyFeatureContext, container: Features) throws -> Feature in
				if let context: Feature.Context = context as? Feature.Context {
					return try load(context, container)
				}
				else {
					throw
						InternalInconsistency
						.error(
							message: "Invalid feature loader."
						)
						.asAssertionFailure(
							message: "Type mismatch in features loader. Please report a bug."
						)
				}
			}
		)
		#endif
	}
}
