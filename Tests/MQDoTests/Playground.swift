import XCTest

@testable import MQDo

class Playground_Test: XCTestCase {

	@MainActor func test_playground() throws {
		// keep this method empty it is intended to be used as a playground
    let container: FeaturesContainer = rootFeaturesContainer { registry in
//      registry.use(
//        .mock(),
//        for: MockDependantFeature.self
//      )
      registry.use(
        .disposable(
          load: { context, _ in
            MockFeature(
              mock: noop,
              mockInt: always(context.mockInt),
              mockString: always(context.mockString)
            )
          }
        ),
        for: MockFeature.self
      )
    }

    let feat1: MockFeature = try container.instance(context: .init(mockInt: 1, mockString: "1"))
    print(feat1.mockInt())
    let feat2: MockFeature = try container.instance(context: .init(mockInt: 42, mockString: "1"))
    print(feat2.mockInt())
    let featd: MockDependantFeature = try container.instance()
    print(featd.mockString())
	}
}
