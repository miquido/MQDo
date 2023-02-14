import MQ

internal final class FeaturesNode<Scope>
where Scope: FeaturesScope {

	private let featuresTree: FeaturesTree
	private let parent: FeaturesContainer
	private let context: Scope.Context
	private let featuresRegistry: FeaturesNodeRegistry<Scope>
	// ensure that cache is always accessed using tree lock
	private var featuresCache: FeaturesCache

	internal init(
		featuresTree: FeaturesTree,
		parent: FeaturesContainer,
		context: Scope.Context,
		featuresRegistry: FeaturesNodeRegistry<Scope>
	) {
		self.featuresTree = featuresTree
		self.parent = parent
		self.context = context
		self.featuresRegistry = featuresRegistry
		self.featuresCache = .init()
	}
}

extension FeaturesNode: @unchecked Sendable {}

extension FeaturesNode: FeaturesContainer {

	@Sendable internal func require<RequestedScope>(
		_ scope: RequestedScope.Type,
		file: StaticString,
		line: UInt
	) throws
	where RequestedScope: FeaturesScope {
		if RequestedScope.self == Scope.self {
			return  // noop
		}
		else {
			return try self.parent
				.require(
					scope,
					file: file,
					line: line
				)
		}
	}

	@Sendable internal func context<RequestedScope>(
		for scope: RequestedScope.Type,
		file: StaticString,
		line: UInt
	) throws -> RequestedScope.Context
	where RequestedScope: FeaturesScope {
		if RequestedScope.self == Scope.self,
			let context: RequestedScope.Context = self.context as? RequestedScope.Context
		{
			return context
		}
		else {
			return try self.parent
				.context(
					for: scope,
					file: file,
					line: line
				)
		}
	}

	@Sendable internal func branch<Scope>(
		_ scope: Scope.Type,
		context: Scope.Context,
		file: StaticString,
		line: UInt
	) throws -> FeaturesContainer
	where Scope: FeaturesScope {
		try FeaturesNode<Scope>(
			featuresTree: self.featuresTree,
			parent: self,
			context: context,
			featuresRegistry: self.featuresTree
				.nodeRegistry(
					for: scope,
					file: file,
					line: line
				)
		)
	}

	@Sendable internal func instance<Feature>(
		of feature: Feature.Type,
		file: StaticString,
		line: UInt
	) -> Feature
	where Feature: StaticFeature {
		self.featuresTree
			.instance(
				of: feature,
				file: file,
				line: line
			)
	}

	@Sendable internal func instance<Feature>(
		of feature: Feature.Type,
		context: Feature.Context,
		file: StaticString,
		line: UInt
	) throws -> Feature
	where Feature: DisposableFeature {
		do {
			return try self.featuresRegistry
				.loadInstance(
					of: feature,
					context: context,
					using: FeaturesProxyNode(
						self,
						featuresTree: self.featuresTree
					),
					file: file,
					line: line
				)
		}
		catch is FeatureUndefined {
			return try self.parent
				.instance(
					of: feature,
					context: context,
					file: file,
					line: line
				)
		}
		catch {
			throw error
		}
	}

	@Sendable internal func instance<Feature>(
		of feature: Feature.Type,
		context: Feature.Context,
		file: StaticString,
		line: UInt
	) throws -> Feature
	where Feature: CacheableFeature {
		try self.featuresTree.withLock {
			if let cachedInstance: Feature = self.featuresCache[feature, context] {
				return cachedInstance
			}
			else {
				do {
					let loadedInstance: Feature = try self.featuresRegistry
						.loadInstance(
							of: feature,
							context: context,
							using: FeaturesProxyNode(
								self,
								featuresTree: self.featuresTree
							),
							file: file,
							line: line
						)
					self.featuresCache[feature, context] = loadedInstance
					return loadedInstance
				}
				catch is FeatureUndefined {
					return try self.parent
						.instance(
							of: feature,
							context: context,
							file: file,
							line: line
						)
				}
				catch {
					throw error
				}
			}
		}
	}
}
