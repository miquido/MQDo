// swift-tools-version:5.6
import PackageDescription

let package = Package(
  name: "tools",
  platforms: [.macOS(.v11)],
  dependencies: [
    .package(
      url: "https://github.com/apple/swift-format.git", 
      exact: "0.50600.1"
    ),
  ],
  targets: [
    .target(
      name: "format",
      dependencies: [
        .product(
          name: "swift-format", 
          package: "swift-format"
        )
      ]
    ),
  ]
)
