import MQDo

// MARK: - Interface

public struct AsyncExecutor {

	fileprivate let schedule: @Sendable (@escaping @Sendable () async -> Void) -> AsyncExecution
	fileprivate let scheduleReplacing:
		@Sendable (AsyncExecutionIdentifier, @escaping @Sendable () async -> Void) -> AsyncExecution
	fileprivate let scheduleReusing:
		@Sendable (AsyncExecutionIdentifier, @escaping @Sendable () async -> Void) -> AsyncExecution
}

extension AsyncExecutor {

	@discardableResult public func execute(
		_ task: @escaping @Sendable () async -> Void
	) -> AsyncExecution {
		self.schedule(task)
	}

	@discardableResult public func executeReplacingCurrent(
		function: StaticString = #function,
		file: StaticString = #fileID,
		line: UInt = #line,
		_ task: @escaping @Sendable () async -> Void
	) -> AsyncExecution {
		self.scheduleReplacing(
			.contextual(
				function: function,
				file: file,
				line: line
			),
			task
		)
	}

	@discardableResult public func executeReusingCurrent(
		function: StaticString = #function,
		file: StaticString = #fileID,
		line: UInt = #line,
		_ task: @escaping @Sendable () async -> Void
	) -> AsyncExecution {
		self.scheduleReusing(
			.contextual(
				function: function,
				file: file,
				line: line
			),
			task
		)
	}
}

extension AsyncExecutor: DisposableFeature {

	public nonisolated static var placeholder: Self {
		.init(
			schedule: unimplemented1(),
			scheduleReplacing: unimplemented2(),
			scheduleReusing: unimplemented2()
		)
	}
}

// MARK: - Implementation

extension AsyncExecutor {

	internal static func system() -> FeatureLoader {
		SystemAsyncExecutor.loader()
	}
}

public struct SystemAsyncExecutor: ImplementationOfDisposableFeature {

	private let executionState: CriticalSection<Dictionary<AsyncExecutionIdentifier, ScheduledAsyncExecution>>

	public init() {
		self.executionState = .init(
			.init(),
			cleanup: { (executionState: Dictionary<AsyncExecutionIdentifier, ScheduledAsyncExecution>) in
				for scheduledExecution in executionState.values {
					scheduledExecution.execution.cancel()
				}
			}
		)
	}
	public init(
		with context: Void,
		using features: Features
	) throws {
		self.init()
	}

	public var instance: AsyncExecutor {
		.init(
			schedule: self.schedule(_:),
			scheduleReplacing: self.scheduleReplacing(_:_:),
			scheduleReusing: self.scheduleReusing(_:_:)
		)
	}
}

extension SystemAsyncExecutor {

	@Sendable public func schedule(
		_ task: @escaping @Sendable () async -> Void
	) -> AsyncExecution {
		let executionIdentifier: AsyncExecutionIdentifier = .empty()
		let task: @Sendable () async -> Void = {
			await task()
			self.executionState.access {
				(executionState: inout Dictionary<AsyncExecutionIdentifier, ScheduledAsyncExecution>) in
				executionState[executionIdentifier] = .none
			}
		}

		return self.executionState.access {
			(executionState: inout Dictionary<AsyncExecutionIdentifier, ScheduledAsyncExecution>) -> AsyncExecution in
			let runningTask: Task<Void, Never> = .init {
				await task()
			}
			let execution: AsyncExecution = .init(
				identifier: executionIdentifier,
				cancellation: { runningTask.cancel() },
				completion: { await runningTask.value }
			)
			executionState[executionIdentifier] = .init(
				execution: execution,
				execute: task
			)
			return execution
		}
	}

	@Sendable public func scheduleReplacing(
		_ executionIdentifier: AsyncExecutionIdentifier,
		_ task: @escaping @Sendable () async -> Void
	) -> AsyncExecution {
		self.executionState.access {
			(state: inout Dictionary<AsyncExecutionIdentifier, ScheduledAsyncExecution>) -> AsyncExecution in
			let runningExecutionIdentifiers: Array<AsyncExecutionIdentifier> = state.keys.filter({
				$0.schedulerIdentifier == executionIdentifier.schedulerIdentifier
			})

			for identifier in runningExecutionIdentifiers {
				state[identifier]?.execution.cancel()
			}
			let task: @Sendable () async -> Void = {
				await task()
				self.executionState.access {
					(executionState: inout Dictionary<AsyncExecutionIdentifier, ScheduledAsyncExecution>) in
					executionState[executionIdentifier] = .none
				}
			}

			let runningTask: Task<Void, Never> = .init {
				await task()
			}
			let execution: AsyncExecution = .init(
				identifier: executionIdentifier,
				cancellation: { runningTask.cancel() },
				completion: { await runningTask.value }
			)
			state[executionIdentifier] = .init(
				execution: execution,
				execute: task
			)
			return execution
		}
	}

	@Sendable public func scheduleReusing(
		_ executionIdentifier: AsyncExecutionIdentifier,
		_ task: @escaping @Sendable () async -> Void
	) -> AsyncExecution {
		self.executionState.access {
			(state: inout Dictionary<AsyncExecutionIdentifier, ScheduledAsyncExecution>) -> AsyncExecution in
			if let runningExecutionIdentifier: AsyncExecutionIdentifier = state.keys.first(where: {
				$0.schedulerIdentifier == executionIdentifier.schedulerIdentifier
			}),
				let runningExecution: AsyncExecution = state[runningExecutionIdentifier]?.execution
			{
				return runningExecution
			}
			else {
				let task: @Sendable () async -> Void = {
					await task()
					self.executionState.access {
						(executionState: inout Dictionary<AsyncExecutionIdentifier, ScheduledAsyncExecution>) in
						executionState[executionIdentifier] = .none
					}
				}

				let runningTask: Task<Void, Never> = .init {
					await task()
				}
				let execution: AsyncExecution = .init(
					identifier: executionIdentifier,
					cancellation: { runningTask.cancel() },
					completion: { await runningTask.value }
				)
				state[executionIdentifier] = .init(
					execution: execution,
					execute: task
				)
				return execution
			}
		}
	}
}

#if DEBUG
	extension AsyncExecutor {

		public static func mock(
			using control: AsyncExecutorControl
		) -> Self {

			@Sendable func schedule(
				_ task: @escaping @Sendable () async -> Void
			) -> AsyncExecution {
				control.addTask(task, withIdentifier: .empty())
			}

			@Sendable func scheduleReplacing(
				_ identifier: AsyncExecutionIdentifier,
				_ task: @escaping @Sendable () async -> Void
			) -> AsyncExecution {
				control.addOrReplaceTask(task, withIdentifier: identifier)
			}

			@Sendable func scheduleReusing(
				_ identifier: AsyncExecutionIdentifier,
				_ task: @escaping @Sendable () async -> Void
			) -> AsyncExecution {
				control.addOrReuseTask(task, withIdentifier: identifier)
			}

			return .init(
				schedule: schedule(_:),
				scheduleReplacing: scheduleReplacing(_:_:),
				scheduleReusing: scheduleReusing(_:_:)
			)
		}
	}
#endif
