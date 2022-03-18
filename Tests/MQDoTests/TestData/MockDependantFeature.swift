import MQDo

struct MockDependantFeature {

	var mock: () -> Void
	var mockInt: () -> Int
	var mockString: () -> String
}

extension MockDependantFeature: LoadableFeature {

	static var placeholder: Self {
		Self(
			mock: unimplemented(),
			mockInt: unimplemented(),
			mockString: unimplemented()
		)
	}

	static var mock: Self {
		.init(
			mock: {},
			mockInt: always(42),
			mockString: always("mock")
		)
	}
}

extension FeatureLoader where Feature == MockDependantFeature {

	static func mock() -> Self {
		.lazyLoaded(
			load: { features in
				let mockFeature: MockFeature = try features.instance(
          context: .init(
						mockInt: 24,
						mockString: "dependant"
					)
				)

				return Feature(
					mock: mockFeature.mock,
					mockInt: mockFeature.mockInt,
					mockString: mockFeature.mockString
				)
			}
		)
	}
}
