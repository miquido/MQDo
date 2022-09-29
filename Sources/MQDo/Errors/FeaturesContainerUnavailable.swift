/// ``TheError`` for unavailable feature containers access.
///
/// ``FeaturesContainerUnavailable`` error can occur when using
/// features container which has been deallocated.
public struct FeaturesContainerUnavailable: TheError {

	/// Create instance of ``FeaturesContainerUnavailable`` error.
	///
	/// - Parameters
	///   - message: Message associated with this error.
	///   Default value is "FeaturesContainerUnavailable".
	///   - displayableMessage: Message which can be displayed
	///   to the end user. Default is based on ``TheErrorDisplayableMessages``.
	///   - file: Source code file identifier.
	///   Filled automatically based on compile time constants.
	///   - line: Line in given source code file.
	///   Filled automatically based on compile time constants.
	/// - Returns: New instance of ``FeaturesContainerUnavailable`` error with given context.
	public static func error(
		message: StaticString = "FeaturesContainerUnavailable",
		displayableMessage: DisplayableString = TheErrorDisplayableMessages.message(for: Self.self),
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self {
		Self(
			context: .context(
				message: message,
				file: file,
				line: line
			),
			displayableMessage: displayableMessage
		)
	}

	/// Source code context of this error.
	public var context: SourceCodeContext
	/// String representation displayable to the end user.
	public var displayableMessage: DisplayableString
}
