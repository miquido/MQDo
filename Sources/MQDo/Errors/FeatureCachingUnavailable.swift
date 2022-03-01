/// ``TheError`` for features which does not support caching.
///
/// ``FeatureCachingUnavailable`` error can occur when asking to use a cache
///  with a feature which implementation does not support caching.
public struct FeatureCachingUnavailable: TheError {

	/// Create instance of ``FeatureCachingUnavailable`` error.
	///
	/// - Parameters
	///   - message: Message associated with this error.
	///   Default value is "FeatureCachingUnavailable".
	///   - feature: Type of a unavailable feature.
	///   - file: Source code file identifier.
	///   Filled automatically based on compile time constants.
	///   - line: Line in given source code file.
	///   Filled automatically based on compile time constants.
	/// - Returns: New instance of ``FeatureCachingUnavailable`` error with given context.
	public static func error(
		message: StaticString = "FeatureCachingUnavailable",
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
			.with(feature, for: "feature")
		)
	}

	/// Source code context of this error.
	public var context: SourceCodeContext
}
