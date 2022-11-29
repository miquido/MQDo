import XCTest

@testable import MQBase

final class MockAsyncExecutorTests: XCTestCase {

	let iterations: UInt = 10
	let mockFunction: StaticString = "function"
	let mockFile: StaticString = "file"
	let mockLine: UInt = 0
	var executor: AsyncExecutor!
	var executorControl: AsyncExecutorControl!
	var counter: CriticalSection<UInt>!

	override func setUp() {
		self.executorControl = .init()
		self.executor = .mock(using: self.executorControl)
		self.counter = .init(0)
	}

	func test_execute_schedulesMultipleTasks() async {
		for _ in 0..<self.iterations {
			executor.execute {
				do {
					try await Task.sleep(nanoseconds: NSEC_PER_MSEC * 10)
					self.counter.access { counter in
						counter += 1
					}
				}
				catch {
					XCTFail("Task cancelled")
				}
			}
		}

		await executorControl.executeAll()
		XCTAssertEqual(
			self.counter.access(\.self),
			self.iterations
		)
	}

	func test_executeReusingCurrent_reusesScheduledTaskIgnoringOther() async {
		executor.executeReusingCurrent(
			function: mockFunction,
			file: mockFile,
			line: mockLine
		) {
			self.counter.access { counter in
				counter += 1
			}
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

		await executorControl.executeAll()
		XCTAssertEqual(
			self.counter.access(\.self),
			1
		)
	}

	func test_executeReplacingCurrent_replacesScheduledTasksAndExecutesLast() async {

		for _ in 0..<self.iterations {
			executor.executeReplacingCurrent(
				function: mockFunction,
				file: mockFile,
				line: mockLine
			) {
				do {
					try await Task.sleep(nanoseconds: NSEC_PER_MSEC * 10 * UInt64(self.iterations))
					XCTFail("Task should be cancelled")
				}
				catch is CancellationError {
					// expected
				}
				catch {
					XCTFail("Unexpected error")
				}
			}
		}

		executor.executeReplacingCurrent(
			function: mockFunction,
			file: mockFile,
			line: mockLine
		) {
			self.counter.access { counter in
				counter += 1
			}
		}

		await executorControl.executeAll()
		XCTAssertEqual(
			self.counter.access(\.self),
			1
		)
	}
}
