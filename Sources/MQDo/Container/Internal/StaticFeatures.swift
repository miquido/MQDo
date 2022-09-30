internal final class StaticFeatures {

	#if DEBUG
		private var features: Dictionary<StaticFeatureIdentifier, StaticFeatureInstance>
	#else
		private let features: Dictionary<StaticFeatureIdentifier, StaticFeatureInstance>
	#endif

	internal init(
		_ features: Dictionary<StaticFeatureIdentifier, StaticFeatureInstance> = .init()
	) {
		self.features = features
	}
}

extension StaticFeatures {

	#if DEBUG
		internal func use<Feature>(
			static instance: Feature,
			implementation: StaticString,
			file: StaticString,
			line: UInt
		) where Feature: StaticFeature {
			self.features[instance.identifier] = .init(
				instance,
				implementation: implementation,
				file: file,
				line: line
			)
		}
	#endif

	internal func instance<Feature>(
		of featureType: Feature.Type,
		file: StaticString,
		line: UInt
	) -> Feature
	where Feature: StaticFeature {
		if let instance: StaticFeatureInstance = self.features[Feature.identifier] {
			if let instance: Feature = instance.feature as? Feature {
				return instance
			}
			else {
				InternalInconsistency
					.error(
						message: "Feature is not matching expected type, please report a bug."
					)
					.with(Feature.self, for: "expected type")
					.with(instance.type, for: "received type")
					.appending(
						.message(
							"Feature instance is invalid",
							file: file,
							line: line
						)
					)
					.asFatalError()
			}
		}
		else {
			#if DEBUG
				let instance: Feature = .placeholder
				self.use(
					static: instance,
					implementation: "placeholder",
					file: file,
					line: line
				)
				return instance
			#else
				Unimplemented
					.error(
						message:
							"Static feature without implementation.",
						file: file,
						line: line
					)
					.with("\(Self.self)", for: "feature")
					.asFatalError(
						message:
							"Static features has to be defined when creating root Features container."
					)
			#endif
		}
	}
}
