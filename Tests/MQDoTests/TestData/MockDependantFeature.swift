import MQDo

struct MockDependantFeature {

	var mock: () -> Void
	var mockInt: () -> Int
	var mockString: () -> String
	var mockThrowing: () throws -> Void
}

extension MockDependantFeature: ContextlessLoadableFeature {

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

extension FeatureLoader where Feature == MockDependantFeature {

	static func mock() -> Self {
		.lazyLoaded(
			load: { features in
				let mockFeature: MockFeature = try features.instance(
					context: (
						mockInt: 24,
						mockString: "dependant",
						mockError: MockError.error()
					)
				)

				return Feature(
					mock: mockFeature.mock,
					mockInt: mockFeature.mockInt,
					mockString: mockFeature.mockString,
					mockThrowing: mockFeature.mockThrowing
				)
			}
		)
	}
}
