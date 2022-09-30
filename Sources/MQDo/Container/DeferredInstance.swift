import MQ

/// Instance of a feature with deferred loading.
///
/// Instance of a feature which is not loaded immediately
/// but wrapped inside ``DeferredInstance`` box and loaded
/// when first time asked for an actual instance.
/// When loading feature succeeds ``DeferredInstance`` will
/// cache loaded instance, this is true for all types of
/// ``FeatureLoader`` (including disposable). If loading
/// fails error will be cached and returned instead of
/// an instance of feature.
public struct DeferredInstance<Feature>
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
				"DeferredInstance",
				file: file,
				line: line
			)
		#endif
	}

	/// Access lazily loaded instance of feature.
	///
	/// Accessing instance will trigger loading feature
	/// when accessed for the first time and might throw
	/// if loading fails.
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

extension DeferredInstance: Sendable {}
