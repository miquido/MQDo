internal struct StaticFeatureInstance {

	internal let identifier: StaticFeatureIdentifier
	private let type: StaticFeature.Type
	internal let instance: StaticFeature
	#if DEBUG
		internal let debugContext: SourceCodeContext
	#endif

	internal init<Feature>(
		instance: Feature,
		implementation: StaticString,
		file: StaticString,
		line: UInt
	) where Feature: StaticFeature {
		self.identifier = Feature.identifier
		self.type = Feature.self
		self.instance = instance
		#if DEBUG
			self.debugContext = .context(
				message: "StaticFeature.instance",
				file: file,
				line: line
			)
			.with(Feature.self, for: "feature")
			.with(implementation, for: "implementation")
		#endif
	}
}

extension StaticFeatureInstance: Sendable {}

// swift-format-ignore: AllPublicDeclarationsHaveDocumentation
extension StaticFeatureInstance: CustomStringConvertible {

	internal var description: String {
		"Instance of \(self.type.typeDescription)"
	}
}

// swift-format-ignore: AllPublicDeclarationsHaveDocumentation
extension StaticFeatureInstance: CustomDebugStringConvertible {

	internal var debugDescription: String {
		#if DEBUG
			"\(self.description)\n\(self.debugContext)"
		#else
			self.description
		#endif
	}
}
