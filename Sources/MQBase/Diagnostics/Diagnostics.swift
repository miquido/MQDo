import MQDo

// MARK: - Interface

public struct Diagnostics {

	public enum Log {

		case info(StaticString)
		case error(TheError)
		case debug(String)
	}

	public var appInfo: @Sendable () -> String
	public var deviceInfo: @Sendable () -> String
	public var log: @Sendable (Log) -> Void
	public var diagnosticsInfo: @Sendable () -> Array<String>
}

extension Diagnostics: StaticFeature {

	public static var placeholder: Diagnostics {
		.init(
			appInfo: unimplemented0(),
			deviceInfo: unimplemented0(),
			log: unimplemented1(),
			diagnosticsInfo: unimplemented0()
		)
	}
}

// MARK: - Implementation

extension Diagnostics {

	public static var disabled: Diagnostics {
		.init(
			appInfo: { "N/A" },
			deviceInfo: { "N/A" },
			log: noop,
			diagnosticsInfo: { ["N/A"] }
		)
	}

	public static var os: Diagnostics {
		OSDiagnostics.shared.instance
	}
}

extension OSDiagnostics: ImplementationOfStaticFeature {

	@_transparent
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
			appInfo: self.appInfo,
			deviceInfo: self.deviceInfo,
			log: self.log(_:),
			diagnosticsInfo: self.diagnosticsInfo
		)
	}
}
