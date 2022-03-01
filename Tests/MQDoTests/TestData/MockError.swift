import MQ

struct MockError: TheError {

	static func error(
		message: StaticString = "MockError",
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
