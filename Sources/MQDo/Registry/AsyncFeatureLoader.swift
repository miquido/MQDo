public struct AsyncFeatureLoader {

	internal typealias AnyFeature = Any
	internal typealias AnyFeatureContext = Any

	internal let featureType: Any.Type
	internal let identifier: FeatureIdentifier
	fileprivate let loadInstance: @Sendable (AnyFeatureContext, Features) async throws -> AnyFeature
	#if DEBUG
		internal let implementation: String
		internal let file: StaticString
		internal let line: UInt
	#endif
}

extension AsyncFeatureLoader: Sendable {}

extension AsyncFeatureLoader: CustomStringConvertible {

	public var description: String {
		"AsyncFeatureLoader<\(self.featureType)>"
	}
}

extension AsyncFeatureLoader: CustomDebugStringConvertible {

	public var debugDescription: String {
		#if DEBUG
			"Feature: \(self.featureType)\nImplementation: \(self.implementation)\nSource: \(self.file):\(self.line)"
		#else
			"AsyncFeatureLoader<\(self.featureType)>"
		#endif
	}
}

extension AsyncFeatureLoader: CustomReflectable {

	public var customMirror: Mirror {
		.init(
			self,
			children: [
				"featureType": self.featureType
			]
		)
	}
}

extension AsyncFeatureLoader {

	public func isLoaderFor<Feature>(
		_ type: Feature.Type
	) -> Bool {
		self.featureType == type
	}
}

extension AsyncFeatureLoader {

	public func loadInstance<Feature>(
		of _: Feature.Type,
		context: Feature.Context,
		using features: Features,
		file: StaticString = #fileID,
		line: UInt = #line
	) async throws -> Feature
	where Feature: AsyncDisposableFeature {
		do {
			if self.isLoaderFor(Feature.self),
				let instance: Feature = try await self.loadInstance(context, features) as? Feature
			{
				return instance
			}
			else {
				throw
					InternalInconsistency
					.error(
						message: "Type mismatch in async disposable feature load."
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

extension AsyncFeatureLoader {

	public static func unavailable<Feature>(
		_: Feature.Type = Feature.self,
		message: StaticString = "Feature unavailable",
		displayableMessage: DisplayableString = TheErrorDisplayableMessages.message(for: FeatureUnavailable.self),
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self
	where Feature: AsyncDisposableFeature {
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

extension AsyncFeatureLoader {

	public static func asyncDisposable<Feature>(
		_: Feature.Type = Feature.self,
		implementation: String = #function,
		load: @escaping @Sendable (_ container: Features) async throws -> Feature,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self
	where Feature: AsyncDisposableFeature, Feature.Context == Void {
		#if DEBUG
			return Self(
				featureType: Feature.self,
				identifier: Feature.identifier(),
				loadInstance: { (_: AnyFeatureContext, container: Features) throws -> Feature in
					try await load(container)
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
					try await load(container)
				}
			)
		#endif
	}

	public static func asyncDisposable<Feature>(
		_: Feature.Type = Feature.self,
		implementation: String = #function,
		load: @escaping @Sendable (_ context: Feature.Context, _ container: Features) async throws -> Feature,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self
	where Feature: AsyncDisposableFeature {
		#if DEBUG
			return Self(
				featureType: Feature.self,
				identifier: Feature.identifier(),
				loadInstance: { (context: AnyFeatureContext, container: Features) async throws -> Feature in
					if let context: Feature.Context = context as? Feature.Context {
						return try await load(context, container)
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
				loadInstance: { (context: AnyFeatureContext, container: Features) async throws -> Feature in
					if let context: Feature.Context = context as? Feature.Context {
						return try await load(context, container)
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
