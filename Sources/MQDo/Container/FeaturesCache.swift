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
			self.typeIdentifier = ObjectIdentifier(featureType) as AnyHashable
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

	internal typealias Removal = (AnyFeature) throws -> Void
}

extension FeaturesCache {

	internal mutating func set(
		entry: Entry,
		for key: Key
	) {
		self.cache[key] = entry
	}

	#if DEBUG
		internal func getDebugContext(
			for key: Key
		) -> SourceCodeContext? {
			self.cache[key]?.debugContext
		}
	#endif

	internal func entry(
		for key: Key
	) -> Entry? {
		self.cache[key]
	}

	private func getFeature(
		for key: Key
	) -> AnyFeature? {
		self.cache[key]?.feature
	}

	internal func get<Feature>(
		_ featureType: Feature.Type,
		context: Feature.Context
	) -> Feature?
	where Feature: LoadableFeature {
		guard
			let cachedFeature: AnyFeature = self.getFeature(
				for: .identifier(
					of: featureType,
					context: context
				)
			)
		else { return .none }

		if let feature: Feature = cachedFeature as? Feature {
			return feature
		}
		else {
			InternalInconsistency
				.error(message: "Cached feature instance is not matching expected type")
				.with(cachedFeature, for: "cachedFeature")
				.with(Feature.self, for: "feature")
				.with(context, for: "context")
				.asFatalError()
		}
	}

	internal mutating func removeEntry(
		for key: Key,
		force: Bool = false  // remove entry on failure if true
	) throws {
		guard let entry: Entry = self.cache[key]
		else { return }
		if force {
			self.cache[key] = .none  // remove always
			try entry.removal(entry.feature)
		}
		else {
			try entry.removal(entry.feature)
			self.cache[key] = .none  // remove only if not failed
		}
	}

	internal mutating func clear() throws {
		for key: FeaturesCache.Key in self.cache.keys {
			try self.removeEntry(for: key)
		}
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
