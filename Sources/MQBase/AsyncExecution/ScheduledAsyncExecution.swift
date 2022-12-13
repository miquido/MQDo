internal struct ScheduledAsyncExecution {

	internal let execution: AsyncExecution
	internal let execute: @Sendable () async -> Void
}

extension ScheduledAsyncExecution: Sendable {}

extension ScheduledAsyncExecution: Hashable {

	internal static func == (
		_ lhs: ScheduledAsyncExecution,
		_ rhs: ScheduledAsyncExecution
	) -> Bool {
		lhs.execution == rhs.execution
	}

	internal func hash(
		into hasher: inout Hasher
	) {
		hasher.combine(self.execution)
	}
}
