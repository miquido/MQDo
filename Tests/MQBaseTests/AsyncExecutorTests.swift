import XCTest

@testable import MQBase

final class AsyncExecutorTests: XCTestCase {

	let timeout: TimeInterval = 0.3
	let iterations: UInt = 10
	let mockFunction: StaticString = "function"
	let mockFile: StaticString = "file"
	let mockLine: UInt = 0
	var executor: AsyncExecutor!
	var counter: CriticalSection<UInt>!

	override func setUp() {
		executor = .system()
		counter = .init(0)
	}

	func test_deinit_cancelsRunningTasks() async throws {
		let expectation_1: XCTestExpectation = expectation(
			description: "Test completes in required time of \(timeout)s."
		)
		executor.execute {
			self.counter.access { counter in
				counter += 1
			}
			do {
				try await Task.sleep(nanoseconds: .max)
			}
			catch is CancellationError {
				// expected
			}
			catch {
				XCTFail("Unexpected error")
			}
			expectation_1.fulfill()
		}

		let expectation_2: XCTestExpectation = expectation(
			description: "Test completes in required time of \(timeout)s."
		)
		executor.executeReusingCurrent {
			self.counter.access { counter in
				counter += 1
			}
			do {
				try await Task.sleep(nanoseconds: .max)
			}
			catch is CancellationError {
				// expected
			}
			catch {
				XCTFail("Unexpected error")
			}
			expectation_2.fulfill()
		}

		let expectation_3: XCTestExpectation = expectation(
			description: "Test completes in required time of \(timeout)s."
		)
		executor.executeReplacingCurrent {
			self.counter.access { counter in
				counter += 1
			}
			do {
				try await Task.sleep(nanoseconds: .max)
			}
			catch is CancellationError {
				// expected
			}
			catch {
				XCTFail("Unexpected error")
			}
			expectation_3.fulfill()
		}

		try await Task.sleep(nanoseconds: NSEC_PER_MSEC * 10)
		self.executor = .none

		await waitForExpectations(timeout: timeout)
		XCTAssertEqual(
			self.counter.access(\.self),
			3
		)
	}

	func test_execute_executesMultipleTasksAtTheSameTime() {
		for _ in 0..<self.iterations {
			let expectation: XCTestExpectation = expectation(
				description: "Test completes in required time of \(timeout)s."
			)
			executor.execute {
				do {
					try await Task.sleep(nanoseconds: NSEC_PER_MSEC * 10)
					self.counter.access { counter in
						counter += 1
					}
				}
				catch is CancellationError {
					XCTFail("Task cancelled")
				}
				catch {
					XCTFail("Unexpected error")
				}
				expectation.fulfill()
			}
		}

		waitForExpectations(timeout: timeout)
		XCTAssertEqual(
			self.counter.access(\.self),
			self.iterations
		)
	}

	func test_executeReusingCurrent_reusesRunningTaskIgnoringOther() {
		let expectation: XCTestExpectation = expectation(
			description: "Test completes in required time of \(timeout)s."
		)
		executor.executeReusingCurrent(
			function: mockFunction,
			file: mockFile,
			line: mockLine
		) {
			do {
				try await Task.sleep(nanoseconds: NSEC_PER_MSEC * 10 * UInt64(self.iterations))
				self.counter.access { counter in
					counter += 1
				}
			}
			catch is CancellationError {
				XCTFail("Task cancelled")
			}
			catch {
				XCTFail("Unexpected error")
			}
			expectation.fulfill()
		}

		for _ in 0..<self.iterations {
			executor.executeReusingCurrent(
				function: mockFunction,
				file: mockFile,
				line: mockLine
			) {
				XCTFail("Task should not be executed")
				self.counter.access { counter in
					counter += 1
				}
			}
		}

		waitForExpectations(timeout: timeout)
		XCTAssertEqual(
			self.counter.access(\.self),
			1
		)
	}

	func test_executeReplacingCurrent_replacesRunningTasksAndExecutesLast() {

		for _ in 0..<self.iterations {
			executor.executeReplacingCurrent(
				function: mockFunction,
				file: mockFile,
				line: mockLine
			) {
				do {
					try await Task.sleep(nanoseconds: NSEC_PER_MSEC * 10 * UInt64(self.iterations))
					XCTFail("Task should be cancelled")
					self.counter.access { counter in
						counter += 1
					}
				}
				catch is CancellationError {
					// expected
				}
				catch {
					XCTFail("Unexpected error")
				}
			}
		}

		let expectation: XCTestExpectation = expectation(
			description: "Test completes in required time of \(timeout)s."
		)
		executor.executeReplacingCurrent(
			function: mockFunction,
			file: mockFile,
			line: mockLine
		) {
			self.counter.access { counter in
				counter += 1
			}
			expectation.fulfill()
		}

		waitForExpectations(timeout: timeout)
		XCTAssertEqual(
			self.counter.access(\.self),
			1
		)
	}
}
