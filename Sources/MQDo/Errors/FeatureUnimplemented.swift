/// ``TheError`` for unimplemented features.
///
/// ``FeatureUnimplemented`` error can occur when asking for a feature
/// or a function which implementation is not implemented for current application state.
/// ``FeatureUnimplemented`` is an error for known, registered features
/// which happen to have no implementation. It can be used to define placeholders.
public struct FeatureUnimplemented: TheError {

	/// Create instance of ``FeatureUnimplemented`` error.
	///
	/// - Parameters
	///   - message: Message associated with this error.
	///   Default value is "FeatureUnimplemented".
	///   - feature: Type of a unimplemented feature.
	///   - file: Source code file identifier.
	///   Filled automatically based on compile time constants.
	///   - line: Line in given source code file.
	///   Filled automatically based on compile time constants.
	/// - Returns: New instance of ``FeatureUnimplemented`` error with given context.
	public static func error(
		message: StaticString = "FeatureUnimplemented",
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
