import MQDo

// MARK: - Interface

public struct AsyncExecutor {

	private let schedule: @Sendable (@escaping @Sendable () async -> Void) -> AsyncExecution
	private let scheduleReplacing:
		@Sendable (AsyncExecutionIdentifier, @escaping @Sendable () async -> Void) -> AsyncExecution
	private let scheduleReusing:
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

	#if DEBUG
		public nonisolated static var placeholder: Self {
			.init(
				schedule: unimplemented(),
				scheduleReplacing: unimplemented(),
				scheduleReusing: unimplemented()
			)
		}
	#endif
}

// MARK: - Implementation

extension AsyncExecutor {

	internal static func system() -> Self {
		let executionState: CriticalSection<Dictionary<AsyncExecutionIdentifier, ScheduledAsyncExecution>> = .init(
			.init(),
			cleanup: { (executionState: Dictionary<AsyncExecutionIdentifier, ScheduledAsyncExecution>) in
				for scheduledExecution in executionState.values {
					scheduledExecution.execution.cancel()
				}
			}
		)

		@Sendable func schedule(
			_ task: @escaping @Sendable () async -> Void
		) -> AsyncExecution {
			let executionIdentifier: AsyncExecutionIdentifier = .empty()
			let task: @Sendable () async -> Void = {
				await task()
				executionState.access { (executionState: inout Dictionary<AsyncExecutionIdentifier, ScheduledAsyncExecution>) in
					executionState[executionIdentifier] = .none
				}
			}

			return executionState.access {
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

		@Sendable func scheduleReplacing(
			_ executionIdentifier: AsyncExecutionIdentifier,
			_ task: @escaping @Sendable () async -> Void
		) -> AsyncExecution {
			executionState.access {
				(state: inout Dictionary<AsyncExecutionIdentifier, ScheduledAsyncExecution>) -> AsyncExecution in
				let runningExecutionIdentifiers: Array<AsyncExecutionIdentifier> = state.keys.filter({
					$0.schedulerIdentifier == executionIdentifier.schedulerIdentifier
				})

				for identifier in runningExecutionIdentifiers {
					state[identifier]?.execution.cancel()
				}
				let task: @Sendable () async -> Void = {
					await task()
					executionState.access {
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

		@Sendable func scheduleReusing(
			_ executionIdentifier: AsyncExecutionIdentifier,
			_ task: @escaping @Sendable () async -> Void
		) -> AsyncExecution {
			executionState.access {
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
						executionState.access {
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

		return .init(
			schedule: schedule(_:),
			scheduleReplacing: scheduleReplacing(_:_:),
			scheduleReusing: scheduleReusing(_:_:)
		)
	}

	internal static func systemExecutor() -> some DisposableFeatureLoader<Self> {
		FeatureLoader
			.disposable(
				Self.self,
				load: { (_: Features) -> Self in
					system()
				}
			)
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
