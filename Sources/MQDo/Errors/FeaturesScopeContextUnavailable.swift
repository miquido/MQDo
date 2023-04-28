/// ``TheError`` for unavailable feature scopes contexts.
///
/// ``FeaturesScopeContextUnavailable`` error can occur when asking for a features scope context
/// which was not present in a given features tree or
/// not available due to some other reason.
public struct FeaturesScopeContextUnavailable: TheError {

	/// Create instance of ``FeaturesScopeContextUnavailable`` error.
	///
	/// - Parameters
	///   - message: Message associated with this error.
	///   Default value is "FeaturesScopeContextUnavailable".
	///   - scope: Type of a undefined scope.
	///   - file: Source code file identifier.
	///   Filled automatically based on compile time constants.
	///   - line: Line in given source code file.
	///   Filled automatically based on compile time constants.
	/// - Returns: New instance of ``FeaturesScopeContextUnavailable`` error with given context.
	public static func error<Scope>(
		message: StaticString = "FeaturesScopeContextUnavailable",
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
				.with(scope, for: "unavailable scope context")
		)
	}

	/// Source code context of this error.
	public var context: SourceCodeContext
}
