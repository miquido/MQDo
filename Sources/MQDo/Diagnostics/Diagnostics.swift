import MQ

// MARK: - Interface

public struct Diagnostics {

	public enum Log {

		case info(StaticString)
		case error(TheError)
		case debug(String)
	}

	public var deviceInfo: @Sendable () -> String
	public var systemInfo: @Sendable () -> String
	public var applicationInfo: @Sendable () -> String
	public var log: @Sendable (Log) -> Void
	public var diagnosticsInfo: @Sendable () -> Array<String>
}

extension Diagnostics: StaticFeature {

	public static var placeholder: Diagnostics {
		.init(
			deviceInfo: unimplemented0(),
			systemInfo: unimplemented0(),
			applicationInfo: unimplemented0(),
			log: unimplemented1(),
			diagnosticsInfo: unimplemented0()
		)
	}
}

// MARK: - Implementation

extension Diagnostics {

	public static var disabled: Diagnostics {
		.init(
			deviceInfo: {
				FeatureUnavailable
					.error(feature: Diagnostics.self)
					.displayableMessage.resolved
			},
			systemInfo: {
				FeatureUnavailable
					.error(feature: Diagnostics.self)
					.displayableMessage.resolved
			},
			applicationInfo: {
				FeatureUnavailable
					.error(feature: Diagnostics.self)
					.displayableMessage.resolved
			},
			log: noop,
			diagnosticsInfo: always(.init())
		)
	}
}

extension OSDiagnostics: ImplementationOfStaticFeature {

	public init(
		with configuration: Void
	) {
		self = .shared
	}

	@_transparent @inline(__always)
	@Sendable public func log(
		_ log: Diagnostics.Log
	) {
		switch log {
		case .info(let message):
			self.log(message)

		case .error(let error):
			self.log(error)

		case .debug(let message):
			self.log(debug: message)
		}
	}

	public nonisolated var instance: Diagnostics {
		.init(
			deviceInfo: always(self.device),
			systemInfo: always(self.system),
			applicationInfo: always(self.application),
			log: self.log(_:),
			diagnosticsInfo: always(self.diagnosticsInfo())
		)
	}
}
