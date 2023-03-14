import MQ

public struct DummyIssue: TheError, Hashable {

	public static func error(
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self {
		Self(
			context: .context(
				message: "DummyIssue",
				file: file,
				line: line
			)
		)
	}

	/// Source code context of this error.
	public var context: SourceCodeContext
}
