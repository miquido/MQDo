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

	@_transparent
	@Sendable internal func registry<Scope>(
		for scope: Scope.Type,
		file: StaticString,
		line: UInt
	) throws -> FeaturesScopeRegistry<Scope>
	where Scope: FeaturesScope {
		try self.featuresRegistry
			.registry(
				for: scope,
				file: file,
				line: line
			)
	}

	@_transparent
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
