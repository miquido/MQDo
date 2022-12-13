public struct AsyncExecution {

	internal let identifier: AsyncExecutionIdentifier
	private let cancellation: @Sendable () -> Void
	private let completion: @Sendable () async -> Void

	internal init(
		identifier: AsyncExecutionIdentifier,
		cancellation: @escaping @Sendable () -> Void,
		completion: @escaping @Sendable () async -> Void
	) {
		self.identifier = identifier
		self.cancellation = cancellation
		self.completion = completion
	}
}

extension AsyncExecution: Hashable {

	public static func == (
		_ lhs: AsyncExecution,
		_ rhs: AsyncExecution
	) -> Bool {
		lhs.identifier == rhs.identifier
	}

	public func hash(
		into hasher: inout Hasher
	) {
		hasher.combine(self.identifier)
	}
}
extension AsyncExecution: Sendable {}

extension AsyncExecution {

	@Sendable public func cancel() {
		self.cancellation()
	}

	@Sendable public func waitForCompletion() async {
		await self.completion()
	}
}
