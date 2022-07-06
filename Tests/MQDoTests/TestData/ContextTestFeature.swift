//
//  File.swift
//  
//
//  Created by Grzegorz Gumieniak on 24/06/2022.
//

import Foundation
import MQDo

struct ContextTestFeature {
	var name: () -> String
	var surname: () -> String
	let age: UInt
	var greetingsFunction: () -> ()
}


extension ContextTestFeature: LoadableFeature {
	struct Context: LoadableFeatureContext, Hashable {
		var name: String
		var surname: String
		let age: UInt
	}
	
	static var mock: Self {
		.init(
			name: always("Jan"),
			surname: always("Kowalski"),
			age: 38,
			greetingsFunction: {
				print("Hay Hey Hello")
			}
		)
	}
}
