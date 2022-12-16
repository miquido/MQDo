#if DEBUG

	import MQBase

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
					testFeatures
						.use(instance: Diagnostics.disabled)
					testFeatures
						.use(
							instance:
								AsyncExecutor
								.mock(
									using: self.asyncExecutorControl
								)
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
					testFeatures
						.use(instance: Diagnostics.disabled)
					testFeatures
						.use(
							instance:
								AsyncExecutor
								.mock(
									using: self.asyncExecutorControl
								)
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
					testFeatures
						.use(instance: Diagnostics.disabled)
					testFeatures
						.use(
							instance:
								AsyncExecutor
								.mock(
									using: self.asyncExecutorControl
								)
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
					testFeatures
						.use(instance: Diagnostics.disabled)
					testFeatures
						.use(
							instance:
								AsyncExecutor
								.mock(
									using: self.asyncExecutorControl
								)
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
					testFeatures
						.use(instance: Diagnostics.disabled)
					testFeatures
						.use(
							instance:
								AsyncExecutor
								.mock(
									using: self.asyncExecutorControl
								)
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

					XCTFail(
						"No error thrown",
						file: file,
						line: line
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
					testFeatures
						.use(instance: Diagnostics.disabled)
					testFeatures
						.use(
							instance:
								AsyncExecutor
								.mock(
									using: self.asyncExecutorControl
								)
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

					XCTFail(
						"No error thrown",
						file: file,
						line: line
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
					testFeatures
						.use(instance: Diagnostics.disabled)
					testFeatures
						.use(
							instance:
								AsyncExecutor
								.mock(
									using: self.asyncExecutorControl
								)
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
					testFeatures
						.use(instance: Diagnostics.disabled)
					testFeatures
						.use(
							instance:
								AsyncExecutor
								.mock(
									using: self.asyncExecutorControl
								)
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
			when preparation: @escaping (FeatureTestPreparation, @escaping @Sendable (Argument) -> Void) -> Void,
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
					testFeatures
						.use(instance: Diagnostics.disabled)
					testFeatures
						.use(
							instance:
								AsyncExecutor
								.mock(
									using: self.asyncExecutorControl
								)
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
			when prepare: @escaping (FeatureTestPreparation, @escaping @Sendable (Argument) -> Void) -> Void,
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
					testFeatures
						.use(instance: Diagnostics.disabled)
					testFeatures
						.use(
							instance:
								AsyncExecutor
								.mock(
									using: self.asyncExecutorControl
								)
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

	extension FeatureTests {

		public final func test<FeatureImplementation>(
			_ implementation: FeatureImplementation.Type,
			timeout: TimeInterval = 0.5,
			when preparation: @escaping (FeatureTestPreparation) -> Void = {
				(_: FeatureTestPreparation) -> Void in /* noop */
			},
			executing: @escaping (FeatureImplementation.Feature) async throws -> Void,
			file: StaticString = #file,
			line: UInt = #line
		)
		where
			FeatureImplementation: CacheableFeatureImplementation,
			FeatureImplementation.Feature.Context == ContextlessCacheableFeatureContext
		{
			let expectation: XCTestExpectation = expectation(
				description: "Test completes in required time of \(timeout)s."
			)

			let testTask: Task<Void, Never> = .init {
				do {
					let testFeatures: Features = .testing(
						FeatureImplementation.self
					)
					testFeatures
						.use(instance: Diagnostics.disabled)
					testFeatures
						.use(
							instance:
								AsyncExecutor
								.mock(
									using: self.asyncExecutorControl
								)
						)
					let testPreparation: FeatureTestPreparation = .init(
						features: testFeatures
					)
					self.commonPreparation(testPreparation)
					preparation(testPreparation)
					try await executing(
						testFeatures
							.instance(
								of: FeatureImplementation.Feature.self,
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

		public final func test<FeatureImplementation>(
			_ implementation: FeatureImplementation.Type,
			context: FeatureImplementation.Feature.Context,
			timeout: TimeInterval = 0.5,
			when preparation: @escaping (FeatureTestPreparation) -> Void = {
				(_: FeatureTestPreparation) -> Void in /* noop */
			},
			executing: @escaping (FeatureImplementation.Feature) async throws -> Void,
			file: StaticString = #file,
			line: UInt = #line
		) where FeatureImplementation: CacheableFeatureImplementation {
			let expectation: XCTestExpectation = expectation(
				description: "Test completes in required time of \(timeout)s."
			)

			let testTask: Task<Void, Never> = .init {
				do {
					let testFeatures: Features = .testing(
						FeatureImplementation.self
					)
					testFeatures
						.use(instance: Diagnostics.disabled)
					testFeatures
						.use(
							instance:
								AsyncExecutor
								.mock(
									using: self.asyncExecutorControl
								)
						)
					let testPreparation: FeatureTestPreparation = .init(
						features: testFeatures
					)
					self.commonPreparation(testPreparation)
					preparation(testPreparation)
					try await executing(
						testFeatures
							.instance(
								of: FeatureImplementation.Feature.self,
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

		public final func test<FeatureImplementation, Returned>(
			_ implementation: FeatureImplementation.Type,
			returnsEqual expected: Returned,
			timeout: TimeInterval = 0.5,
			when preparation: @escaping (FeatureTestPreparation) -> Void = {
				(_: FeatureTestPreparation) -> Void in /* noop */
			},
			executing: @escaping (FeatureImplementation.Feature) async throws -> Returned,
			file: StaticString = #file,
			line: UInt = #line
		)
		where
			FeatureImplementation: CacheableFeatureImplementation,
			FeatureImplementation.Feature.Context == ContextlessCacheableFeatureContext,
			Returned: Equatable
		{
			let expectation: XCTestExpectation = expectation(
				description: "Test completes in required time of \(timeout)s."
			)

			let testTask: Task<Void, Never> = .init { [unowned self] in
				do {
					let testFeatures: Features = .testing(
						FeatureImplementation.self
					)
					testFeatures
						.use(instance: Diagnostics.disabled)
					testFeatures
						.use(
							instance:
								AsyncExecutor
								.mock(
									using: self.asyncExecutorControl
								)
						)
					let testPreparation: FeatureTestPreparation = .init(
						features: testFeatures
					)
					self.commonPreparation(testPreparation)
					preparation(testPreparation)
					let returned: Returned = try await executing(
						testFeatures
							.instance(
								of: FeatureImplementation.Feature.self,
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

		public final func test<FeatureImplementation, Returned>(
			_ implementation: FeatureImplementation.Type,
			context: FeatureImplementation.Feature.Context,
			returnsEqual expected: Returned,
			timeout: TimeInterval = 0.5,
			when preparation: @escaping (FeatureTestPreparation) -> Void = {
				(_: FeatureTestPreparation) -> Void in /* noop */
			},
			executing: @escaping (FeatureImplementation.Feature) async throws -> Returned,
			file: StaticString = #file,
			line: UInt = #line
		) where FeatureImplementation: CacheableFeatureImplementation, Returned: Equatable {
			let expectation: XCTestExpectation = expectation(
				description: "Test completes in required time of \(timeout)s."
			)

			let testTask: Task<Void, Never> = .init { [unowned self] in
				do {
					let testFeatures: Features = .testing(
						FeatureImplementation.self
					)
					testFeatures
						.use(instance: Diagnostics.disabled)
					testFeatures
						.use(
							instance:
								AsyncExecutor
								.mock(
									using: self.asyncExecutorControl
								)
						)
					let testPreparation: FeatureTestPreparation = .init(
						features: testFeatures
					)
					self.commonPreparation(testPreparation)
					preparation(testPreparation)
					let returned: Returned = try await executing(
						testFeatures
							.instance(
								of: FeatureImplementation.Feature.self,
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

		public final func test<FeatureImplementation, Returned, ExpectedError>(
			_ implementation: FeatureImplementation.Type,
			throws expected: ExpectedError.Type,
			timeout: TimeInterval = 0.5,
			when preparation: @escaping (FeatureTestPreparation) -> Void = {
				(_: FeatureTestPreparation) -> Void in /* noop */
			},
			executing: @escaping (FeatureImplementation.Feature) async throws -> Returned,
			file: StaticString = #file,
			line: UInt = #line
		)
		where
			FeatureImplementation: CacheableFeatureImplementation,
			FeatureImplementation.Feature.Context == ContextlessCacheableFeatureContext,
			ExpectedError: Error
		{
			let expectation: XCTestExpectation = expectation(
				description: "Test completes in required time of \(timeout)s."
			)

			let testTask: Task<Void, Never> = .init {
				do {
					let testFeatures: Features = .testing(
						FeatureImplementation.self
					)
					testFeatures
						.use(instance: Diagnostics.disabled)
					testFeatures
						.use(
							instance:
								AsyncExecutor
								.mock(
									using: self.asyncExecutorControl
								)
						)
					let testPreparation: FeatureTestPreparation = .init(
						features: testFeatures
					)
					self.commonPreparation(testPreparation)
					preparation(testPreparation)
					let _: Returned = try await executing(
						testFeatures
							.instance(
								of: FeatureImplementation.Feature.self,
								file: file,
								line: line
							)
					)

					XCTFail(
						"No error thrown",
						file: file,
						line: line
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

		public final func test<FeatureImplementation, Returned, ExpectedError>(
			_ implementation: FeatureImplementation.Type,
			context: FeatureImplementation.Feature.Context,
			throws expected: ExpectedError.Type,
			timeout: TimeInterval = 0.5,
			when preparation: @escaping (FeatureTestPreparation) -> Void = {
				(_: FeatureTestPreparation) -> Void in /* noop */
			},
			executing: @escaping (FeatureImplementation.Feature) async throws -> Returned,
			file: StaticString = #file,
			line: UInt = #line
		) where FeatureImplementation: CacheableFeatureImplementation, ExpectedError: Error {
			let expectation: XCTestExpectation = expectation(
				description: "Test completes in required time of \(timeout)s."
			)

			let testTask: Task<Void, Never> = .init {
				do {
					let testFeatures: Features = .testing(
						FeatureImplementation.self
					)
					testFeatures
						.use(instance: Diagnostics.disabled)
					testFeatures
						.use(
							instance:
								AsyncExecutor
								.mock(
									using: self.asyncExecutorControl
								)
						)
					let testPreparation: FeatureTestPreparation = .init(
						features: testFeatures
					)
					self.commonPreparation(testPreparation)
					preparation(testPreparation)
					let _: Returned = try await executing(
						testFeatures
							.instance(
								of: FeatureImplementation.Feature.self,
								context: context,
								file: file,
								line: line
							)
					)

					XCTFail(
						"No error thrown",
						file: file,
						line: line
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

		public final func test<FeatureImplementation>(
			_ implementation: FeatureImplementation.Type,
			executedPrepared expectedExecutionCount: UInt,
			timeout: TimeInterval = 0.5,
			when preparation: @escaping (FeatureTestPreparation, @escaping @Sendable () -> Void) -> Void,
			executing: @escaping (FeatureImplementation.Feature) async throws -> Void,
			file: StaticString = #file,
			line: UInt = #line
		)
		where
			FeatureImplementation: CacheableFeatureImplementation,
			FeatureImplementation.Feature.Context == ContextlessCacheableFeatureContext
		{
			let expectation: XCTestExpectation = expectation(
				description: "Test completes in required time of \(timeout)s."
			)

			let testTask: Task<Void, Never> = .init {
				do {
					let testFeatures: Features = .testing(
						FeatureImplementation.self
					)
					testFeatures
						.use(instance: Diagnostics.disabled)
					testFeatures
						.use(
							instance:
								AsyncExecutor
								.mock(
									using: self.asyncExecutorControl
								)
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
								of: FeatureImplementation.Feature.self,
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

		public final func test<FeatureImplementation>(
			_ implementation: FeatureImplementation.Type,
			context: FeatureImplementation.Feature.Context,
			executedPrepared expectedExecutionCount: UInt,
			timeout: TimeInterval = 0.5,
			when preparation: @escaping (FeatureTestPreparation, @escaping @Sendable () -> Void) -> Void,
			executing: @escaping (FeatureImplementation.Feature) async throws -> Void,
			file: StaticString = #file,
			line: UInt = #line
		) where FeatureImplementation: CacheableFeatureImplementation {
			let expectation: XCTestExpectation = expectation(
				description: "Test completes in required time of \(timeout)s."
			)

			let testTask: Task<Void, Never> = .init {
				do {
					let testFeatures: Features = .testing(
						FeatureImplementation.self
					)
					testFeatures
						.use(instance: Diagnostics.disabled)
					testFeatures
						.use(
							instance:
								AsyncExecutor
								.mock(
									using: self.asyncExecutorControl
								)
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
								of: FeatureImplementation.Feature.self,
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

		public final func test<FeatureImplementation, Argument>(
			_ implementation: FeatureImplementation.Type,
			executedPreparedUsing expectedArgument: Argument,
			timeout: TimeInterval = 0.5,
			when preparation: @escaping (FeatureTestPreparation, @escaping @Sendable (Argument) -> Void) -> Void,
			executing: @escaping (FeatureImplementation.Feature) async throws -> Void,
			file: StaticString = #file,
			line: UInt = #line
		)
		where
			FeatureImplementation: CacheableFeatureImplementation,
			FeatureImplementation.Feature.Context == ContextlessCacheableFeatureContext,
			Argument: Equatable & Sendable
		{
			let expectation: XCTestExpectation = expectation(
				description: "Test completes in required time of \(timeout)s."
			)

			let testTask: Task<Void, Never> = .init {
				do {
					let testFeatures: Features = .testing(
						FeatureImplementation.self
					)
					testFeatures
						.use(instance: Diagnostics.disabled)
					testFeatures
						.use(
							instance:
								AsyncExecutor
								.mock(
									using: self.asyncExecutorControl
								)
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
								of: FeatureImplementation.Feature.self,
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

		public final func test<FeatureImplementation, Argument>(
			_ implementation: FeatureImplementation.Type,
			context: FeatureImplementation.Feature.Context,
			executedPreparedUsing expectedArgument: Argument,
			timeout: TimeInterval = 0.5,
			when prepare: @escaping (FeatureTestPreparation, @escaping @Sendable (Argument) -> Void) -> Void,
			executing: @escaping (FeatureImplementation.Feature) async throws -> Void,
			file: StaticString = #file,
			line: UInt = #line
		) where FeatureImplementation: CacheableFeatureImplementation, Argument: Equatable & Sendable {
			let expectation: XCTestExpectation = expectation(
				description: "Test completes in required time of \(timeout)s."
			)

			let testTask: Task<Void, Never> = .init {
				do {
					let testFeatures: Features = .testing(
						FeatureImplementation.self
					)
					testFeatures
						.use(instance: Diagnostics.disabled)
					testFeatures
						.use(
							instance:
								AsyncExecutor
								.mock(
									using: self.asyncExecutorControl
								)
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
								of: FeatureImplementation.Feature.self,
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
