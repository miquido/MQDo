public final class AsyncExecutionIdentifier {

	// identifier used for scheduling work
	// it is NOT used for equality check
	// each different instance is treated
	// as unique for equality check (reference check)
	internal let schedulerIdentifier: String

	fileprivate init(
		schedulerIdentifier: String
	) {
		self.schedulerIdentifier = schedulerIdentifier
	}
}

extension AsyncExecutionIdentifier: Sendable {}

extension AsyncExecutionIdentifier: Hashable {

	public static func == (
		_ lhs: AsyncExecutionIdentifier,
		_ rhs: AsyncExecutionIdentifier
	) -> Bool {
		lhs === rhs
	}

	public func hash(
		into hasher: inout Hasher
	) {
		hasher.combine(self.schedulerIdentifier)
	}
}

extension AsyncExecutionIdentifier {

	public static func contextual(
		function: StaticString,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self {
		.init(
			schedulerIdentifier: "\(file):\(function):\(line)"
		)
	}

	public static func explicit(
		_ identifier: String
	) -> Self {
		.init(
			schedulerIdentifier: identifier
		)
	}

	internal static func empty() -> Self {
		.init(
			schedulerIdentifier: ""
		)
	}
}
