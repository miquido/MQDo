// swift-tools-version:5.7
import PackageDescription

let package = Package(
  name: "tools",
  platforms: [.macOS(.v12)],
  dependencies: [
    .package(
      url: "https://github.com/apple/swift-format.git", 
      exact: "0.50700.1"
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
