//
//  ContextlessTestFeature.swift
//  
//
//  Created by Grzegorz Gumieniak on 22/06/2022.
//

import Foundation
import MQDo

struct ContextlessTestFeature {
	
	var name: () -> String
	var surname: () -> String
	let age: UInt
	var greetingsFunction: () -> ()
}

extension ContextlessTestFeature: ContextlessLoadableFeature {
	
	static var mock: Self {
		.init(
			name: always("Jan"),
			surname: always("Kowalski"),
			age: 42,
			greetingsFunction: {
				print("My name is")
			}
		)
	}
	
	static var mock2: Self {
		.init(
			name: always("John"),
			surname: always("Doe"),
			age: 11,
			greetingsFunction: {
				print("I really like tacos.")
			}
		)
	}
}

extension FeatureLoader where Feature == ContextlessTestFeature {
	
	static func constantLoader() -> Self {
		.constant(
			instance: .mock
		)
	}
	
	static func disposableLoader() -> Self {
		.disposable { container in
			return .mock
		}
	}
	
	static func lazyLoadedLoader() -> Self {
		.lazyLoaded { container in
			return .mock
		}
	}
	
//	static func lazyLoadedLoaderWithContext() -> Self {
//		.lazyLoaded { context, container in
//
//		}
//	}
}

extension ContextlessTestFeature: Equatable {
	
	static func == (lhs: ContextlessTestFeature, rhs: ContextlessTestFeature) -> Bool {
		lhs.age == rhs.age &&
		lhs.surname() == rhs.surname() &&
		lhs.name() == rhs.name()
	}
}
