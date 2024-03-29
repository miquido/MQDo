import MQDo

import class Foundation.NSRecursiveLock

public final class DummyFeatures {

	private let lock: NSRecursiveLock
	private var items: Dictionary<ItemIdentifier, Any>

	public init(
		with patches: (FeaturePatches) -> Void = { _ in /* noop */ }
	) {
		self.lock = .init()
		self.items = .init()
		patches(FeaturePatches(using: self))
	}
}

extension DummyFeatures: @unchecked Sendable {}

extension DummyFeatures: FeaturesContainer {

	@Sendable public func context<Scope>(
		for scope: Scope.Type,
		file: StaticString,
		line: UInt
	) throws -> Scope.Context
	where Scope: FeaturesScope {
		if let context: Scope.Context = self.items[scope.valueIdentifier()] as? Scope.Context {
			return context
		}
		else {
			throw
				FeaturesScopeContextUnavailable
				.error(
					scope: scope,
					file: file,
					line: line
				)
		}
	}

	@Sendable public func branch<Scope>(
		_ scope: Scope.Type,
		context: Scope.Context,
		file: StaticString,
		line: UInt
	) -> FeaturesContainer
	where Scope: FeaturesScope {
		self.lock.withLock {
			self.items[Scope.valueIdentifier()] = context
		}
		return self
	}

	@Sendable public func instance<Feature>(
		of feature: Feature.Type,
		file: StaticString,
		line: UInt
	) -> Feature
	where Feature: StaticFeature {
		self.lock.withLock {
			if let feature: Feature = self.items[feature.itemIdentifier()] as? Feature {
				return feature
			}
			else {
				return .placeholder
			}
		}
	}

	@Sendable public func instance<Feature>(
		of feature: Feature.Type,
		context: Feature.Context,
		file: StaticString,
		line: UInt
	) throws -> Feature
	where Feature: DisposableFeature {
		self.lock.withLock {
			if let feature: Feature = self.items[feature.itemIdentifier()] as? Feature {
				return feature
			}
			else {
				return .placeholder
			}
		}
	}

	@Sendable public func instance<Feature>(
		of feature: Feature.Type,
		context: Feature.Context,
		file: StaticString,
		line: UInt
	) throws -> Feature
	where Feature: CacheableFeature {
		self.lock.withLock {
			if let feature: Feature = self.items[feature.itemIdentifier(context: context)] as? Feature {
				return feature
			}
			else {
				return .placeholder
			}
		}
	}
}

extension DummyFeatures {

	@Sendable public func use<Scope>(
		context: Scope.Context,
		for scope: Scope.Type,
		file: StaticString = #filePath,
		line: UInt = #line
	) where Scope: FeaturesScope {
		self.lock.withLock {
			self.items[scope.valueIdentifier()] = context
		}
	}

	@Sendable public func use<Feature>(
		_ feature: Feature,
		file: StaticString = #filePath,
		line: UInt = #line
	) where Feature: StaticFeature {
		self.lock.withLock {
			self.items[Feature.itemIdentifier()] = feature
		}
	}

	@Sendable public func patch<Feature, Property>(
		_ keyPath: WritableKeyPath<Feature, Property>,
		with property: Property,
		file: StaticString = #filePath,
		line: UInt = #line
	) where Feature: StaticFeature {
		self.lock.withLock {
			var instance: Feature = self.items[Feature.itemIdentifier()] as? Feature ?? .placeholder
			instance[keyPath: keyPath] = property
			self.items[Feature.itemIdentifier()] = instance
		}
	}

	@Sendable public func patch<Feature>(
		_ feature: Feature.Type,
		with update: (inout Feature) -> Void,
		file: StaticString = #filePath,
		line: UInt = #line
	) where Feature: StaticFeature {
		self.lock.withLock {
			var instance: Feature = self.items[Feature.itemIdentifier()] as? Feature ?? .placeholder
			update(&instance)
			self.items[Feature.itemIdentifier()] = instance
		}
	}

	@Sendable public func use<Feature>(
		_ feature: Feature,
		file: StaticString = #filePath,
		line: UInt = #line
	) where Feature: DisposableFeature {
		self.lock.withLock {
			self.items[Feature.itemIdentifier()] = feature
		}
	}

	@Sendable public func patch<Feature, Property>(
		_ keyPath: WritableKeyPath<Feature, Property>,
		with property: Property,
		file: StaticString = #filePath,
		line: UInt = #line
	) where Feature: DisposableFeature {
		self.lock.withLock {
			var instance: Feature = self.items[Feature.itemIdentifier()] as? Feature ?? .placeholder
			instance[keyPath: keyPath] = property
			self.items[Feature.itemIdentifier()] = instance
		}
	}

	@Sendable public func patch<Feature>(
		_ feature: Feature.Type,
		with update: (inout Feature) -> Void,
		file: StaticString = #filePath,
		line: UInt = #line
	) where Feature: DisposableFeature {
		self.lock.withLock {
			var instance: Feature = self.items[Feature.itemIdentifier()] as? Feature ?? .placeholder
			update(&instance)
			self.items[Feature.itemIdentifier()] = instance
		}
	}

	@Sendable public func use<Feature>(
		_ feature: Feature,
		context: Feature.Context,
		file: StaticString = #filePath,
		line: UInt = #line
	) where Feature: CacheableFeature {
		self.lock.withLock {
			self.items[Feature.itemIdentifier(context: context)] = feature
		}
	}

	@Sendable public func patch<Feature, Property>(
		_ keyPath: WritableKeyPath<Feature, Property>,
		context: Feature.Context,
		with property: Property,
		file: StaticString = #filePath,
		line: UInt = #line
	) where Feature: CacheableFeature {
		self.lock.withLock {
			var instance: Feature = self.items[Feature.itemIdentifier(context: context)] as? Feature ?? .placeholder
			instance[keyPath: keyPath] = property
			self.items[Feature.itemIdentifier(context: context)] = instance
		}
	}

	@Sendable public func patch<Feature>(
		_ feature: Feature.Type,
		context: Feature.Context,
		with update: (inout Feature) -> Void,
		file: StaticString = #filePath,
		line: UInt = #line
	) where Feature: CacheableFeature {
		self.lock.withLock {
			var instance: Feature = self.items[Feature.itemIdentifier(context: context)] as? Feature ?? .placeholder
			update(&instance)
			self.items[Feature.itemIdentifier(context: context)] = instance
		}
	}

	@Sendable public func use<Feature>(
		_ feature: Feature,
		file: StaticString = #filePath,
		line: UInt = #line
	) where Feature: CacheableFeature, Feature.Context == CacheableFeatureVoidContext {
		self.lock.withLock {
			self.items[Feature.itemIdentifier(context: .void)] = feature
		}
	}

	@Sendable public func patch<Feature, Property>(
		_ keyPath: WritableKeyPath<Feature, Property>,
		with property: Property,
		file: StaticString = #filePath,
		line: UInt = #line
	) where Feature: CacheableFeature, Feature.Context == CacheableFeatureVoidContext {
		self.lock.withLock {
			var instance: Feature = self.items[Feature.itemIdentifier(context: .void)] as? Feature ?? .placeholder
			instance[keyPath: keyPath] = property
			self.items[Feature.itemIdentifier(context: .void)] = instance
		}
	}

	@Sendable public func patch<Feature>(
		_ feature: Feature.Type,
		with update: (inout Feature) -> Void,
		file: StaticString = #filePath,
		line: UInt = #line
	) where Feature: CacheableFeature, Feature.Context == CacheableFeatureVoidContext {
		self.lock.withLock {
			var instance: Feature = self.items[Feature.itemIdentifier(context: .void)] as? Feature ?? .placeholder
			update(&instance)
			self.items[Feature.itemIdentifier(context: .void)] = instance
		}
	}
}

extension DummyFeatures {

	fileprivate struct ItemIdentifier: Hashable, @unchecked Sendable {

		private let item: AnyHashable
		private let context: AnyHashable?

		fileprivate init<Scope>(
			_: Scope.Type
		) where Scope: FeaturesScope {
			self.item = ObjectIdentifier(Scope.self)
			self.context = .none
		}

		fileprivate init<Feature>(
			_: Feature.Type
		) where Feature: StaticFeature {
			self.item = ObjectIdentifier(Feature.self)
			self.context = .none
		}

		fileprivate init<Feature>(
			_: Feature.Type
		) where Feature: DisposableFeature {
			self.item = ObjectIdentifier(Feature.self)
			self.context = .none
		}

		fileprivate init<Feature>(
			_: Feature.Type,
			context: Feature.Context?
		) where Feature: CacheableFeature {
			self.item = ObjectIdentifier(Feature.self)
			self.context = context
		}
	}
}

extension FeaturesScope {

	fileprivate static func valueIdentifier() -> DummyFeatures.ItemIdentifier {
		.init(Self.self)
	}
}

extension StaticFeature {

	fileprivate static func itemIdentifier() -> DummyFeatures.ItemIdentifier {
		.init(Self.self)
	}
}

extension DisposableFeature {

	fileprivate static func itemIdentifier() -> DummyFeatures.ItemIdentifier {
		.init(Self.self)
	}
}

extension CacheableFeature {

	fileprivate static func itemIdentifier(
		context: Self.Context
	) -> DummyFeatures.ItemIdentifier {
		.init(
			Self.self,
			context: context
		)
	}
}

#if DEBUG
extension DummyFeatures {

	@Sendable public func which<Feature>(
		_: Feature.Type
	) -> String
	where Feature: DisposableFeature {
		"N/A"
	}

	@Sendable public func which<Feature>(
		_: Feature.Type
	) -> String
	where Feature: CacheableFeature {
		"N/A"
	}
}
#endif
