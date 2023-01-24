import MQ

import class Foundation.NSRecursiveLock

internal final class FeaturesTree {

	private let treeLock: NSRecursiveLock
	private let featuresRegistry: FeaturesTreeRegistry

	internal init(
		featuresRegistry: FeaturesTreeRegistry
	) {
		self.treeLock = .init()
		self.featuresRegistry = featuresRegistry
	}
}

extension FeaturesTree: Sendable {}

extension FeaturesTree {

	@_transparent
	internal func withLock<Result>(
		_ execute: () throws -> Result
	) rethrows -> Result {
		try self.treeLock.withLock(execute)
	}

	@Sendable internal func nodeRegistry<Scope>(
		for scope: Scope.Type,
		file: StaticString,
		line: UInt
	) throws -> FeaturesNodeRegistry<Scope>
	where Scope: FeaturesScope {
		try self.featuresRegistry
			.nodeRegistry(
				for: scope,
				file: file,
				line: line
			)
	}

	@Sendable internal func instance<Feature>(
		of feature: Feature.Type,
		file: StaticString,
		line: UInt
	) -> Feature
	where Feature: StaticFeature {
		self.featuresRegistry
			.instance(
				of: feature,
				file: file,
				line: line
			)
	}
}
