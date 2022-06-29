import MQ

internal final class FeaturesCache {

	@MainActor private var cache: Dictionary<Key, Entry>

	internal nonisolated init() {
		self.cache = .init()
	}

	deinit {
		// ensure proper unloading of features
		for entry: FeaturesCache.Entry in self.cache.values {
			entry.removal(entry.feature)
		}
	}
}

extension FeaturesCache {

	internal typealias Key = LoadableFeatureInstanceIdentifier

	internal typealias Removal = (AnyFeature) -> Void

	internal struct Entry {

		internal var feature: AnyFeature
		#if DEBUG
			internal var debugContext: SourceCodeContext
		#endif
		internal var removal: Removal

		#if DEBUG
			internal init(
				feature: AnyFeature,
				debugContext: SourceCodeContext,
				removal: @escaping Removal
			) {
				self.feature = feature
				self.debugContext = debugContext
				self.removal = removal
			}
		#else
			internal init(
				feature: AnyFeature,
				removal: @escaping Removal
			) {
				self.feature = feature
				self.removal = removal
			}
		#endif
	}
}

extension FeaturesCache {

	@MainActor internal func getEntry(
		for key: Key
	) -> Entry? {
		self.cache[key]
	}

	@MainActor internal func set(
		entry: Entry,
		for key: Key
	) {
		// properly remove previous entry if any
		if let previousEntry: Entry = self.cache[key] {
			previousEntry.removal(previousEntry.feature)
		}
		else {
			noop()
		}

		self.cache[key] = entry
	}

	#if DEBUG
		@MainActor internal func getDebugContext(
			for key: Key
		) -> SourceCodeContext? {
			self.cache[key]?.debugContext
		}
	#endif

	@MainActor internal func get<Feature>(
		_ featureType: Feature.Type,
		context: Feature.Context
	) throws -> Feature?
	where Feature: LoadableFeature {
		let key: Key = .key(
			for: featureType,
			context: context
		)
		guard let cachedFeature: AnyFeature = self.cache[key]?.feature
		else { return .none }

		if let feature: Feature = cachedFeature as? Feature {
			return feature
		}
		else {
			throw
				InternalInconsistency
				.error(message: "Cached feature instance is not matching expected type, please report a bug.")
				.with(cachedFeature, for: "cachedFeature")
				.with(Feature.self, for: "feature")
				.with(context, for: "context")
				.asAssertionFailure()
		}
	}

	@MainActor internal func removeEntry(
		for key: Key
	) {
		guard let entry: Entry = self.cache[key]
		else { return }

		self.cache[key] = .none
		entry.removal(entry.feature)
	}

	@MainActor internal func clear() {
		for entry: FeaturesCache.Entry in self.cache.values {
			entry.removal(entry.feature)
		}
		self.cache = .init()
	}
}

extension FeaturesCache.Key {

	@MainActor internal static func key<Feature>(
		for featureType: Feature.Type,
		context: Feature.Context
	) -> Self
	where Feature: LoadableFeature {
		.instanceIdentifier(
			featureType: featureType,
			context: context
		)
	}
}
