import MQ

public struct DeferredInstance<Feature> {

	private enum State {

		case instance(Feature)
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
				case let .instance(feature):
					return feature

				case let .pending(load):
					let instance: Feature = try load()
					state = .instance(instance)
					return instance
				}
			}
		}
	}
}

extension DeferredInstance: Sendable {}
