import MQDo

struct TestDependantFeature {

	var testVoid: () -> Void
	var testInt: () -> Int
	var testString: () -> String
}

extension TestDependantFeature: ContextlessLoadableFeature {

	static var mock: Self {
		.init(
			testVoid: {},
			testInt: always(42),
			testString: always("mock")
		)
	}
}

extension FeatureLoader where Feature == TestDependantFeature {

	static func lazyLoaded() -> Self {
		.lazyLoaded(
			load: { features in
				let testFeature: TestFeature = try features.instance(
					context: .init(
						intValue: 0,
						stringValue: "lazyLoaded"
					)
				)

				var intState = testFeature.testInt()

				return Feature(
					testVoid: testFeature.testVoid,
					testInt: {
						intState += 1
						return intState
					},
					testString: testFeature.testString
				)
			}
		)
	}
}

extension TestDependantFeature {

	static var placeholder: Self {
		Self(
			testVoid: unimplemented(),
			testInt: unimplemented(),
			testString: unimplemented()
		)
	}
}
