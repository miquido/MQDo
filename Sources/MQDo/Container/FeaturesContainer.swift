import MQ

@MainActor public func rootFeaturesContainer(
  registry: ScopedFeaturesRegistry<RootFeaturesScope>.SetupFunction,
  file: StaticString = #fileID,
  line: UInt = #line
) -> some FeaturesContainer {
  var featuresRegistry: ScopedFeaturesRegistry<RootFeaturesScope> = .init()
  registry(&featuresRegistry)

  return Features(
    scopes: [RootFeaturesScope.identifier],
    registry: featuresRegistry.registry,
    parent: .none,
    root: .none,
    file: file,
    line: line
  )
}

@MainActor public protocol FeaturesContainer {

	#if DEBUG
		var debugContext: SourceCodeContext { get }
	#endif

	@MainActor func containsScope<Scope>(
		_ scope: Scope.Type
	) -> Bool
  where Scope: FeaturesScope

	@MainActor func branch<Scope>(
		_ scope: Scope.Type,
		registrySetup: ScopedFeaturesRegistry<Scope>.SetupFunction,
		file: StaticString,
		line: UInt
	) -> FeaturesContainer
  where Scope: FeaturesScope

	@MainActor func instance<Feature>(
		of featureType: Feature.Type,
		file: StaticString,
		line: UInt
	) throws -> Feature
	where Feature: LoadableFeature

	@MainActor func instance<Feature>(
		of featureType: Feature.Type,
		context: Feature.Context,
		file: StaticString,
		line: UInt
	) throws -> Feature
	where Feature: LoadableContextualFeature
}

extension FeaturesContainer {

	@MainActor public func branch<Scope>(
		_ scope: Scope.Type,
		registrySetup: ScopedFeaturesRegistry<Scope>.SetupFunction = noop,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> FeaturesContainer
  where Scope: FeaturesScope {
		self.branch(
			scope,
			registrySetup: registrySetup,
			file: file,
			line: line
		)
	}

	@MainActor public func instance<Feature>(
		of featureType: Feature.Type = Feature.self,
		file: StaticString = #fileID,
		line: UInt = #line
	) throws -> Feature
	where Feature: LoadableFeature {
		try self.instance(
			of: featureType,
			file: file,
			line: line
		)
	}

	@MainActor public func instance<Feature>(
		of featureType: Feature.Type = Feature.self,
		context: Feature.Context,
		file: StaticString = #fileID,
		line: UInt = #line
	) throws -> Feature
	where Feature: LoadableContextualFeature {
		try self.instance(
			of: featureType,
			context: context,
			file: file,
			line: line
		)
	}

	@MainActor public func loadIfNeeded<Feature>(
		_ featureType: Feature.Type = Feature.self,
		file: StaticString = #fileID,
		line: UInt = #line
	) throws
	where Feature: LoadableFeature {
    // initial, naive implementation
		_ = try self.instance(
			of: featureType,
			file: file,
			line: line
		)
	}

	@MainActor public func loadIfNeeded<Feature>(
		_ featureType: Feature.Type = Feature.self,
		context: Feature.Context,
		file: StaticString = #fileID,
		line: UInt = #line
	) throws
	where Feature: LoadableContextualFeature {
    // initial, naive implementation
		_ = try self.instance(
			of: featureType,
			context: context,
			file: file,
			line: line
		)
	}
}
