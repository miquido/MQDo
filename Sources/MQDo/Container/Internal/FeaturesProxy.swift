internal struct FeaturesProxy {

	private weak var container: FeaturesContainer?
	private unowned let featuresTree: FeaturesTree

	internal init(
		_ container: FeaturesContainer? = .none,
		featuresTree: FeaturesTree
	) {
		self.container = container
		self.featuresTree = featuresTree
	}
}

extension FeaturesProxy: Features {

	@_transparent
	@Sendable internal func require<Scope>(
		_ scope: Scope.Type,
		file: StaticString = #file,
		line: UInt = #line
	) throws
	where Scope: FeaturesScope {
		if let container: FeaturesContainer = self.container {
			return
				try container
				.require(
					scope,
					file: file,
					line: line
				)
		}
		else {
			throw
				FeaturesContainerUnavailable
				.error(
					file: file,
					line: line
				)
				.asRuntimeWarning(
					message: "Using detached features container. This is likely a memory issue.",
					file: file,
					line: line
				)
		}
	}

	@_transparent
	@Sendable internal func context<RequestedScope>(
		for scope: RequestedScope.Type,
		file: StaticString,
		line: UInt
	) throws -> RequestedScope.Context
	where RequestedScope: FeaturesScope {
		if let container: FeaturesContainer = self.container {
			return
				try container
				.context(
					for: scope,
					file: file,
					line: line
				)
		}
		else {
			throw
				FeaturesContainerUnavailable
				.error(
					file: file,
					line: line
				)
				.asRuntimeWarning(
					message: "Using detached features container. This is likely a memory issue.",
					file: file,
					line: line
				)
		}
	}

	@_transparent
	@Sendable internal func branch<Scope>(
		_ scope: Scope.Type,
		context: Scope.Context,
		file: StaticString,
		line: UInt
	) throws -> FeaturesContainer
	where Scope: FeaturesScope {
		if let container: FeaturesContainer = self.container {
			return
				try container
				.branch(
					scope,
					context: context,
					file: file,
					line: line
				)
		}
		else {
			throw
				FeaturesContainerUnavailable
				.error(
					file: file,
					line: line
				)
				.asRuntimeWarning(
					message: "Using detached features container. This is likely a memory issue.",
					file: file,
					line: line
				)
		}
	}

	@_transparent
	@Sendable internal func instance<Feature>(
		of feature: Feature.Type,
		file: StaticString,
		line: UInt
	) -> Feature
	where Feature: StaticFeature {
		if let container: FeaturesContainer = self.container {
			return
				container
				.instance(
					of: feature,
					file: file,
					line: line
				)
		}
		else {
			FeaturesContainerUnavailable
				.error(
					file: file,
					line: line
				)
				.asRuntimeWarning(
					message: "Using detached features container. This is an issue.",
					file: file,
					line: line
				)
			return self.featuresTree
				.instance(
					of: feature,
					file: file,
					line: line
				)
		}
	}

	@_transparent
	@Sendable internal func instance<Feature>(
		of feature: Feature.Type,
		context: Feature.Context,
		file: StaticString,
		line: UInt
	) throws -> Feature
	where Feature: DisposableFeature {
		if let container: FeaturesContainer = self.container {
			return
				try container
				.instance(
					of: feature,
					context: context,
					file: file,
					line: line
				)
		}
		else {
			throw
				FeatureLoadingFailed
				.error(
					feature: feature,
					cause:
						FeaturesContainerUnavailable
						.error(
							file: file,
							line: line
						),
					file: file,
					line: line
				)
				.asRuntimeWarning(
					message: "Using detached features container. This is an issue.",
					file: file,
					line: line
				)
		}
	}

	@_transparent
	@Sendable internal func instance<Feature>(
		of feature: Feature.Type,
		context: Feature.Context,
		file: StaticString,
		line: UInt
	) throws -> Feature
	where Feature: CacheableFeature {
		if let container: FeaturesContainer = self.container {
			return
				try container
				.instance(
					of: feature,
					context: context,
					file: file,
					line: line
				)
		}
		else {
			throw
				FeatureLoadingFailed
				.error(
					feature: feature,
					cause:
						FeaturesContainerUnavailable
						.error(
							file: file,
							line: line
						),
					file: file,
					line: line
				)
				.asRuntimeWarning(
					message: "Using detached features container. This is an issue.",
					file: file,
					line: line
				)
		}
	}

	#if DEBUG
		@Sendable internal func which<Feature>(
			_: Feature.Type
		) -> String
		where Feature: DisposableFeature {
			if let container: FeaturesContainer = self.container {
				return container.which(Feature.self)
			}
			else {
				return "N/A"
			}
		}

		@Sendable internal func which<Feature>(
			_: Feature.Type
		) -> String
		where Feature: CacheableFeature {
			if let container: FeaturesContainer = self.container {
				return container.which(Feature.self)
			}
			else {
				return "N/A"
			}
		}
	#endif
}
