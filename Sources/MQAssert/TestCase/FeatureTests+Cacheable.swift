import MQDummy
import XCTest

// MARK: - Cacheable

extension FeatureTests {

	public final func test<Feature>(
		_ implementation: FeatureLoader,
		context: Feature.Context,
		when patches: @escaping (FeaturePatches) -> Void = {
			(_: FeaturePatches) -> Void in /* noop */
		},
		executing: @escaping (Feature) async throws -> Void,
		file: StaticString = #fileID,
		line: UInt = #line
	) async where Feature: CacheableFeature {
		await self.test(
			patches: patches,
			execute: { (testFeatures: DummyFeatures) throws -> Void in
				try await executing(
					implementation
						.loadInstance(
							of: Feature.self,
							context: context,
							using: testFeatures,
							file: file,
							line: line
						)
				)
			},
			file: file,
			line: line
		)
	}

	public final func test<Feature>(
		_ implementation: FeatureLoader,
		when patches: @escaping (FeaturePatches) -> Void = {
			(_: FeaturePatches) -> Void in /* noop */
		},
		executing: @escaping (Feature) async throws -> Void,
		file: StaticString = #fileID,
		line: UInt = #line
	) async where Feature: CacheableFeature, Feature.Context == CacheableFeatureVoidContext {
		await self.test(
			patches: patches,
			execute: { (testFeatures: DummyFeatures) throws -> Void in
				try await executing(
					implementation
						.loadInstance(
							of: Feature.self,
							context: .void,
							using: testFeatures,
							file: file,
							line: line
						)
				)
			},
			file: file,
			line: line
		)
	}

	public final func test<Feature, Returned>(
		_ implementation: FeatureLoader,
		context: Feature.Context,
		returnsEqual expected: Returned,
		when patches: @escaping (FeaturePatches) -> Void = {
			(_: FeaturePatches) -> Void in /* noop */
		},
		executing: @escaping (Feature) async throws -> Returned,
		file: StaticString = #fileID,
		line: UInt = #line
	) async where Feature: CacheableFeature, Returned: Equatable {
		await self.test(
			patches: patches,
			returnsEqual: expected,
			execute: { (testFeatures: DummyFeatures) throws -> Returned in
				try await executing(
					implementation
						.loadInstance(
							of: Feature.self,
							context: context,
							using: testFeatures,
							file: file,
							line: line
						)
				)
			},
			file: file,
			line: line
		)
	}

	public final func test<Feature, Returned>(
		_ implementation: FeatureLoader,
		returnsEqual expected: Returned,
		when patches: @escaping (FeaturePatches) -> Void = {
			(_: FeaturePatches) -> Void in /* noop */
		},
		executing: @escaping (Feature) async throws -> Returned,
		file: StaticString = #fileID,
		line: UInt = #line
	) async where Feature: CacheableFeature, Feature.Context == CacheableFeatureVoidContext, Returned: Equatable {
		await self.test(
			patches: patches,
			returnsEqual: expected,
			execute: { (testFeatures: DummyFeatures) throws -> Returned in
				try await executing(
					implementation
						.loadInstance(
							of: Feature.self,
							context: .void,
							using: testFeatures,
							file: file,
							line: line
						)
				)
			},
			file: file,
			line: line
		)
	}

	public final func test<Feature, Returned, ExpectedError>(
		_ implementation: FeatureLoader,
		context: Feature.Context,
		throws expected: ExpectedError.Type,
		when patches: @escaping (FeaturePatches) -> Void = {
			(_: FeaturePatches) -> Void in /* noop */
		},
		executing: @escaping (Feature) async throws -> Returned,
		file: StaticString = #fileID,
		line: UInt = #line
	) async where Feature: CacheableFeature, ExpectedError: Error {
		await self.test(
			patches: patches,
			throws: expected,
			execute: { (testFeatures: DummyFeatures) throws -> Returned in
				try await executing(
					implementation
						.loadInstance(
							of: Feature.self,
							context: context,
							using: testFeatures,
							file: file,
							line: line
						)
				)
			},
			file: file,
			line: line
		)
	}

	public final func test<Feature, Returned, ExpectedError>(
		_ implementation: FeatureLoader,
		throws expected: ExpectedError.Type,
		when patches: @escaping (FeaturePatches) -> Void = {
			(_: FeaturePatches) -> Void in /* noop */
		},
		executing: @escaping (Feature) async throws -> Returned,
		file: StaticString = #fileID,
		line: UInt = #line
	) async where Feature: CacheableFeature, Feature.Context == CacheableFeatureVoidContext, ExpectedError: Error {
		await self.test(
			patches: patches,
			throws: expected,
			execute: { (testFeatures: DummyFeatures) throws -> Returned in
				try await executing(
					implementation
						.loadInstance(
							of: Feature.self,
							context: .void,
							using: testFeatures,
							file: file,
							line: line
						)
				)
			},
			file: file,
			line: line
		)
	}

	public final func test<Feature, Returned>(
		_ implementation: FeatureLoader,
		context: Feature.Context,
		executedPrepared expectedExecutionCount: UInt,
		when patches: @escaping (FeaturePatches, @escaping @Sendable () -> Void) -> Void,
		executing: @escaping (Feature) async throws -> Returned,
		file: StaticString = #fileID,
		line: UInt = #line
	) async where Feature: CacheableFeature {
		await self.test(
			patches: patches,
			executedPrepared: expectedExecutionCount,
			execute: { (testFeatures: DummyFeatures) throws -> Returned in
				try await executing(
					implementation
						.loadInstance(
							of: Feature.self,
							context: context,
							using: testFeatures,
							file: file,
							line: line
						)
				)
			},
			file: file,
			line: line
		)
	}

	public final func test<Feature, Returned>(
		_ implementation: FeatureLoader,
		executedPrepared expectedExecutionCount: UInt,
		when patches: @escaping (FeaturePatches, @escaping @Sendable () -> Void) -> Void,
		executing: @escaping (Feature) async throws -> Returned,
		file: StaticString = #fileID,
		line: UInt = #line
	) async where Feature: CacheableFeature, Feature.Context == CacheableFeatureVoidContext {
		await self.test(
			patches: patches,
			executedPrepared: expectedExecutionCount,
			execute: { (testFeatures: DummyFeatures) throws -> Returned in
				try await executing(
					implementation
						.loadInstance(
							of: Feature.self,
							context: .void,
							using: testFeatures,
							file: file,
							line: line
						)
				)
			},
			file: file,
			line: line
		)
	}

	public final func test<Feature, Returned, Argument>(
		_ implementation: FeatureLoader,
		context: Feature.Context,
		executedPreparedUsing expectedArgument: Argument,
		when patches: @escaping (FeaturePatches, @escaping @Sendable (Argument) -> Void) -> Void,
		executing: @escaping (Feature) async throws -> Returned,
		file: StaticString = #fileID,
		line: UInt = #line
	) async where Feature: CacheableFeature, Argument: Equatable & Sendable {
		await self.test(
			patches: patches,
			executedPreparedUsing: expectedArgument,
			execute: { (testFeatures: DummyFeatures) throws -> Returned in
				try await executing(
					implementation
						.loadInstance(
							of: Feature.self,
							context: context,
							using: testFeatures,
							file: file,
							line: line
						)
				)
			},
			file: file,
			line: line
		)
	}

	public final func test<Feature, Returned, Argument>(
		_ implementation: FeatureLoader,
		executedPreparedUsing expectedArgument: Argument,
		when patches: @escaping (FeaturePatches, @escaping @Sendable (Argument) -> Void) -> Void,
		executing: @escaping (Feature) async throws -> Returned,
		file: StaticString = #fileID,
		line: UInt = #line
	) async
	where
		Feature: CacheableFeature,
		Feature.Context == CacheableFeatureVoidContext,
		Argument: Equatable & Sendable
	{
		await self.test(
			patches: patches,
			executedPreparedUsing: expectedArgument,
			execute: { (testFeatures: DummyFeatures) throws -> Returned in
				try await executing(
					implementation
						.loadInstance(
							of: Feature.self,
							context: .void,
							using: testFeatures,
							file: file,
							line: line
						)
				)
			},
			file: file,
			line: line
		)
	}
}
