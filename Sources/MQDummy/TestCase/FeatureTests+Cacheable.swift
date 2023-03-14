#if canImport(XCTest)

	import MQDo
	import XCTest

	// MARK: - Cacheable

	extension FeatureTests {

		public final func test<Feature>(
			_ implementation: FeatureLoader,
			context: Feature.Context,
			timeout: TimeInterval = 0.5,
			when preparation: @escaping (FeaturePatches) -> Void = {
				(_: FeaturePatches) -> Void in /* noop */
			},
			executing: @escaping (Feature) async throws -> Void,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Feature: CacheableFeature {
			self.test(
				timeout: timeout,
				preparation: preparation,
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
			timeout: TimeInterval = 0.5,
			when preparation: @escaping (FeaturePatches) -> Void = {
				(_: FeaturePatches) -> Void in /* noop */
			},
			executing: @escaping (Feature) async throws -> Void,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Feature: CacheableFeature, Feature.Context == CacheableFeatureVoidContext {
			self.test(
				timeout: timeout,
				preparation: preparation,
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
			timeout: TimeInterval = 0.5,
			when preparation: @escaping (FeaturePatches) -> Void = {
				(_: FeaturePatches) -> Void in /* noop */
			},
			executing: @escaping (Feature) async throws -> Returned,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Feature: CacheableFeature, Returned: Equatable {
			self.test(
				timeout: timeout,
				preparation: preparation,
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
			timeout: TimeInterval = 0.5,
			when preparation: @escaping (FeaturePatches) -> Void = {
				(_: FeaturePatches) -> Void in /* noop */
			},
			executing: @escaping (Feature) async throws -> Returned,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Feature: CacheableFeature, Feature.Context == CacheableFeatureVoidContext, Returned: Equatable {
			self.test(
				timeout: timeout,
				preparation: preparation,
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
			timeout: TimeInterval = 0.5,
			when preparation: @escaping (FeaturePatches) -> Void = {
				(_: FeaturePatches) -> Void in /* noop */
			},
			executing: @escaping (Feature) async throws -> Returned,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Feature: CacheableFeature, ExpectedError: Error {
			self.test(
				timeout: timeout,
				preparation: preparation,
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
			timeout: TimeInterval = 0.5,
			when preparation: @escaping (FeaturePatches) -> Void = {
				(_: FeaturePatches) -> Void in /* noop */
			},
			executing: @escaping (Feature) async throws -> Returned,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Feature: CacheableFeature, Feature.Context == CacheableFeatureVoidContext, ExpectedError: Error {
			self.test(
				timeout: timeout,
				preparation: preparation,
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
			timeout: TimeInterval = 0.5,
			when preparation: @escaping (FeaturePatches, @escaping @Sendable () -> Void) -> Void,
			executing: @escaping (Feature) async throws -> Returned,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Feature: CacheableFeature {
			self.test(
				timeout: timeout,
				preparation: preparation,
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
			timeout: TimeInterval = 0.5,
			when preparation: @escaping (FeaturePatches, @escaping @Sendable () -> Void) -> Void,
			executing: @escaping (Feature) async throws -> Returned,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Feature: CacheableFeature, Feature.Context == CacheableFeatureVoidContext {
			self.test(
				timeout: timeout,
				preparation: preparation,
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
			timeout: TimeInterval = 0.5,
			when preparation: @escaping (FeaturePatches, @escaping @Sendable (Argument) -> Void) -> Void,
			executing: @escaping (Feature) async throws -> Returned,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Feature: CacheableFeature, Argument: Equatable & Sendable {
			self.test(
				timeout: timeout,
				preparation: preparation,
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
			timeout: TimeInterval = 0.5,
			when preparation: @escaping (FeaturePatches, @escaping @Sendable (Argument) -> Void) -> Void,
			executing: @escaping (Feature) async throws -> Returned,
			file: StaticString = #fileID,
			line: UInt = #line
		)
		where
			Feature: CacheableFeature,
			Feature.Context == CacheableFeatureVoidContext,
			Argument: Equatable & Sendable
		{
			self.test(
				timeout: timeout,
				preparation: preparation,
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

#endif
