#if DEBUG
	import MQBase
	import XCTest

	@MainActor
	open class FeatureTests: XCTestCase {

		public final override class func setUp() {
			super.setUp()
			runtimeAssertionMethod = { _, _, _, _ in }
		}

		open var commonPreparation: (FeatureTestPreparation) -> Void = { (_: FeatureTestPreparation) -> Void in /* noop */
		}

		public final let asyncExecutorControl: AsyncExecutorControl = .init()

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
			XCTAssertTrue(self.asyncExecutorControl.isEmpty)
		}
	}
#endif
