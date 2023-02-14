import MQDo

struct TestDisposableFeature {

	var nextValue: () -> Int
}

extension TestDisposableFeature: DisposableFeature {

	nonisolated static var placeholder: Self {
		.init(
			nextValue: unimplemented0()
		)
	}
}
