import PlaygroundSupport
import Foundation
PlaygroundPage.current.needsIndefiniteExecution = true

// Import MQDo to begin your journey...
import MQDo
// Then let's prepare few features in a different way!

// Define feature interface using struct.
struct Logger {

	// Method required by interface.
	// This is equivalent of `@Sendable func logMessage(_ message: String)`
	var logMessage: @Sendable (String) -> Void
}

// Conform to one of a "feature" protocols.
// Static features are base functionalities which are always available.
// Note that all static features have to be sendable.
extension Logger: StaticFeature {

	// Placeholders are required for all features.
	// It is used to simplify mocking and testing.
	nonisolated static var placeholder: Self {
		.init(
			// Placeholder implementations
			// should crash or at least fail in tests.
			// `unimplemented` function is a nice fit here.
			logMessage: unimplemented1()
		)
	}
}

// Prepare an implementation of a feature.
// You can use a feature type namespace
// to define its implementations.
extension Logger {

	// For static features you have to provide an instance.
	// Here implementation is defined ad-hoc by constructing
	// an instance inside the scope.
	nonisolated static var stdout: Self {
		.init(
			logMessage: { print("MESSAGE: \($0)") }
		)
	}
}

// Here is the example of a cacheable feature.
// Cacheable features are reused after loading according
// to features tree and used scopes feature registry state.
struct NewsController {

	var fetchNews: @Sendable () async throws -> Void
	var newsList: @Sendable () -> Array<String>
	var prepareDetails: @Sendable (String) throws -> NewsDetails
}

// Note that all cacheable features have to be sendable.
// It can also have optional context (which is "Void" by default).
extension NewsController: CacheableFeature {

	nonisolated static var placeholder: Self {
		.init(
			fetchNews: unimplemented0(),
			newsList: unimplemented0(),
			prepareDetails: unimplemented1()
		)
	}
}

// You can use a feature type namespace to define
// its implementation through loaders.
extension NewsController {

	// This is ad-hoc implementation, below you can find
	// implementation using class as a base and dedicated
	// interface to speed up the process.
	static let liveImplementation: FeatureLoader = {
		.cacheable { (features: Features) -> Self in
			// You can access other features if needed.
			let logger: Logger = features.instance()

			let newsCache: CriticalSection<Array<String>> = .init(.init())

			@Sendable func fetchNews() async throws {
				// do network stuff...
				logger.logMessage("Fetching news...")
				try await Task.sleep(nanoseconds: NSEC_PER_SEC * 2)
				// and save to cache (synchronization required)
				newsCache.access { (news: inout Array<String>) in
					news = [
						"News...",
						"MQDo seems to be nice!",
						"... but only if you have seen it in action"
					]
				}
				logger.logMessage("...fetching news finished!")
			}

			@Sendable func newsList() -> Array<String> {
				newsCache.access(\.self)
			}

			@Sendable func prepareDetails(
				_ message: String
			) -> NewsDetails {
				do {
					// Accessing nonstatic features can fail.
					// You have to handle it properly.
					return try features.instance(context: message)
				}
				catch {
					logger.logMessage("Failed to prepare details!")
					error.asTheError().asFatalError()
				}
			}

			return .init(
				fetchNews: fetchNews,
				newsList: newsList,
				prepareDetails: prepareDetails
			)
		}
	}()
}

// Here is exactly the same implementation as above
// but using class as a base for implementing the same
// feature. You can see how similar it is and choose
// one which better suits you.
final class NewsControllerImplementation: ImplementationOfCacheableFeature
 {

	let features: Features
	let logger: Logger

	let newsCache: CriticalSection<Array<String>> = .init(.init())

	// This init becomes equivalent of "load" fuction
	// from feature loader (and eventually becomes called in one).
	init(
		with context: CacheableFeatureVoidContext,
		using features: Features
	) throws {
		self.features = features
		self.logger = features.instance()
	}

	// Instance is required by protocol to create actual
	// implementation of given feature interface.
	nonisolated var instance: NewsController {
		.init(
			fetchNews: fetchNews,
			newsList: newsList,
			prepareDetails: prepareDetails
		)
	}

	@Sendable func fetchNews() async throws {
		// do network stuff...
		logger.logMessage("Fetching news...")
		try await Task.sleep(nanoseconds: NSEC_PER_SEC * 2)
		// and save to cache (synchronization required)
		newsCache.access { (news: inout Array<String>) in
			news = [
				"News...",
				"MQDo seems to be nice!",
				"... but only if you have seen it in action"
			]
		}
		logger.logMessage("...fetching news finished!")
	}

	@Sendable func newsList() -> Array<String> {
		newsCache.access(\.self)
	}

	@Sendable func prepareDetails(
		_ message: String
	) -> NewsDetails {
		do {
			// Accessing nonstatic features can fail.
			// You have to handle it properly.
			return try features.instance(context: message)
		}
		catch {
			logger.logMessage("Failed to prepare details!")
			error.asTheError().asFatalError()
		}
	}
}

// Here is an example of a disposable feature.
// Disposable features are constructed on demand.
// Each time you request an instance the new one will be created.
struct NewsDetails {

	var details: () -> String
}

// Disposable features can also have context
// (similar to cachable ones) and it is also
// "Void" by default but it will be defined this time.
extension NewsDetails: DisposableFeature {

	// Context can be used to pass in some data
	// when creating instance of a feature.
	typealias Context = String

	static var placeholder: NewsDetails {
		.init(
			details: unimplemented0()
		)
	}
}

extension NewsDetails {

	static let liveImplementation: FeatureLoader = {
		.disposable { (context: Context, features: Features) -> Self in
				.init(
					details: always(context)
				)
		}
	}()
}

// Then you can create root of the features container tree.
// It is also a place to register all features.
let features: Features = FeaturesRoot { (rootRegistry: inout FeaturesRegistry<RootFeaturesScope>) in
	rootRegistry.use(Logger.stdout)
	rootRegistry.use(NewsControllerImplementation.self)
	// You can use either of implementations but not both.
	//	rootRegistry.use(NewsController.liveImplementation)
	rootRegistry.use(NewsDetails.liveImplementation)
}

// When everyting is set up you can use the container
// to access all registered features.
let logger: Logger = features.instance()

logger.logMessage("Access Static Feature")

let news: NewsController = try features.instance()

Task {
	try await news.fetchNews()
	logger.logMessage("Access the news: \(news.newsList())")
	PlaygroundPage.current.finishExecution()
}
