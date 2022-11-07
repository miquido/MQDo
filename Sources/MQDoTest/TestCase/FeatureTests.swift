#if DEBUG
	import MQBase
	import XCTest

	@MainActor
	open class FeatureTests: XCTestCase {

		open var commonPreparation: (FeatureTestPreparation) -> Void = { (_: FeatureTestPreparation) -> Void in /* noop */
		}

		public final override func setUp() {
			super.setUp()
		}

		public final override func setUp() async throws {
			try await super.setUp()
		}

		public final override func tearDown() {
			super.tearDown()
		}

		public final override func tearDown() async throws {
			try await super.tearDown()
		}
	}

	// MARK: - Disposable

	extension FeatureTests {

		public final func test<Feature>(
			_ implementation: some DisposableFeatureLoader<Feature>,
			timeout: TimeInterval = 0.5,
			when preparation: @escaping (FeatureTestPreparation) -> Void = {
				(_: FeatureTestPreparation) -> Void in /* noop */
			},
			executing: @escaping (Feature) async throws -> Void,
			file: StaticString = #file,
			line: UInt = #line
		) where Feature: DisposableFeature, Feature.Context == Void {
			let expectation: XCTestExpectation = expectation(
				description: "Test completes in required time of \(timeout)s."
			)

			let testTask: Task<Void, Never> = .init {
				do {
					let testFeatures: Features = .testing(
						Feature.self,
						implementation
					)
					testFeatures.use(instance: Diagnostics.disabled)
					let testPreparation: FeatureTestPreparation = .init(
						features: testFeatures
					)
					self.commonPreparation(testPreparation)
					preparation(testPreparation)
					try await executing(
						testFeatures
							.instance(
								of: Feature.self,
								file: file,
								line: line
							)
					)
				}
				catch {
					XCTFail(
						"Unexpected error thrown: \(error)",
						file: file,
						line: line
					)
				}
				expectation.fulfill()
			}

			waitForExpectations(timeout: timeout)
			testTask.cancel()
		}

		public final func test<Feature>(
			_ implementation: some DisposableFeatureLoader<Feature>,
			context: Feature.Context,
			timeout: TimeInterval = 0.5,
			when preparation: @escaping (FeatureTestPreparation) -> Void = {
				(_: FeatureTestPreparation) -> Void in /* noop */
			},
			executing: @escaping (Feature) async throws -> Void,
			file: StaticString = #file,
			line: UInt = #line
		) where Feature: DisposableFeature {
			let expectation: XCTestExpectation = expectation(
				description: "Test completes in required time of \(timeout)s."
			)

			let testTask: Task<Void, Never> = .init {
				do {
					let testFeatures: Features = .testing(
						Feature.self,
						implementation
					)
					let testPreparation: FeatureTestPreparation = .init(
						features: testFeatures
					)
					self.commonPreparation(testPreparation)
					preparation(testPreparation)
					try await executing(
						testFeatures
							.instance(
								of: Feature.self,
								context: context,
								file: file,
								line: line
							)
					)
				}
				catch {
					XCTFail(
						"Unexpected error thrown: \(error)",
						file: file,
						line: line
					)
				}
				expectation.fulfill()
			}

			waitForExpectations(timeout: timeout)
			testTask.cancel()
		}

		public final func test<Feature, Returned>(
			_ implementation: some DisposableFeatureLoader<Feature>,
			returnsEqual expected: Returned,
			timeout: TimeInterval = 0.5,
			when preparation: @escaping (FeatureTestPreparation) -> Void = {
				(_: FeatureTestPreparation) -> Void in /* noop */
			},
			executing: @escaping (Feature) async throws -> Returned,
			file: StaticString = #file,
			line: UInt = #line
		) where Feature: DisposableFeature, Feature.Context == Void, Returned: Equatable {
			let expectation: XCTestExpectation = expectation(
				description: "Test completes in required time of \(timeout)s."
			)

			let testTask: Task<Void, Never> = .init { [unowned self] in
				do {
					let testFeatures: Features = .testing(
						Feature.self,
						implementation
					)
					let testPreparation: FeatureTestPreparation = .init(
						features: testFeatures
					)
					self.commonPreparation(testPreparation)
					preparation(testPreparation)
					let returned: Returned = try await executing(
						testFeatures
							.instance(
								of: Feature.self,
								file: file,
								line: line
							)
					)
					XCTAssertEqual(
						returned,
						expected,
						"Returned value is not equal to expected.",
						file: file,
						line: line
					)
				}
				catch {
					XCTFail(
						"Unexpected error thrown: \(error)",
						file: file,
						line: line
					)
				}
				expectation.fulfill()
			}

			waitForExpectations(timeout: timeout)
			testTask.cancel()
		}

		public final func test<Feature, Returned>(
			_ implementation: some DisposableFeatureLoader<Feature>,
			context: Feature.Context,
			returnsEqual expected: Returned,
			timeout: TimeInterval = 0.5,
			when preparation: @escaping (FeatureTestPreparation) -> Void = {
				(_: FeatureTestPreparation) -> Void in /* noop */
			},
			executing: @escaping (Feature) async throws -> Returned,
			file: StaticString = #file,
			line: UInt = #line
		) where Feature: DisposableFeature, Returned: Equatable {
			let expectation: XCTestExpectation = expectation(
				description: "Test completes in required time of \(timeout)s."
			)

			let testTask: Task<Void, Never> = .init { [unowned self] in
				do {
					let testFeatures: Features = .testing(
						Feature.self,
						implementation
					)
					let testPreparation: FeatureTestPreparation = .init(
						features: testFeatures
					)
					self.commonPreparation(testPreparation)
					preparation(testPreparation)
					let returned: Returned = try await executing(
						testFeatures
							.instance(
								of: Feature.self,
								context: context,
								file: file,
								line: line
							)
					)
					XCTAssertEqual(
						returned,
						expected,
						"Returned value is not equal to expected.",
						file: file,
						line: line
					)
				}
				catch {
					XCTFail(
						"Unexpected error thrown: \(error)",
						file: file,
						line: line
					)
				}
				expectation.fulfill()
			}

			waitForExpectations(timeout: timeout)
			testTask.cancel()
		}

		public final func test<Feature, Returned, ExpectedError>(
			_ implementation: some DisposableFeatureLoader<Feature>,
			throws expected: ExpectedError.Type,
			timeout: TimeInterval = 0.5,
			when preparation: @escaping (FeatureTestPreparation) -> Void = {
				(_: FeatureTestPreparation) -> Void in /* noop */
			},
			executing: @escaping (Feature) async throws -> Returned,
			file: StaticString = #file,
			line: UInt = #line
		) where Feature: DisposableFeature, Feature.Context == Void, ExpectedError: Error {
			let expectation: XCTestExpectation = expectation(
				description: "Test completes in required time of \(timeout)s."
			)

			let testTask: Task<Void, Never> = .init {
				do {
					let testFeatures: Features = .testing(
						Feature.self,
						implementation
					)
					let testPreparation: FeatureTestPreparation = .init(
						features: testFeatures
					)
					self.commonPreparation(testPreparation)
					preparation(testPreparation)
					let _: Returned = try await executing(
						testFeatures
							.instance(
								of: Feature.self,
								file: file,
								line: line
							)
					)
				}
				catch is ExpectedError {
					// expected error thrown
				}
				catch {
					XCTFail(
						"Unexpected error thrown: \(error)",
						file: file,
						line: line
					)
				}
				expectation.fulfill()
			}

			waitForExpectations(timeout: timeout)
			testTask.cancel()
		}

		public final func test<Feature, Returned, ExpectedError>(
			_ implementation: some DisposableFeatureLoader<Feature>,
			context: Feature.Context,
			throws expected: ExpectedError.Type,
			timeout: TimeInterval = 0.5,
			when preparation: @escaping (FeatureTestPreparation) -> Void = {
				(_: FeatureTestPreparation) -> Void in /* noop */
			},
			executing: @escaping (Feature) async throws -> Returned,
			file: StaticString = #file,
			line: UInt = #line
		) where Feature: DisposableFeature, ExpectedError: Error {
			let expectation: XCTestExpectation = expectation(
				description: "Test completes in required time of \(timeout)s."
			)

			let testTask: Task<Void, Never> = .init {
				do {
					let testFeatures: Features = .testing(
						Feature.self,
						implementation
					)
					let testPreparation: FeatureTestPreparation = .init(
						features: testFeatures
					)
					self.commonPreparation(testPreparation)
					preparation(testPreparation)
					let _: Returned = try await executing(
						testFeatures
							.instance(
								of: Feature.self,
								context: context,
								file: file,
								line: line
							)
					)
				}
				catch is ExpectedError {
					// expected error thrown
				}
				catch {
					XCTFail(
						"Unexpected error thrown: \(error)",
						file: file,
						line: line
					)
				}
				expectation.fulfill()
			}

			waitForExpectations(timeout: timeout)
			testTask.cancel()
		}

		public final func test<Feature>(
			_ implementation: some DisposableFeatureLoader<Feature>,
			executedPrepared expectedExecutionCount: UInt,
			timeout: TimeInterval = 0.5,
			when preparation: @escaping (FeatureTestPreparation, @escaping @Sendable () -> Void) -> Void,
			executing: @escaping (Feature) async throws -> Void,
			file: StaticString = #file,
			line: UInt = #line
		) where Feature: DisposableFeature, Feature.Context == Void {
			let expectation: XCTestExpectation = expectation(
				description: "Test completes in required time of \(timeout)s."
			)

			let testTask: Task<Void, Never> = .init {
				do {
					let testFeatures: Features = .testing(
						Feature.self,
						implementation
					)
					let testPreparation: FeatureTestPreparation = .init(
						features: testFeatures
					)
					self.commonPreparation(testPreparation)
					let executedCount: CriticalSection<UInt> = .init(0)
					let executed: @Sendable () -> Void = {
						executedCount.access { (count: inout UInt) -> Void in
							count += 1
						}
					}
					preparation(testPreparation, executed)
					try await executing(
						testFeatures
							.instance(
								of: Feature.self,
								file: file,
								line: line
							)
					)
					XCTAssertEqual(
						executedCount.access(\.self),
						expectedExecutionCount,
						"Executed count is not matching expected.",
						file: file,
						line: line
					)
				}
				catch {
					XCTFail(
						"Unexpected error thrown: \(error)",
						file: file,
						line: line
					)
				}
				expectation.fulfill()
			}

			waitForExpectations(timeout: timeout)
			testTask.cancel()
		}

		public final func test<Feature>(
			_ implementation: some DisposableFeatureLoader<Feature>,
			context: Feature.Context,
			executedPrepared expectedExecutionCount: UInt,
			timeout: TimeInterval = 0.5,
			when preparation: @escaping (FeatureTestPreparation, @escaping @Sendable () -> Void) -> Void,
			executing: @escaping (Feature) async throws -> Void,
			file: StaticString = #file,
			line: UInt = #line
		) where Feature: DisposableFeature {
			let expectation: XCTestExpectation = expectation(
				description: "Test completes in required time of \(timeout)s."
			)

			let testTask: Task<Void, Never> = .init {
				do {
					let testFeatures: Features = .testing(
						Feature.self,
						implementation
					)
					let testPreparation: FeatureTestPreparation = .init(
						features: testFeatures
					)
					self.commonPreparation(testPreparation)
					let executedCount: CriticalSection<UInt> = .init(0)
					let executed: @Sendable () -> Void = {
						executedCount.access { (count: inout UInt) -> Void in
							count += 1
						}
					}
					preparation(testPreparation, executed)
					try await executing(
						testFeatures
							.instance(
								of: Feature.self,
								context: context,
								file: file,
								line: line
							)
					)
					XCTAssertEqual(
						executedCount.access(\.self),
						expectedExecutionCount,
						"Executed count is not matching expected.",
						file: file,
						line: line
					)
				}
				catch {
					XCTFail(
						"Unexpected error thrown: \(error)",
						file: file,
						line: line
					)
				}
				expectation.fulfill()
			}

			waitForExpectations(timeout: timeout)
			testTask.cancel()
		}

		public final func test<Feature, Argument>(
			_ implementation: some DisposableFeatureLoader<Feature>,
			executedPreparedUsing expectedArgument: Argument,
			timeout: TimeInterval = 0.5,
			when preparation: @escaping (FeatureTestPreparation, @escaping @Sendable (Argument) -> Void) -> Void,
			executing: @escaping (Feature) async throws -> Void,
			file: StaticString = #file,
			line: UInt = #line
		) where Feature: DisposableFeature, Feature.Context == Void, Argument: Equatable & Sendable {
			let expectation: XCTestExpectation = expectation(
				description: "Test completes in required time of \(timeout)s."
			)

			let testTask: Task<Void, Never> = .init {
				do {
					let testFeatures: Features = .testing(
						Feature.self,
						implementation
					)
					let testPreparation: FeatureTestPreparation = .init(
						features: testFeatures
					)
					self.commonPreparation(testPreparation)
					let executedArgument: CriticalSection<Argument?> = .init(.none)
					let executed: @Sendable (Argument) -> Void = { (arg: Argument) in
						executedArgument.access { (argument: inout Argument?) -> Void in
							argument = arg
						}
					}
					preparation(testPreparation, executed)
					try await executing(
						testFeatures
							.instance(
								of: Feature.self,
								file: file,
								line: line
							)
					)
					XCTAssertEqual(
						executedArgument.access(\.self),
						expectedArgument,
						"Executed using argument not matching expected.",
						file: file,
						line: line
					)
				}
				catch {
					XCTFail(
						"Unexpected error thrown: \(error)",
						file: file,
						line: line
					)
				}
				expectation.fulfill()
			}

			waitForExpectations(timeout: timeout)
			testTask.cancel()
		}

		public final func test<Feature, Argument>(
			_ implementation: some DisposableFeatureLoader<Feature>,
			context: Feature.Context,
			executedPreparedUsing expectedArgument: Argument,
			timeout: TimeInterval = 0.5,
			when prepare: @escaping (FeatureTestPreparation, @escaping @Sendable (Argument) -> Void) -> Void,
			executing: @escaping (Feature) async throws -> Void,
			file: StaticString = #file,
			line: UInt = #line
		) where Feature: DisposableFeature, Argument: Equatable & Sendable {
			let expectation: XCTestExpectation = expectation(
				description: "Test completes in required time of \(timeout)s."
			)

			let testTask: Task<Void, Never> = .init {
				do {
					let testFeatures: Features = .testing(
						Feature.self,
						implementation
					)
					let testPreparation: FeatureTestPreparation = .init(
						features: testFeatures
					)
					self.commonPreparation(testPreparation)
					let executedArgument: CriticalSection<Argument?> = .init(.none)
					let executed: @Sendable (Argument) -> Void = { (arg: Argument) in
						executedArgument.access { (argument: inout Argument?) -> Void in
							argument = arg
						}
					}
					prepare(testPreparation, executed)
					try await executing(
						testFeatures
							.instance(
								of: Feature.self,
								context: context,
								file: file,
								line: line
							)
					)
					XCTAssertEqual(
						executedArgument.access(\.self),
						expectedArgument,
						"Executed using argument not matching expected.",
						file: file,
						line: line
					)
				}
				catch {
					XCTFail(
						"Unexpected error thrown: \(error)",
						file: file,
						line: line
					)
				}
				expectation.fulfill()
			}

			waitForExpectations(timeout: timeout)
			testTask.cancel()
		}
	}

	// MARK: - Cacheable

	extension FeatureTests {

		public final func test<Feature>(
			_ implementation: some CacheableFeatureLoader<Feature>,
			timeout: TimeInterval = 0.5,
			when preparation: @escaping (FeatureTestPreparation) -> Void = {
				(_: FeatureTestPreparation) -> Void in /* noop */
			},
			executing: @escaping (Feature) async throws -> Void,
			file: StaticString = #file,
			line: UInt = #line
		) where Feature: CacheableFeature, Feature.Context == ContextlessCacheableFeatureContext {
			let expectation: XCTestExpectation = expectation(
				description: "Test completes in required time of \(timeout)s."
			)

			let testTask: Task<Void, Never> = .init {
				do {
					let testFeatures: Features = .testing(
						Feature.self,
						implementation
					)
					let testPreparation: FeatureTestPreparation = .init(
						features: testFeatures
					)
					self.commonPreparation(testPreparation)
					preparation(testPreparation)
					try await executing(
						testFeatures
							.instance(
								of: Feature.self,
								file: file,
								line: line
							)
					)
				}
				catch {
					XCTFail(
						"Unexpected error thrown: \(error)",
						file: file,
						line: line
					)
				}
				expectation.fulfill()
			}

			waitForExpectations(timeout: timeout)
			testTask.cancel()
		}

		public final func test<Feature>(
			_ implementation: some CacheableFeatureLoader<Feature>,
			context: Feature.Context,
			timeout: TimeInterval = 0.5,
			when preparation: @escaping (FeatureTestPreparation) -> Void = {
				(_: FeatureTestPreparation) -> Void in /* noop */
			},
			executing: @escaping (Feature) async throws -> Void,
			file: StaticString = #file,
			line: UInt = #line
		) where Feature: CacheableFeature {
			let expectation: XCTestExpectation = expectation(
				description: "Test completes in required time of \(timeout)s."
			)

			let testTask: Task<Void, Never> = .init {
				do {
					let testFeatures: Features = .testing(
						Feature.self,
						implementation
					)
					let testPreparation: FeatureTestPreparation = .init(
						features: testFeatures
					)
					self.commonPreparation(testPreparation)
					preparation(testPreparation)
					try await executing(
						testFeatures
							.instance(
								of: Feature.self,
								context: context,
								file: file,
								line: line
							)
					)
				}
				catch {
					XCTFail(
						"Unexpected error thrown: \(error)",
						file: file,
						line: line
					)
				}
				expectation.fulfill()
			}

			waitForExpectations(timeout: timeout)
			testTask.cancel()
		}

		public final func test<Feature, Returned>(
			_ implementation: some CacheableFeatureLoader<Feature>,
			returnsEqual expected: Returned,
			timeout: TimeInterval = 0.5,
			when preparation: @escaping (FeatureTestPreparation) -> Void = {
				(_: FeatureTestPreparation) -> Void in /* noop */
			},
			executing: @escaping (Feature) async throws -> Returned,
			file: StaticString = #file,
			line: UInt = #line
		) where Feature: CacheableFeature, Feature.Context == ContextlessCacheableFeatureContext, Returned: Equatable {
			let expectation: XCTestExpectation = expectation(
				description: "Test completes in required time of \(timeout)s."
			)

			let testTask: Task<Void, Never> = .init { [unowned self] in
				do {
					let testFeatures: Features = .testing(
						Feature.self,
						implementation
					)
					let testPreparation: FeatureTestPreparation = .init(
						features: testFeatures
					)
					self.commonPreparation(testPreparation)
					preparation(testPreparation)
					let returned: Returned = try await executing(
						testFeatures
							.instance(
								of: Feature.self,
								file: file,
								line: line
							)
					)
					XCTAssertEqual(
						returned,
						expected,
						"Returned value is not equal to expected.",
						file: file,
						line: line
					)
				}
				catch {
					XCTFail(
						"Unexpected error thrown: \(error)",
						file: file,
						line: line
					)
				}
				expectation.fulfill()
			}

			waitForExpectations(timeout: timeout)
			testTask.cancel()
		}

		public final func test<Feature, Returned>(
			_ implementation: some CacheableFeatureLoader<Feature>,
			context: Feature.Context,
			returnsEqual expected: Returned,
			timeout: TimeInterval = 0.5,
			when preparation: @escaping (FeatureTestPreparation) -> Void = {
				(_: FeatureTestPreparation) -> Void in /* noop */
			},
			executing: @escaping (Feature) async throws -> Returned,
			file: StaticString = #file,
			line: UInt = #line
		) where Feature: CacheableFeature, Returned: Equatable {
			let expectation: XCTestExpectation = expectation(
				description: "Test completes in required time of \(timeout)s."
			)

			let testTask: Task<Void, Never> = .init { [unowned self] in
				do {
					let testFeatures: Features = .testing(
						Feature.self,
						implementation
					)
					let testPreparation: FeatureTestPreparation = .init(
						features: testFeatures
					)
					self.commonPreparation(testPreparation)
					preparation(testPreparation)
					let returned: Returned = try await executing(
						testFeatures
							.instance(
								of: Feature.self,
								context: context,
								file: file,
								line: line
							)
					)
					XCTAssertEqual(
						returned,
						expected,
						"Returned value is not equal to expected.",
						file: file,
						line: line
					)
				}
				catch {
					XCTFail(
						"Unexpected error thrown: \(error)",
						file: file,
						line: line
					)
				}
				expectation.fulfill()
			}

			waitForExpectations(timeout: timeout)
			testTask.cancel()
		}

		public final func test<Feature, Returned, ExpectedError>(
			_ implementation: some CacheableFeatureLoader<Feature>,
			throws expected: ExpectedError.Type,
			timeout: TimeInterval = 0.5,
			when preparation: @escaping (FeatureTestPreparation) -> Void = {
				(_: FeatureTestPreparation) -> Void in /* noop */
			},
			executing: @escaping (Feature) async throws -> Returned,
			file: StaticString = #file,
			line: UInt = #line
		) where Feature: CacheableFeature, Feature.Context == ContextlessCacheableFeatureContext, ExpectedError: Error {
			let expectation: XCTestExpectation = expectation(
				description: "Test completes in required time of \(timeout)s."
			)

			let testTask: Task<Void, Never> = .init {
				do {
					let testFeatures: Features = .testing(
						Feature.self,
						implementation
					)
					let testPreparation: FeatureTestPreparation = .init(
						features: testFeatures
					)
					self.commonPreparation(testPreparation)
					preparation(testPreparation)
					let _: Returned = try await executing(
						testFeatures
							.instance(
								of: Feature.self,
								file: file,
								line: line
							)
					)
				}
				catch is ExpectedError {
					// expected error thrown
				}
				catch {
					XCTFail(
						"Unexpected error thrown: \(error)",
						file: file,
						line: line
					)
				}
				expectation.fulfill()
			}

			waitForExpectations(timeout: timeout)
			testTask.cancel()
		}

		public final func test<Feature, Returned, ExpectedError>(
			_ implementation: some CacheableFeatureLoader<Feature>,
			context: Feature.Context,
			throws expected: ExpectedError.Type,
			timeout: TimeInterval = 0.5,
			when preparation: @escaping (FeatureTestPreparation) -> Void = {
				(_: FeatureTestPreparation) -> Void in /* noop */
			},
			executing: @escaping (Feature) async throws -> Returned,
			file: StaticString = #file,
			line: UInt = #line
		) where Feature: CacheableFeature, ExpectedError: Error {
			let expectation: XCTestExpectation = expectation(
				description: "Test completes in required time of \(timeout)s."
			)

			let testTask: Task<Void, Never> = .init {
				do {
					let testFeatures: Features = .testing(
						Feature.self,
						implementation
					)
					let testPreparation: FeatureTestPreparation = .init(
						features: testFeatures
					)
					self.commonPreparation(testPreparation)
					preparation(testPreparation)
					let _: Returned = try await executing(
						testFeatures
							.instance(
								of: Feature.self,
								context: context,
								file: file,
								line: line
							)
					)
				}
				catch is ExpectedError {
					// expected error thrown
				}
				catch {
					XCTFail(
						"Unexpected error thrown: \(error)",
						file: file,
						line: line
					)
				}
				expectation.fulfill()
			}

			waitForExpectations(timeout: timeout)
			testTask.cancel()
		}

		public final func test<Feature>(
			_ implementation: some CacheableFeatureLoader<Feature>,
			executedPrepared expectedExecutionCount: UInt,
			timeout: TimeInterval = 0.5,
			when preparation: @escaping (FeatureTestPreparation, @escaping @Sendable () -> Void) -> Void,
			executing: @escaping (Feature) async throws -> Void,
			file: StaticString = #file,
			line: UInt = #line
		) where Feature: CacheableFeature, Feature.Context == ContextlessCacheableFeatureContext {
			let expectation: XCTestExpectation = expectation(
				description: "Test completes in required time of \(timeout)s."
			)

			let testTask: Task<Void, Never> = .init {
				do {
					let testFeatures: Features = .testing(
						Feature.self,
						implementation
					)
					let testPreparation: FeatureTestPreparation = .init(
						features: testFeatures
					)
					self.commonPreparation(testPreparation)
					let executedCount: CriticalSection<UInt> = .init(0)
					let executed: @Sendable () -> Void = {
						executedCount.access { (count: inout UInt) -> Void in
							count += 1
						}
					}
					preparation(testPreparation, executed)
					try await executing(
						testFeatures
							.instance(
								of: Feature.self,
								file: file,
								line: line
							)
					)
					XCTAssertEqual(
						executedCount.access(\.self),
						expectedExecutionCount,
						"Executed count is not matching expected.",
						file: file,
						line: line
					)
				}
				catch {
					XCTFail(
						"Unexpected error thrown: \(error)",
						file: file,
						line: line
					)
				}
				expectation.fulfill()
			}

			waitForExpectations(timeout: timeout)
			testTask.cancel()
		}

		public final func test<Feature>(
			_ implementation: some CacheableFeatureLoader<Feature>,
			context: Feature.Context,
			executedPrepared expectedExecutionCount: UInt,
			timeout: TimeInterval = 0.5,
			when preparation: @escaping (FeatureTestPreparation, @escaping @Sendable () -> Void) -> Void,
			executing: @escaping (Feature) async throws -> Void,
			file: StaticString = #file,
			line: UInt = #line
		) where Feature: CacheableFeature {
			let expectation: XCTestExpectation = expectation(
				description: "Test completes in required time of \(timeout)s."
			)

			let testTask: Task<Void, Never> = .init {
				do {
					let testFeatures: Features = .testing(
						Feature.self,
						implementation
					)
					let testPreparation: FeatureTestPreparation = .init(
						features: testFeatures
					)
					self.commonPreparation(testPreparation)
					let executedCount: CriticalSection<UInt> = .init(0)
					let executed: @Sendable () -> Void = {
						executedCount.access { (count: inout UInt) -> Void in
							count += 1
						}
					}
					preparation(testPreparation, executed)
					try await executing(
						testFeatures
							.instance(
								of: Feature.self,
								context: context,
								file: file,
								line: line
							)
					)
					XCTAssertEqual(
						executedCount.access(\.self),
						expectedExecutionCount,
						"Executed count is not matching expected.",
						file: file,
						line: line
					)
				}
				catch {
					XCTFail(
						"Unexpected error thrown: \(error)",
						file: file,
						line: line
					)
				}
				expectation.fulfill()
			}

			waitForExpectations(timeout: timeout)
			testTask.cancel()
		}

		public final func test<Feature, Argument>(
			_ implementation: some CacheableFeatureLoader<Feature>,
			executedPreparedUsing expectedArgument: Argument,
			timeout: TimeInterval = 0.5,
			when preparation: @escaping (FeatureTestPreparation, @Sendable (Argument) -> Void) -> Void,
			executing: @escaping (Feature) async throws -> Void,
			file: StaticString = #file,
			line: UInt = #line
		)
		where
			Feature: CacheableFeature,
			Feature.Context == ContextlessCacheableFeatureContext,
			Argument: Equatable & Sendable
		{
			let expectation: XCTestExpectation = expectation(
				description: "Test completes in required time of \(timeout)s."
			)

			let testTask: Task<Void, Never> = .init {
				do {
					let testFeatures: Features = .testing(
						Feature.self,
						implementation
					)
					let testPreparation: FeatureTestPreparation = .init(
						features: testFeatures
					)
					self.commonPreparation(testPreparation)
					let executedArgument: CriticalSection<Argument?> = .init(.none)
					let executed: @Sendable (Argument) -> Void = { (arg: Argument) in
						executedArgument.access { (argument: inout Argument?) -> Void in
							argument = arg
						}
					}
					preparation(testPreparation, executed)
					try await executing(
						testFeatures
							.instance(
								of: Feature.self,
								file: file,
								line: line
							)
					)
					XCTAssertEqual(
						executedArgument.access(\.self),
						expectedArgument,
						"Executed using argument not matching expected.",
						file: file,
						line: line
					)
				}
				catch {
					XCTFail(
						"Unexpected error thrown: \(error)",
						file: file,
						line: line
					)
				}
				expectation.fulfill()
			}

			waitForExpectations(timeout: timeout)
			testTask.cancel()
		}

		public final func test<Feature, Argument>(
			_ implementation: some CacheableFeatureLoader<Feature>,
			context: Feature.Context,
			executedPreparedUsing expectedArgument: Argument,
			timeout: TimeInterval = 0.5,
			when prepare: @escaping (FeatureTestPreparation, @Sendable (Argument) -> Void) -> Void,
			executing: @escaping (Feature) async throws -> Void,
			file: StaticString = #file,
			line: UInt = #line
		) where Feature: CacheableFeature, Argument: Equatable & Sendable {
			let expectation: XCTestExpectation = expectation(
				description: "Test completes in required time of \(timeout)s."
			)

			let testTask: Task<Void, Never> = .init {
				do {
					let testFeatures: Features = .testing(
						Feature.self,
						implementation
					)
					let testPreparation: FeatureTestPreparation = .init(
						features: testFeatures
					)
					self.commonPreparation(testPreparation)
					let executedArgument: CriticalSection<Argument?> = .init(.none)
					let executed: @Sendable (Argument) -> Void = { (arg: Argument) in
						executedArgument.access { (argument: inout Argument?) -> Void in
							argument = arg
						}
					}
					prepare(testPreparation, executed)
					try await executing(
						testFeatures
							.instance(
								of: Feature.self,
								context: context,
								file: file,
								line: line
							)
					)
					XCTAssertEqual(
						executedArgument.access(\.self),
						expectedArgument,
						"Executed using argument not matching expected.",
						file: file,
						line: line
					)
				}
				catch {
					XCTFail(
						"Unexpected error thrown: \(error)",
						file: file,
						line: line
					)
				}
				expectation.fulfill()
			}

			waitForExpectations(timeout: timeout)
			testTask.cancel()
		}
	}
#endif
