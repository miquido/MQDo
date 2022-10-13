/// ``TheError`` for features which failed to load.
///
/// ``FeatureLoadingFailed`` error can occur when asking for an instance
///  of a feature which failed loading properly.
public struct FeatureLoadingFailed: TheError {

	/// Create instance of ``FeatureLoadingFailed`` error.
	///
	/// - Parameters
	///   - message: Message associated with this error.
	///   Default value is "FeatureLoadingFailed".
	///   - feature: Type of a unavailable feature.
	///   - cause: Error causing loading failure.
	///   - file: Source code file identifier.
	///   Filled automatically based on compile time constants.
	///   - line: Line in given source code file.
	///   Filled automatically based on compile time constants.
	/// - Returns: New instance of ``FeatureLoadingFailed`` error with given context.
	public static func error(
		message: StaticString = "FeatureLoadingFailed",
		feature: Any.Type,
		cause: TheError,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self {
		Self(
			context: .merging(
				cause.context,
				.context(
					message: message,
					file: file,
					line: line
				)
			)
			.with(feature, for: "feature"),
			cause: cause
		)
	}

	/// Source code context of this error.
	public var context: SourceCodeContext
	/// Cause of loading failure.
	public var cause: TheError
}
