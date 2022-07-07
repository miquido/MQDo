import MQ

public struct LazyInstance<Feature>: Sendable
where Feature: AnyFeature {

	private enum State {

		case instance(Feature)
		case issue(TheError)
		case pending(@Sendable () throws -> Feature)
	}

	private let state: CriticalSection<State>
	#if DEBUG
		private let debugMeta: SourceCodeMeta
	#endif

	internal init(
		_ load: @escaping @Sendable () throws -> Feature,
		file: StaticString,
		line: UInt
	) {
		self.state = .init(
			.pending(load)
		)
		#if DEBUG
			self.debugMeta = .message(
				"LazyInstance",
				file: file,
				line: line
			)
		#endif
	}

	public var instance: Feature {
		get throws {
			try self.state.access { (state: inout State) throws -> Feature in
				switch state {
				case let .instance(feature):
					return feature

				case let .issue(error):
					throw error

				case let .pending(load):
					do {
						let instance: Feature = try load()
						state = .instance(instance)
						return instance
					}
					catch {
						#if DEBUG
							let theError: TheError =
								error
								.asTheError()
								.appending(self.debugMeta)
						#else
							let theError: TheError =
								error
								.asTheError()
						#endif

						state = .issue(theError)

						throw theError
					}
				}
			}
		}
	}
}
