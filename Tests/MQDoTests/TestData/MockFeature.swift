import MQDo

struct MockFeature {

	var mock: () -> Void
	var mockInt: () -> Int
	var mockString: () -> String
	var mockThrowing: () throws -> Void
}

extension MockFeature: LoadableFeature {

	typealias Context = (
		mockInt: Int,
		mockString: String,
		mockError: TheError
	)

	static var placeholder: Self {
		Self(
			mock: unimplemented(),
			mockInt: unimplemented(),
			mockString: unimplemented(),
			mockThrowing: unimplemented()
		)
	}

	static var mock: Self {
		.init(
			mock: {},
			mockInt: always(42),
			mockString: always("mock"),
			mockThrowing: alwaysThrowing(MockError.error())
		)
	}
}

extension FeatureLoader where Feature == MockFeature {

	static func mock() -> Self {
		.lazyLoaded(
			load: { context, _ in
				Feature(
					mock: noop,
					mockInt: always(context.mockInt),
					mockString: always(context.mockString),
					mockThrowing: alwaysThrowing(context.mockError)
				)
			}
		)
	}
}
