# MQDo

[![Platforms](https://img.shields.io/badge/platform-iOS%20|%20iPadOS%20|%20macOS-gray.svg?style=flat)]()
[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)
[![SwiftVersion](https://img.shields.io/badge/Swift-5.5-brightgreen.svg)]()

Dependency injection framework for Swift.

## Features

MQDo provides numerous features for managing dependencies across Swift codebases:
- dependency container tree with support for branches and scopes
- scopes with automatic lifetime management
- multiple dependency trees (multiple, independent tree roots)
- multiple implementations of the same type within a single tree based on scopes
- multiple instances of the same type within a single tree based on scopes
- dynamic implementation selection
- nested dependencies
- cache and lazy loading
- effortless mocking and testing
- error diagnostics

## Example

Basic example of a container, feature definition and feature access.

Firstly you have to prepare feature interface. Using structs instead of protocols is required due to swift compiler limitations.

```swift

// Interface of a feature. Using struct is required, protocol based interfaces are not supported.
struct Logger {

  // Method required by the interface
  var logMessage: (String) -> Void
}
```

Then define its conformance to a required protocol allowing usage in dependency containers.

```swift

// LoadableFeature implementation is required. Features can have Context types defined or
// be contextless as defined here using `ContextlessLoadableFeature` protocol.
extension Logger: ContextlessLoadableFeature {

  // For debug builds it is required to provide placeholder implementation.
  #if DEBUG
  static var placeholder: Self {
    .init(
      logMessage: unimplemented()
    )
  }
  #endif
}
```

Next you can provide any number of implementations. You can do it ad-hoc (as in example below) or by using only concrete type which will be used to fulfill interface requirements.

```swift

// Implementation of a feature is provided by defining
// FeatureLoader creating concrete instance based on required interface.
extension FeatureLoader where Feature == Logger {

  static func console() -> Self {
    // There are multiple available implementations of the FeatureLoader
    // which define lifetime and loading behavior for implemented feature.
    .lazyLoaded { (features: Features) in
      // `features` is a container context which can be used
      // to retrieve any other features
      Feature(
        logMessage: { (message: String) in
          print(message)
        }
      )
    }
  }
}
```

If you have defined your feature interface and some implementation you can then register it for a scope inside a container to be available. All feature implementations should be defined when creating container tree root.

```swift
let features: Features = .root { (registry: inout ScopedFeaturesRegistry<RootFeaturesScope>) in
  registry.use(Logger.self, .console())
  // you can also define other scopes and its features in this context
}
```

Finally you can access any feature from the container.

```swift
let logger: Logger = try features.instance()
```

If requested feature was not defined in available registry or there was any issue with accessing its instance you will get full diagnostics required to track the error.

```
FeatureLoadingFailed
###
---
MQDo/Example.swift@16:29
 " Requested feature loader is not defined
 - feature: Logger
---
MQDo/Example.swift@16:29
 " Loading feature instance failed
 - feature: Logger
 - context: Tag<Never>
 - scope: [Scope:MyScope]
 - features: Branch
   Features[Scope:MyScope]
   Features[Scope:RootFeaturesScope]
---
```

## License

Copyright 2021 Miquido

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
