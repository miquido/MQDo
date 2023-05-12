import MQDummy
import XCTest

// MARK: - Disposable

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
	) async where Feature: DisposableFeature {
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
	) async where Feature: DisposableFeature, Feature.Context == Void {
		await self.test(
			patches: patches,
			execute: { (testFeatures: DummyFeatures) throws -> Void in
				try await executing(
					implementation
						.loadInstance(
							of: Feature.self,
							context: Void(),
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
	) async where Feature: DisposableFeature, Returned: Equatable {
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
	) async where Feature: DisposableFeature, Feature.Context == Void, Returned: Equatable {
		await self.test(
			patches: patches,
			returnsEqual: expected,
			execute: { (testFeatures: DummyFeatures) throws -> Returned in
				try await executing(
					implementation
						.loadInstance(
							of: Feature.self,
							context: Void(),
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
	) async where Feature: DisposableFeature, ExpectedError: Error {
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
	) async where Feature: DisposableFeature, Feature.Context == Void, ExpectedError: Error {
		await self.test(
			patches: patches,
			throws: expected,
			execute: { (testFeatures: DummyFeatures) throws -> Returned in
				try await executing(
					implementation
						.loadInstance(
							of: Feature.self,
							context: Void(),
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
	) async where Feature: DisposableFeature {
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
	) async where Feature: DisposableFeature, Feature.Context == Void {
		await self.test(
			patches: patches,
			executedPrepared: expectedExecutionCount,
			execute: { (testFeatures: DummyFeatures) throws -> Returned in
				try await executing(
					implementation
						.loadInstance(
							of: Feature.self,
							context: Void(),
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
	) async where Feature: DisposableFeature, Argument: Equatable & Sendable {
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
		Feature: DisposableFeature,
		Feature.Context == Void,
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
							context: Void(),
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
