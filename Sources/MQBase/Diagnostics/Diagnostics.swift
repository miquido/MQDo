import MQDo
import OSLog

import class Foundation.NSProcessInfo

#if os(iOS)
	import class UIKit.UIDevice
#endif

// MARK: - Interface

public struct Diagnostics {

	public var appInfo: @Sendable () -> String
	public var deviceInfo: @Sendable () -> String
	public var log: @Sendable (Log) -> Void
	public var diagnosticsInfo: @Sendable () -> Array<String>
}

extension Diagnostics: StaticFeature {

	public enum Log {

		case info(StaticString)
		case error(TheError)
		case debug(String)
	}
}

// MARK: - Implementation

extension Diagnostics {

	@available(iOS 14.0, tvOS 14.0, *)
	public static var osDiagnostics: Diagnostics {
		let infoDictionary: Dictionary<String, Any> = Bundle.main.infoDictionary ?? .init()
		let appName: String = infoDictionary["CFBundleName"] as? String ?? "App"
		let appVersion: String = infoDictionary["CFBundleShortVersionString"] as? String ?? "?.?.?"
		let appBundleIdentifier: String = infoDictionary["CFBundleIdentifier"] as? String ?? "com.miquido.mqdo"
		#if os(iOS)
			let deviceModel: String = UIDevice.current.model
		#elseif os(watchOS)
			let deviceModel: String = "Apple Watch"
		#elseif os(tvOS)
			let deviceModel: String = "Apple TV"
		#else
			let deviceModel: String = "Mac"
		#endif
		let systemVersion: String = ProcessInfo.processInfo.operatingSystemVersionString

		let logger: Logger = .init(
			subsystem: appBundleIdentifier + ".diagnostics",
			category: "diagnostic"
		)

		@Sendable func appInfo() -> String {
			"\(appName) \(appVersion)"
		}

		@Sendable func deviceInfo() -> String {
			"\(deviceModel) iOS \(systemVersion)"
		}

		@Sendable func log(
			_ log: Log
		) {
			switch log {
			case .info(let message):
				logger.info("\(message, privacy: .public)")

			case .error(let error):
				#if DEBUG
					print(error.debugDescription)
				#else
					logger.error("\(error.description, privacy: .auto)")
				#endif

			case .debug(let message):
				#if DEBUG
					print(message)
				#else
					logger.debug("\n\(message, privacy: .private)")
				#endif
			}
		}

		@Sendable func diagnosticsInfo() -> Array<String> {
			let environmentInfo: String = "\(deviceInfo()) \(appInfo())"
			if #available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *) {
				do {
					let logStore: OSLogStore = try .init(scope: .currentProcessIdentifier)
					let dateFormatter: DateFormatter = .init()
					dateFormatter.timeZone = .init(secondsFromGMT: 0)
					dateFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
					return try [environmentInfo]
						+ logStore
						.getEntries(
							at:
								logStore
								.position(  // last hour
									date: Date(timeIntervalSinceNow: -60 * 60)
								),
							matching: NSPredicate(
								format: "category == %@",
								argumentArray: ["diagnostic"]
							)
						)
						.map { logEntry in
							"[\(dateFormatter.string(from: logEntry.date))] \(logEntry.composedMessage)"
						}
				}
				catch {
					return [
						environmentInfo,
						"Logs are not available",
					]
				}
			}
			else {
				return [
					environmentInfo,
					"Logs are not available",
				]
			}
		}

		return .init(
			appInfo: appInfo,
			deviceInfo: deviceInfo,
			log: log(_:),
			diagnosticsInfo: diagnosticsInfo
		)
	}

	public static var disabled: Diagnostics {
		.init(
			appInfo: { "N/A" },
			deviceInfo: { "N/A" },
			log: { (_: Log) in /* noop */ },
			diagnosticsInfo: { ["N/A"] }
		)
	}

	#if DEBUG

		public static var placeholder: Diagnostics {
			.init(
				appInfo: unimplemented(),
				deviceInfo: unimplemented(),
				log: unimplemented(),
				diagnosticsInfo: unimplemented()
			)
		}
	#endif
}
