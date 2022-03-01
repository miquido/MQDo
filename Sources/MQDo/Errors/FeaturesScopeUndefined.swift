/// ``TheError`` for undefined feature scopes.
///
/// ``FeaturesScopeUndefined`` error can occur when asking for a features scope
/// which was not defined for given features tree.
public struct FeaturesScopeUndefined: TheError {

	/// Create instance of ``FeaturesScopeUndefined`` error.
	///
	/// - Parameters
	///   - message: Message associated with this error.
	///   Default value is "FeaturesScopeUndefined".
	///   - scope: Type of a undefined scope.
	///   - file: Source code file identifier.
	///   Filled automatically based on compile time constants.
	///   - line: Line in given source code file.
	///   Filled automatically based on compile time constants.
	/// - Returns: New instance of ``FeatureUnimplemented`` error with given context.
	public static func error(
		message: StaticString = "FeaturesScopeUndefined",
		scope: FeaturesScope.Type,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self {
		Self(
			context: .context(
				message: message,
				file: file,
				line: line
			)
			.with(scope, for: "undefined scope")
		)
	}

	/// Source code context of this error.
	public var context: SourceCodeContext
}
