import MQDo

struct TestCacheableFeature {

	var nextValue: @Sendable () -> Int
}

extension TestCacheableFeature: CacheableFeature {

	nonisolated static var placeholder: Self {
		.init(
			nextValue: unimplemented0()
		)
	}
}
