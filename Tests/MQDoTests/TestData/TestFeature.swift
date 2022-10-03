import MQDo

struct TestFeature {

	var testVoid: () -> Void
	var testInt: () -> Int
	var testString: () -> String
}

extension TestFeature: DynamicFeature {

	struct Context: IdentifiableFeatureContext, Hashable {

		var intValue: Int
		var stringValue: String
	}

	static var mock: Self {
		.init(
			testVoid: {},
			testInt: always(42),
			testString: always("mock")
		)
	}
}

extension FeatureLoader where Feature == TestFeature {

	static func lazyLoaded() -> Self {
		.cacheable(
			load: { context, _ in
				Feature(
					testVoid: noop,
					testInt: always(context.intValue),
					testString: always(context.stringValue)
				)
			}
		)
	}
}

extension TestFeature {

	static var placeholder: Self {
		Self(
			testVoid: unimplemented(),
			testInt: unimplemented(),
			testString: unimplemented()
		)
	}
}
