import MQDo
import XCTest

@MainActor
open class FeatureTests: XCTestCase {

	public final override class func setUp() {
		super.setUp()
		runtimeAssertionMethod = { _, _, _, _ in }
	}

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

	@inline(__always)
	internal final func test(
		timeout: TimeInterval,
		preparation: @escaping (FeatureTestPreparation) -> Void,
		execute: @escaping (TestFeatures) async throws -> Void,
		file: StaticString,
		line: UInt
	) {
		let expectation: XCTestExpectation = expectation(
			description: "Test completes in required time of \(timeout)s."
		)

		let testTask: Task<Void, Never> = .init {
			do {
				let testFeatures: TestFeatures = .init()
				let testPreparation: FeatureTestPreparation = .init(
					features: testFeatures
				)
				self.commonPreparation(testPreparation)
				preparation(testPreparation)
				try await execute(testFeatures)
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

	@inline(__always)
	internal final func test<Returned>(
		timeout: TimeInterval,
		preparation: @escaping (FeatureTestPreparation) -> Void,
		returnsEqual expected: Returned,
		execute: @escaping (TestFeatures) async throws -> Returned,
		file: StaticString,
		line: UInt
	) where Returned: Equatable {
		self.test(
			timeout: timeout,
			preparation: preparation,
			execute: { (testFeatures: TestFeatures) throws -> Void in
				let returned: Returned = try await execute(
					testFeatures
				)
				XCTAssertEqual(
					returned,
					expected,
					file: file,
					line: line
				)
			},
			file: file,
			line: line
		)
	}

	@inline(__always)
	internal final func test<Returned, ExpectedError>(
		timeout: TimeInterval,
		preparation: @escaping (FeatureTestPreparation) -> Void,
		throws expected: ExpectedError.Type,
		execute: @escaping (TestFeatures) async throws -> Returned,
		file: StaticString,
		line: UInt
	) where ExpectedError: Error {
		self.test(
			timeout: timeout,
			preparation: preparation,
			execute: { (testFeatures: TestFeatures) throws -> Void in
				do {
					_ = try await execute(
						testFeatures
					)
					XCTFail(
						"No error was thrown",
						file: file,
						line: line
					)
				}
				catch is ExpectedError {
					// expected error thrown
				}
			},
			file: file,
			line: line
		)
	}

	@inline(__always)
	internal final func test<Returned>(
		timeout: TimeInterval,
		preparation: @escaping (FeatureTestPreparation, @escaping @Sendable () -> Void) -> Void,
		executedPrepared expectedExecutionCount: UInt,
		execute: @escaping (TestFeatures) async throws -> Returned,
		file: StaticString,
		line: UInt
	) {
		let executedCount: CriticalSection<UInt> = .init(0)
		self.test(
			timeout: timeout,
			preparation: { (testPreparation: FeatureTestPreparation) in
				preparation(
					testPreparation
				) {
					executedCount.access { (count: inout UInt) -> Void in
						count += 1
					}
				}
			},
			execute: { (testFeatures: TestFeatures) throws -> Void in
				_ = try await execute(testFeatures)
				XCTAssertEqual(
					executedCount.access(\.self),
					expectedExecutionCount,
					"Executed count is not matching expected.",
					file: file,
					line: line
				)
			},
			file: file,
			line: line
		)
	}

	@inline(__always)
	internal final func test<Returned, Argument>(
		timeout: TimeInterval,
		preparation: @escaping (FeatureTestPreparation, @escaping @Sendable (Argument) -> Void) -> Void,
		executedPreparedUsing expectedArgument: Argument,
		execute: @escaping (TestFeatures) async throws -> Returned,
		file: StaticString,
		line: UInt
	) where Argument: Equatable {
		let usedArgument: CriticalSection<Argument?> = .init(.none)
		self.test(
			timeout: timeout,
			preparation: { (testPreparation: FeatureTestPreparation) in
				preparation(
					testPreparation
				) { (argument: Argument) in
					usedArgument.access { (used: inout Argument?) -> Void in
						used = argument
					}
				}
			},
			execute: { (testFeatures: TestFeatures) throws -> Void in
				_ = try await execute(testFeatures)
				XCTAssertEqual(
					usedArgument.access(\.self),
					expectedArgument,
					"Executed using argument not matching expected.",
					file: file,
					line: line
				)
			},
			file: file,
			line: line
		)
	}
}
