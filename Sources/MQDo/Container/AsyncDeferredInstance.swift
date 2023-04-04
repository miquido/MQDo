import MQ

public final actor AsyncDeferredInstance<Feature> {

	private enum State {

		case loaded(Result<Feature, Error>)
		case loading(Task<Feature, Error>)
		case pending(@Sendable () async throws -> Feature)
	}

	private var state: State

	internal init(
		_ load: @escaping @Sendable () async throws -> Feature
	) {
		self.state = .pending(load)
	}

	public var instance: Feature {
		get async throws {
			switch state {
			case let .loaded(result):
				return try result.get()

			case let .loading(task):
				return try await task.value

			case let .pending(load):
				let loadingTask: Task<Feature, Error> = .init {
					try await load()
				}
				state = .loading(loadingTask)
				do {
					let feature: Feature = try await loadingTask.value
					self.state = .loaded(.success(feature))
					return feature
				}
				catch {
					self.state = .loaded(.failure(error))
					throw error
				}
			}
		}
	}
}

extension AsyncDeferredInstance: Sendable {}
