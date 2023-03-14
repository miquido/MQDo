#if canImport(XCTest)

	import MQ
	import XCTest

	extension TheError {

		@discardableResult public func asTestFailure(
			file: StaticString = #file,
			line: UInt = #line
		) -> Self {
			XCTFail(
				self.debugDescription,
				file: file,
				line: line
			)
			return self
		}
	}

#endif
