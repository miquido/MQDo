import MQ

internal struct FeaturesCache {

	private var cache: Dictionary<Key, Entry>

	internal init() {
		self.cache = .init()
	}
}

extension FeaturesCache {

	internal struct Key {

		internal let featureType: AnyFeature.Type
		private let typeIdentifier: AnyHashable
		private let contextIdentifier: AnyHashable?

		private init(
			featureType: AnyFeature.Type,
			contextIdentifier: AnyHashable?
		) {
			self.featureType = featureType
			self.typeIdentifier = featureType.identifier
			self.contextIdentifier = contextIdentifier
		}
	}

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

	internal typealias Removal = (AnyFeature) -> Void
}

extension FeaturesCache {

	@MainActor internal mutating func set(
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
		_ featureType: Feature.Type
	) throws -> Feature?
	where Feature: LoadableFeature {
		let key: Key = .identifier(
			of: featureType,
			context: void
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
				.asAssertionFailure()
		}
	}

	@MainActor internal func get<Feature>(
		_ featureType: Feature.Type,
		context: Feature.Context
	) throws -> Feature?
	where Feature: LoadableContextualFeature {
		let key: Key = .identifier(
			of: featureType,
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

	@MainActor internal mutating func removeEntry(
		for key: Key
	) {
		guard let entry: Entry = self.cache[key]
		else { return }
		entry.removal(entry.feature)
		self.cache[key] = .none
	}

	// used only on deinit
	nonisolated internal mutating func clear() {
		for entry: FeaturesCache.Entry in self.cache.values {
			entry.removal(entry.feature)
		}
		self.cache = .init()
	}
}

extension FeaturesCache.Key: Hashable {

	internal static func == (
		_ lhs: FeaturesCache.Key,
		_ rhs: FeaturesCache.Key
	) -> Bool {
		lhs.typeIdentifier == rhs.typeIdentifier
			&& lhs.contextIdentifier == rhs.contextIdentifier
	}

	internal func hash(
		into hasher: inout Hasher
	) {
		hasher.combine(self.typeIdentifier)
		hasher.combine(self.contextIdentifier)
	}
}

extension FeaturesCache.Key {

	internal static func identifier(
		of featureType: AnyFeature.Type,
		context: Any
	) -> Self {
		Self(
			featureType: featureType,
			contextIdentifier: (context as? IdentifiableFeatureContext)?.identifier
		)
	}
}
