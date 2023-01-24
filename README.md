# MQDo

[![Platforms](https://img.shields.io/badge/platform-iOS%20|%20iPadOS%20|%20macOS-gray.svg?style=flat)]()
[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)
[![SwiftVersion](https://img.shields.io/badge/Swift-5.7-brightgreen.svg)]()

Dependency injection framework for Swift.

## Features

MQDo provides numerous functionalities useful for managing dependencies across Swift codebases:
- dependency container tree with support for branches and scopes
- scopes with automatic access and lifetime management
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

Firstly you have to prepare feature interface. All interfaces should be defined using structs. 
It helps in both testing (mocking) and debugging. Using structs instead of protocols is also 
required due to swift compiler limitations in some cases.

```swift

// Interface of a feature prepared using a struct.
struct Printer {

  // Method required by the interface
  var printMessage: (String) -> Void
}
```

Then define its conformance to a required protocol allowing usage in dependency containers.
Depending on selected protocol it also defines a lifetime and accessibility of a feature.
`StaticFeature` is always available and have to be defined. `DisposableFeature` is built
each time instance is requested returning fresh instance each time. `CacheableFeature` is built
once for defined scope, cached and reused when able.

```swift

// Conformance to one of a "Feature" protocols is required. 
// Dynamic features (Disposable, Cacheable) can have a Context defined or be contextless (which is default).
// Context is then required to create instances and can be used to pass any additional data and methods inside.
extension Printer: DisposableFeature {

  // It is required to provide placeholder implementation.
  // Placeholders are then used as a base for mocking.
  static var placeholder: Self {
    .init(
      printMessage: unimplemented1()
    )
  }
}
```

Next you can provide any number of implementations. You can do it ad-hoc (as in example below) or by using 
only a concrete type which will be used to fulfill interface requirements.

```swift

// Implementation of a feature can be provided by defining
// FeatureLoader loading instances of given feature.
extension Printer  {

  static func consolePrinter() -> FeatureLoader {
    // There are multiple available implementations of the FeatureLoader
    // which correspond to a lifetime and loading behavior of implemented feature
    // based on its type.
    .disposable { (features: Features) -> Printer in
      // `features` is a container context which can be used
      // to retrieve any other features if needed.
      Printer(
        logMessage: { (message: String) in
          print(message)
        }
      )
    }
  }
}
```

If you have defined your feature interface and some implementation you can then register it within a scope inside a container to be available. All feature implementations should be defined when creating container tree root.

```swift
let features: Features = FeaturesRoot { (registry: inout FeaturesRegistry<RootFeaturesScope>) in
  registry.use(.consolePrinter())
  // you can also define other scopes and its features in this context
}
```

Finally you can access any feature from the container.

```swift
let printer: Printer = try features.instance()
```

If requested feature was not defined in available registry or there was any issue with accessing its instance you will get full diagnostics required to track the error.

```
⎡ ⚠️ FeatureUndefined
⎜ 📺 FeatureUndefined
⎜ 🧵 Context: 
⎜ 📍 MQDo/Example.swift:36
⎜ ✉️ FeatureUndefined 
⎜ 🧩 feature: Printer
⎣ ⚠️ FeatureUndefined
```

## License

Copyright 2021-2023 Miquido

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
