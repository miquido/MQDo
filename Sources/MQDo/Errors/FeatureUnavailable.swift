/// ``TheError`` for unavailable features.
///
/// ``FeatureUnavailable`` error can occur when asking for a feature
/// which implementation or its part is not available due to application state.
public struct FeatureUnavailable: TheError {

	/// Create instance of ``FeatureUnavailable`` error.
	///
	/// - Parameters
	///   - message: Message associated with this error.
	///   Default value is "FeatureUnavailable".
	///   - displayableMessage: Message which can be displayed
	///   to the end user. Default is based on ``TheErrorDisplayableMessages``.
	///   - feature: Type of a unavailable feature.
	///   - file: Source code file identifier.
	///   Filled automatically based on compile time constants.
	///   - line: Line in given source code file.
	///   Filled automatically based on compile time constants.
	/// - Returns: New instance of ``FeatureUnavailable`` error with given context.
	public static func error(
		message: StaticString = "FeatureUnavailable",
		displayableMessage: DisplayableString = TheErrorDisplayableMessages.message(for: Self.self),
		feature: AnyFeature.Type,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self {
		Self(
			context: .context(
				message: message,
				file: file,
				line: line
			)
			.with(feature, for: "feature"),
			displayableMessage: displayableMessage
		)
	}

	/// Source code context of this error.
	public var context: SourceCodeContext
	/// String representation displayable to the end user.
	public var displayableMessage: DisplayableString
}
