#if DEBUG
	import MQ

	public struct AsyncExecutorControl {

		private struct State {

			fileprivate var queue: Array<ScheduledAsyncExecution> = .init()
			fileprivate var executionAwaiters: Dictionary<AsyncExecutionIdentifier, Array<CheckedContinuation<Void, Never>>> =
				.init()
		}

		private let state: CriticalSection<State> = .init(.init())

		public init() {}
	}

	extension AsyncExecutorControl {

		@discardableResult public func executeNext() async -> Bool {
			if let next: ScheduledAsyncExecution = self.pickNextScheduled() {
				await next.execute()
				return true
			}
			else {
				return false
			}
		}

		@discardableResult public func executeAll() async -> UInt {
			var counter: UInt = 0
			while let next: ScheduledAsyncExecution = self.pickNextScheduled() {
				await next.execute()
				counter += 1
			}
			return counter
		}
	}

	extension AsyncExecutorControl {

		@Sendable private func pickNextScheduled() -> ScheduledAsyncExecution? {
			self.state.access { (state: inout State) -> ScheduledAsyncExecution? in
				if state.queue.isEmpty {
					return .none
				}
				else {
					return state.queue.removeFirst()
				}
			}
		}

		@Sendable private func waitForCompletionOfTask(
			with identifier: AsyncExecutionIdentifier
		) async {
			await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
				self.state.access { (state: inout State) in
					guard var awaiters: Array<CheckedContinuation<Void, Never>> = state.executionAwaiters[identifier]
					else {
						InternalInconsistency
							.error(message: "Invalid executor state - trying to wait for nonexisting task.")
							.asFatalError()
					}
					awaiters.append(continuation)
					state.executionAwaiters[identifier] = awaiters
				}
			}
		}

		@Sendable private func completeTask(
			with identifier: AsyncExecutionIdentifier
		) {
			let awaiters: Array<CheckedContinuation<Void, Never>> = self.state.access { (state: inout State) in
				guard let awaiters: Array<CheckedContinuation<Void, Never>> = state.executionAwaiters[identifier]
				else {
					InternalInconsistency
						.error(message: "Invalid executor state - trying to complete nonexisting task.")
						.asFatalError()
				}
				defer { state.executionAwaiters[identifier] = .none }
				return awaiters
			}

			for awaiter in awaiters {
				awaiter.resume()
			}
		}

		@Sendable private func cancelTask(
			with identifier: AsyncExecutionIdentifier
		) {
			let awaiters: Array<CheckedContinuation<Void, Never>> = self.state.access { (state: inout State) in
				state.queue
					.removeAll(
						where: { (scheduledExecution: ScheduledAsyncExecution) -> Bool in
							scheduledExecution.execution.identifier == identifier
						}
					)

				guard let awaiters: Array<CheckedContinuation<Void, Never>> = state.executionAwaiters[identifier]
				else { return .init() }

				defer { state.executionAwaiters[identifier] = .none }
				return awaiters
			}

			for awaiter in awaiters {
				awaiter.resume()
			}
		}
	}

	extension AsyncExecutorControl {

		@Sendable internal func addTask(
			_ task: @escaping @Sendable () async -> Void,
			withIdentifier identifier: AsyncExecutionIdentifier
		) -> AsyncExecution {
			self.state.access { (state: inout State) -> AsyncExecution in
				let execution: AsyncExecution = .init(
					identifier: identifier,
					cancellation: {
						self.cancelTask(with: identifier)
					},
					completion: {
						await self.waitForCompletionOfTask(with: identifier)
					}
				)

				state.executionAwaiters[identifier] = .init()
				state.queue
					.append(
						.init(
							execution: execution,
							execute: {
								await task()
								self.completeTask(with: identifier)
							}
						)
					)

				return execution
			}
		}

		@Sendable internal func addOrReplaceTask(
			_ task: @escaping @Sendable () async -> Void,
			withIdentifier identifier: AsyncExecutionIdentifier
		) -> AsyncExecution {
			self.state.access { (state: inout State) -> AsyncExecution in
				let scheduledMatching: Array<ScheduledAsyncExecution> = state.queue
					.filter { (scheduledExecution: ScheduledAsyncExecution) -> Bool in
						scheduledExecution.execution.identifier.schedulerIdentifier == identifier.schedulerIdentifier
					}

				for scheduled in scheduledMatching {
					for awaiter in state.executionAwaiters[scheduled.execution.identifier] ?? .init() {
						awaiter.resume()
					}
					state.executionAwaiters[scheduled.execution.identifier] = .none
				}

				state.queue
					.removeAll(
						where: { (scheduledExecution: ScheduledAsyncExecution) -> Bool in
							scheduledExecution.execution.identifier.schedulerIdentifier == identifier.schedulerIdentifier
						}
					)

				let execution: AsyncExecution = .init(
					identifier: identifier,
					cancellation: {
						self.cancelTask(with: identifier)
					},
					completion: {
						await self.waitForCompletionOfTask(with: identifier)
					}
				)

				state.executionAwaiters[identifier] = .init()
				state.queue
					.append(
						.init(
							execution: execution,
							execute: {
								await task()
								self.completeTask(with: identifier)
							}
						)
					)

				return execution
			}
		}

		@Sendable internal func addOrReuseTask(
			_ task: @escaping @Sendable () async -> Void,
			withIdentifier identifier: AsyncExecutionIdentifier
		) -> AsyncExecution {
			self.state.access { (state: inout State) -> AsyncExecution in
				if let existing: ScheduledAsyncExecution = state.queue.first(where: {
					$0.execution.identifier.schedulerIdentifier == identifier.schedulerIdentifier
				}) {
					return existing.execution
				}
				else {
					let execution: AsyncExecution = .init(
						identifier: identifier,
						cancellation: {
							self.cancelTask(with: identifier)
						},
						completion: {
							await self.waitForCompletionOfTask(with: identifier)
						}
					)

					state.executionAwaiters[identifier] = .init()
					state.queue
						.append(
							.init(
								execution: execution,
								execute: {
									await task()
									self.completeTask(with: identifier)
								}
							)
						)

					return execution
				}
			}
		}
	}
#endif
