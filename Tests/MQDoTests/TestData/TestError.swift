import MQ

struct TestError: TheError {

	static func error(
		message: StaticString = "TestError",
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self {
		Self(
			context: .context(
				message: message,
				file: file,
				line: line
			)
		)
	}

	var context: SourceCodeContext
}
