internal struct FeaturesTreeRegistry {

	internal typealias DynamicFeatureLoaders = Dictionary<FeatureIdentifier, FeatureLoader>

	internal var staticFeatures: Dictionary<FeatureIdentifier, any StaticFeature> = .init()
	internal var scopedDynamicFeatureLoaders: Dictionary<FeaturesScopeIdentifier, DynamicFeatureLoaders>

	internal init() {
		self.staticFeatures = .init()
		self.scopedDynamicFeatureLoaders = [
			RootFeaturesScope.identifier(): .init()
		]
	}
}

extension FeaturesTreeRegistry: Sendable {}

extension FeaturesTreeRegistry {

	@inline(__always)
	internal func registry<Scope>(
		for scope: Scope.Type,
		file: StaticString,
		line: UInt
	) throws -> FeaturesScopeRegistry<Scope>
	where Scope: FeaturesScope {
		guard let scopeDynamicFeatureLoaders: DynamicFeatureLoaders = self.scopedDynamicFeatureLoaders[scope.identifier()]
		else {
			throw
				FeaturesScopeUndefined
				.error(
					scope: Scope.self,
					file: file,
					line: line
				)
				.asRuntimeWarning(
					message: "Undefined features scope. You have to define all scopes when creating features root.",
					file: file,
					line: line
				)
		}

		return .init(
			for: scope,
			dynamicFeatureLoaders: scopeDynamicFeatureLoaders
		)
	}
}

extension FeaturesTreeRegistry {

	@inline(__always)
	@Sendable internal func instance<Feature>(
		of _: Feature.Type,
		file: StaticString,
		line: UInt
	) -> Feature
	where Feature: StaticFeature {
		if let instance: any StaticFeature = self.staticFeatures[Feature.identifier()] {
			if let instance: Feature = instance as? Feature {
				return instance
			}
			else {
				InternalInconsistency
					.error(
						message: "Type mismatch when accessing static feature, please report a bug."
					)
					.asFatalError(
						file: file,
						line: line
					)
			}
		}
		else {
			FeatureUndefined
				.error(
					feature: Feature.self,
					file: file,
					line: line
				)
				.asFatalError(
					message: "All static features have to be defined.",
					file: file,
					line: line
				)
		}
	}
}
