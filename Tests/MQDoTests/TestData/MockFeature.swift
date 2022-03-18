import MQDo

struct MockFeature {

	var mock: () -> Void
	var mockInt: () -> Int
	var mockString: () -> String
}

extension MockFeature: LoadableContextualFeature {

  struct Context: IdentifiableFeatureContext, Hashable {
		var mockInt: Int
		var mockString: String
  }

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

extension FeatureLoader where Feature == MockFeature {

	static func mock() -> Self {
		.lazyLoaded(
			load: { context, _ in
				Feature(
					mock: noop,
					mockInt: always(context.mockInt),
					mockString: always(context.mockString)
				)
			}
		)
	}
}
