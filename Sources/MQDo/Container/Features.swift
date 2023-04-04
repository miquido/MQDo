public protocol Features: Sendable {

	@Sendable func branch<Scope>(
		_ scope: Scope.Type,
		context: Scope.Context,
		file: StaticString,
		line: UInt
	) throws -> FeaturesContainer
	where Scope: FeaturesScope

	@Sendable func require<Scope>(
		_ scope: Scope.Type,
		file: StaticString,
		line: UInt
	) throws
	where Scope: FeaturesScope

	@Sendable func context<Scope>(
		for scope: Scope.Type,
		file: StaticString,
		line: UInt
	) throws -> Scope.Context
	where Scope: FeaturesScope

	@Sendable func instance<Feature>(
		of featureType: Feature.Type,
		file: StaticString,
		line: UInt
	) -> Feature
	where Feature: StaticFeature

	@Sendable func instance<Feature>(
		of featureType: Feature.Type,
		context: Feature.Context,
		file: StaticString,
		line: UInt
	) throws -> Feature
	where Feature: DisposableFeature

	@Sendable func instance<Feature>(
		of featureType: Feature.Type,
		context: Feature.Context,
		file: StaticString,
		line: UInt
	) async throws -> Feature
	where Feature: AsyncDisposableFeature

	@Sendable func instance<Feature>(
		of featureType: Feature.Type,
		context: Feature.Context,
		file: StaticString,
		line: UInt
	) throws -> Feature
	where Feature: CacheableFeature

	#if DEBUG
		@Sendable func which<Feature>(
			_: Feature.Type
		) -> String
		where Feature: DisposableFeature

		@Sendable func which<Feature>(
			_: Feature.Type
		) -> String
		where Feature: CacheableFeature
	#endif
}

extension Features {

	@_transparent
	@Sendable public func require<Scope>(
		_ scope: Scope.Type,
		file: StaticString = #file,
		line: UInt = #line
	) throws
	where Scope: FeaturesScope {
		try self.require(
			Scope.self,
			file: file,
			line: line
		)
	}

	@_transparent
	@Sendable public func context<Scope>(
		for scope: Scope.Type,
		file: StaticString = #fileID,
		line: UInt = #line
	) throws -> Scope.Context
	where Scope: FeaturesScope {
		try self.context(
			for: scope,
			file: file,
			line: line
		)
	}
}

extension Features {

	@_transparent
	@_disfavoredOverload @Sendable public func branch<Scope>(
		_ scope: Scope.Type,
		file: StaticString = #fileID,
		line: UInt = #line
	) throws -> Features
	where Scope: FeaturesScope, Scope.Context == Void {
		try self.branch(
			scope,
			context: Void(),
			file: file,
			line: line
		)
	}

	@_transparent
	@_disfavoredOverload @Sendable public func branch<Scope>(
		_ scope: Scope.Type,
		context: Scope.Context,
		file: StaticString = #fileID,
		line: UInt = #line
	) throws -> Features
	where Scope: FeaturesScope {
		try self.branch(
			scope,
			context: context,
			file: file,
			line: line
		)
	}
}

extension Features {

	@_transparent
	@Sendable public func instance<Feature>(
		of featureType: Feature.Type = Feature.self,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Feature
	where Feature: StaticFeature {
		self.instance(
			of: featureType,
			file: file,
			line: line
		)
	}

	@_transparent
	@Sendable public func instance<Feature>(
		of featureType: Feature.Type = Feature.self,
		context: Feature.Context,
		file: StaticString = #fileID,
		line: UInt = #line
	) throws -> Feature
	where Feature: DisposableFeature {
		try self.instance(
			of: featureType,
			context: context,
			file: file,
			line: line
		)
	}

	@_transparent
	@Sendable public func instance<Feature>(
		of featureType: Feature.Type = Feature.self,
		file: StaticString = #fileID,
		line: UInt = #line
	) throws -> Feature
	where Feature: DisposableFeature, Feature.Context == Void {
		try self.instance(
			of: featureType,
			context: Void(),
			file: file,
			line: line
		)
	}

	@_transparent
	@Sendable public func instance<Feature>(
		of featureType: Feature.Type = Feature.self,
		context: Feature.Context,
		file: StaticString = #fileID,
		line: UInt = #line
	) async throws -> Feature
	where Feature: AsyncDisposableFeature {
		try await self.instance(
			of: featureType,
			context: context,
			file: file,
			line: line
		)
	}

	@_transparent
	@Sendable public func instance<Feature>(
		of featureType: Feature.Type = Feature.self,
		file: StaticString = #fileID,
		line: UInt = #line
	) async throws -> Feature
	where Feature: AsyncDisposableFeature, Feature.Context == Void {
		try await self.instance(
			of: featureType,
			context: Void(),
			file: file,
			line: line
		)
	}

	@_transparent
	@Sendable public func instance<Feature>(
		of featureType: Feature.Type = Feature.self,
		context: Feature.Context,
		file: StaticString = #fileID,
		line: UInt = #line
	) throws -> Feature
	where Feature: CacheableFeature {
		try self.instance(
			of: featureType,
			context: context,
			file: file,
			line: line
		)
	}

	@_transparent
	@Sendable public func instance<Feature>(
		of featureType: Feature.Type = Feature.self,
		file: StaticString = #fileID,
		line: UInt = #line
	) throws -> Feature
	where Feature: CacheableFeature, Feature.Context == CacheableFeatureVoidContext {
		try self.instance(
			of: featureType,
			context: .void,
			file: file,
			line: line
		)
	}
}

extension Features {

	@Sendable public func deferredInstance<Feature>(
		of featureType: Feature.Type = Feature.self,
		context: Feature.Context,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> DeferredInstance<Feature>
	where Feature: DisposableFeature {
		let proxy: FeaturesProxy = .proxy(from: self)
		return DeferredInstance {
			try proxy.instance(
				of: featureType,
				context: context,
				file: file,
				line: line
			)
		}
	}

	@Sendable public func deferredInstance<Feature>(
		of featureType: Feature.Type = Feature.self,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> DeferredInstance<Feature>
	where Feature: DisposableFeature, Feature.Context == Void {
		let proxy: FeaturesProxy = .proxy(from: self)
		return DeferredInstance {
			try proxy.instance(
				of: featureType,
				context: Void(),
				file: file,
				line: line
			)
		}
	}

	@Sendable public func deferredInstance<Feature>(
		of featureType: Feature.Type = Feature.self,
		context: Feature.Context,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> AsyncDeferredInstance<Feature>
	where Feature: AsyncDisposableFeature {
		let proxy: FeaturesProxy = .proxy(from: self)
		return AsyncDeferredInstance {
			try await proxy.instance(
				of: featureType,
				context: context,
				file: file,
				line: line
			)
		}
	}

	@Sendable public func deferredInstance<Feature>(
		of featureType: Feature.Type = Feature.self,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> AsyncDeferredInstance<Feature>
	where Feature: AsyncDisposableFeature, Feature.Context == Void {
		let proxy: FeaturesProxy = .proxy(from: self)
		return AsyncDeferredInstance {
			try await proxy.instance(
				of: featureType,
				context: Void(),
				file: file,
				line: line
			)
		}
	}

	@Sendable public func deferredInstance<Feature>(
		of featureType: Feature.Type = Feature.self,
		context: Feature.Context,
		file: StaticString = #fileID,
		line: UInt = #line
	) throws -> DeferredInstance<Feature>
	where Feature: CacheableFeature {
		DeferredInstance {
			try self.instance(
				of: featureType,
				context: context,
				file: file,
				line: line
			)
		}
	}

	@Sendable public func deferredInstance<Feature>(
		of featureType: Feature.Type = Feature.self,
		file: StaticString = #fileID,
		line: UInt = #line
	) throws -> DeferredInstance<Feature>
	where Feature: CacheableFeature, Feature.Context == CacheableFeatureVoidContext {
		DeferredInstance {
			try self.instance(
				of: featureType,
				context: .void,
				file: file,
				line: line
			)
		}
	}
}
