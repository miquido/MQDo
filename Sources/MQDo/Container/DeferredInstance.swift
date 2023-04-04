import MQ

public struct DeferredInstance<Feature> {

	private enum State {

		case loaded(Result<Feature, Error>)
		case pending(@Sendable () throws -> Feature)
	}

	private let state: CriticalSection<State>

	internal init(
		_ load: @escaping @Sendable () throws -> Feature
	) {
		self.state = .init(
			.pending(load)
		)
	}

	public var instance: Feature {
		get throws {
			try self.state.access { (state: inout State) throws -> Feature in
				switch state {
				case let .loaded(result):
					return try result.get()

				case let .pending(load):
					do {
						let instance: Feature = try load()
						state = .loaded(.success(instance))
						return instance
					}
					catch {
						state = .loaded(.failure(error))
						throw error
					}
				}
			}
		}
	}
}

extension DeferredInstance: Sendable {}
