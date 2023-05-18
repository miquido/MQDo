import MQDummy
import XCTest

@MainActor
open class FeatureTests: XCTestCase {

	open func commonPatches(
		_ patches: FeaturePatches
	) {
		/* noop - to be overriden */
	}

	public final override class func setUp() {
		super.setUp()
		runtimeAssertionMethod = { _, _, _, _ in }
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

	public final func test(
		patches: @escaping (FeaturePatches) -> Void,
		execute: @escaping (DummyFeatures) async throws -> Void,
		file: StaticString = #filePath,
		line: UInt = #line
	) async {
		do {
			let testFeatures: DummyFeatures = .init()
			let testPatches: FeaturePatches = .init(
				using: testFeatures
			)
			self.commonPatches(testPatches)
			patches(testPatches)
			try await execute(testFeatures)
		}
		catch {
			XCTFail(
				"Unexpected error thrown: \(error)",
				file: (file),
				line: line
			)
		}
	}

	public final func test<Returned>(
		patches: @escaping (FeaturePatches) -> Void,
		returnsEqual expected: Returned,
		execute: @escaping (DummyFeatures) async throws -> Returned,
		file: StaticString = #filePath,
		line: UInt = #line
	) async where Returned: Equatable {
		await self.test(
			patches: patches,
			execute: { (testFeatures: DummyFeatures) throws -> Void in
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

	public final func test<Returned, ExpectedError>(
		patches: @escaping (FeaturePatches) -> Void,
		throws expected: ExpectedError.Type,
		execute: @escaping (DummyFeatures) async throws -> Returned,
		file: StaticString = #filePath,
		line: UInt = #line
	) async where ExpectedError: Error {
		await self.test(
			patches: patches,
			execute: { (testFeatures: DummyFeatures) throws -> Void in
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

	public final func test<Returned>(
		patches: @escaping (FeaturePatches, @escaping @Sendable () -> Void) -> Void,
		executedPrepared expectedExecutionCount: UInt,
		execute: @escaping (DummyFeatures) async throws -> Returned,
		file: StaticString = #filePath,
		line: UInt = #line
	) async {
		let executedCount: CriticalSection<UInt> = .init(0)
		await self.test(
			patches: { (testPreparation: FeaturePatches) in
				patches(
					testPreparation
				) {
					executedCount.access { (count: inout UInt) -> Void in
						count += 1
					}
				}
			},
			execute: { (testFeatures: DummyFeatures) throws -> Void in
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

	public final func test<Returned, Argument>(
		patches: @escaping (FeaturePatches, @escaping @Sendable (Argument) -> Void) -> Void,
		executedPreparedUsing expectedArgument: Argument,
		execute: @escaping (DummyFeatures) async throws -> Returned,
		file: StaticString = #filePath,
		line: UInt = #line
	) async where Argument: Equatable {
		let usedArgument: CriticalSection<Argument?> = .init(.none)
		await self.test(
			patches: { (testPreparation: FeaturePatches) in
				patches(
					testPreparation
				) { (argument: Argument) in
					usedArgument.access { (used: inout Argument?) -> Void in
						used = argument
					}
				}
			},
			execute: { (testFeatures: DummyFeatures) throws -> Void in
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
