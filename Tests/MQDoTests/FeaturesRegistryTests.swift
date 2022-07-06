import XCTest

@testable import MQDo

final class FeaturesRegistryTests: XCTestCase {
	
	func test_use_addsLoader() {
		var registry: ScopedFeaturesRegistry = .init(
			scope: TestScope.self,
			registry: .init()
		)
		
		registry.use(
			.constant(
				ContextlessTestFeature.self,
				instance: .mock
			)
		)
		
		// How to check that there is something in that container?
	}
	
	func test_use_replacesLoader_whenMatchingFeatureLoaderExists() {
		var registry: ScopedFeaturesRegistry = .init(
			scope: TestScope.self,
			registry: .init()
		)
		
		registry.use(
			.constant(
				ContextlessTestFeature.self,
				instance: .mock
			)
		)
		
		registry.use(
			.constant(
				ContextlessTestFeature.self,
				instance: .mock2
			)
		)
	}
	
	// I'm not sure about this test because to make an result we have to use an container to
	
	func test_remove_removesLoader() {
		var registry: ScopedFeaturesRegistry = .init(scope: TestScope.self, registry: .init())
		registry.use(.constant(ContextlessTestFeature.self, instance: .mock))
		registry.remove(ContextlessTestFeature.self)
		
		// Im not sure how to check if it correctly remove loader
	}
	
	func test_useLazy_addsLazyLoadedLoader() {
		var registry: ScopedFeaturesRegistry = .init(scope: TestScope.self, registry: .init())
		registry.use(
			.lazyLoaded(ContextTestFeature.self, load: { context, _ in
				return .init(
					name: always(context.name),
					surname: always(context.surname),
					age: context.age,
					greetingsFunction: noop
				)
			})
		)
		
		// I'm not sure about this test because to make an result we have to use an container to
	}
	
	func test_useLazy_addslazyLoadedLoader_withoutContext() {
		var registry: ScopedFeaturesRegistry = .init(scope: TestScope.self, registry: .init())
		registry.use(
			.lazyLoaded(ContextlessTestFeature.self, load: { _ in
				return .mock
			})
		)
		
		// I'm not sure about this test because to make an result we have to use an container to
	}
	
	func test_useDisposable_addsDisposableLoader() {
		XCTExpectFailure {
			XCTFail("TODO: implement tests")
		}
	}
	
	func test_useDisposable_addsDisposableLoader_withoutContext() {
		XCTExpectFailure {
			XCTFail("TODO: implement tests")
		}
	}
	
	func test_useConstant_addsConstantLoader() {
		XCTExpectFailure {
			XCTFail("TODO: implement tests")
		}
	}
	
	func test_useLazyConstant_addsLazyConstantLoader() {
		XCTExpectFailure {
			XCTFail("TODO: implement tests")
		}
	}
	
	func test_defineScope_addsFeaturesRegistryScopeConstantLoader() {
		XCTExpectFailure {
			XCTFail("TODO: implement tests")
		}
	}
	
	func test_loader_returnsNone_withoutMatchingLoader() {
		let rootFeatures: Features = .root { registry in
			registry.use(
				.constant(
					TestDependantFeature.self,
					instance: .mock
				)
			)
		}
		
		var isFailed: Bool = false
		
		do {
			let _: ContextlessTestFeature = try rootFeatures.instance()
		} catch {
			isFailed = true
		}
		XCTAssert(isFailed)
	}
	
	func test_loader_returnsSome_withMatchingLoader() {
		let rootFeatures: Features = .root { registry in
			registry.use(
				.constant(
					ContextlessTestFeature.self,
					instance: .mock
				)
			)
		}
		
		var isFailed: Bool = false
		
		do {
			let _: ContextlessTestFeature = try rootFeatures.instance()
		} catch {
			isFailed = true
		}
		XCTAssert(!isFailed)
	}
}
