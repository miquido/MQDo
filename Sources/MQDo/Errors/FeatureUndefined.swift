/// ``TheError`` for undefined features.
///
/// ``FeatureUndefined`` error can occur when asking for a feature
/// which implementation or its part is not defined.
/// ``FeatureUndefined`` is an error for unknown, not registered features.
public struct FeatureUndefined: TheError {

	/// Create instance of ``FeatureUndefined`` error.
	///
	/// - Parameters
	///   - message: Message associated with this error.
	///   Default value is "FeatureUndefined".
	///   - feature: Type of a undefined feature.
	///   - file: Source code file identifier.
	///   Filled automatically based on compile time constants.
	///   - line: Line in given source code file.
	///   Filled automatically based on compile time constants.
	/// - Returns: New instance of ``FeatureUndefined`` error with given context.
	public static func error(
		message: StaticString = "FeatureUndefined",
		feature: Any.Type,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self {
		Self(
			context: .context(
				message: message,
				file: file,
				line: line
			)
			.with(feature, for: "feature")
		)
	}

	/// Source code context of this error.
	public var context: SourceCodeContext
}
