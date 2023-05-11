/// ``TheError`` for unavailable feature scopes.
///
/// ``FeaturesScopeUnavailable`` error can occur when asking for a features scope
/// which was not present in a given features tree.
public struct FeaturesScopeUnavailable: TheError {

	/// Create instance of ``FeaturesScopeUnavailable`` error.
	///
	/// - Parameters
	///   - message: Message associated with this error.
	///   Default value is "FeaturesScopeUnavailable".
	///   - scope: Type of a undefined scope.
	///   - file: Source code file identifier.
	///   Filled automatically based on compile time constants.
	///   - line: Line in given source code file.
	///   Filled automatically based on compile time constants.
	/// - Returns: New instance of ``FeaturesScopeUnavailable`` error with given context.
	public static func error<Scope>(
		message: StaticString = "FeaturesScopeUnavailable",
		scope: Scope.Type,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self
	where Scope: FeaturesScope {
		Self(
			context:
				.context(
					message: message,
					file: file,
					line: line
				)
				.with(scope, for: "scope")
		)
	}

	/// Source code context of this error.
	public var context: SourceCodeContext
}
