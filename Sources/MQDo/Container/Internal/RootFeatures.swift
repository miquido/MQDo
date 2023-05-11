import MQ

internal final class RootFeatures {

	private let featuresTree: FeaturesTree
	private let featuresRegistry: FeaturesScopeRegistry<RootFeaturesScope>
	// ensure that cache is always accessed using tree lock
	private var featuresCache: FeaturesCache

	internal init(
		featuresTree: FeaturesTree,
		featuresRegistry: FeaturesScopeRegistry<RootFeaturesScope>
	) {
		self.featuresTree = featuresTree
		self.featuresRegistry = featuresRegistry
		self.featuresCache = .init()
	}
}

extension RootFeatures: @unchecked Sendable {}

extension RootFeatures: FeaturesContainer {

	@_transparent
	@Sendable internal func require<Scope>(
		_ scope: Scope.Type,
		file: StaticString = #file,
		line: UInt = #line
	) throws
	where Scope: FeaturesScope {
		if scope == RootFeaturesScope.self {
			return  // noop
		}
		else {
			throw
				FeaturesScopeUnavailable
				.error(
					scope: scope,
					file: file,
					line: line
				)
				.asRuntimeWarning(
					message: "Unavailable scope was required.",
					file: file,
					line: line
				)
		}
	}

	@_transparent
	@Sendable internal func context<Scope>(
		for scope: Scope.Type,
		file: StaticString,
		line: UInt
	) throws -> Scope.Context
	where Scope: FeaturesScope {
		// Root can't have context.
		throw
			FeaturesScopeContextUnavailable
			.error(
				scope: scope,
				file: file,
				line: line
			)
			.asRuntimeWarning(
				message: "Trying to access unreachable scope context.",
				file: file,
				line: line
			)
	}

	@_transparent
	@Sendable internal func branch<Scope>(
		_ scope: Scope.Type,
		context: Scope.Context,
		file: StaticString,
		line: UInt
	) throws -> FeaturesContainer
	where Scope: FeaturesScope {
		try ScopedFeatures<Scope>(
			featuresTree: self.featuresTree,
			parent: self,
			context: context,
			featuresRegistry: self.featuresTree
				.registry(
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
					using: FeaturesProxy(
						self,
						featuresTree: self.featuresTree
					),
					file: file,
					line: line
				)
		}
		catch let error as FeatureUndefined {
			throw
				error
				.asRuntimeWarning(
					message:
						"Undefined feature is likely a bug. If a feature should be unavailable please make it explicit by registering loader on root, which throws an aproppriate error.",
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
							using: FeaturesProxy(
								self,
								featuresTree: self.featuresTree
							),
							file: file,
							line: line
						)
					self.featuresCache[feature, context] = loadedInstance
					return loadedInstance
				}
				catch let error as FeatureUndefined {
					throw
						error
						.asRuntimeWarning(
							message:
								"Undefined feature is likely a bug. If a feature should be unavailable please make it explicit by registering loader on root, which throws an aproppriate error.",
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

	#if DEBUG
	@Sendable internal func which<Feature>(
		_: Feature.Type
	) -> String
	where Feature: DisposableFeature {
		if let loader: FeatureLoader = self.featuresRegistry.dynamicFeatureLoaders[Feature.identifier()] {
			return "---\nScope: \(RootFeaturesScope.self)\n\(loader.debugDescription)"
		}
		else {
			return "---\nFeature \(Feature.self) is not defined!"
		}
	}

	@Sendable internal func which<Feature>(
		_: Feature.Type
	) -> String
	where Feature: CacheableFeature {
		if let loader: FeatureLoader = self.featuresRegistry.dynamicFeatureLoaders[Feature.identifier()] {
			return "---\nScope: \(RootFeaturesScope.self)\n\(loader.debugDescription)"
		}
		else {
			return "---\nFeature \(Feature.self) is not defined!"
		}
	}
	#endif
}
