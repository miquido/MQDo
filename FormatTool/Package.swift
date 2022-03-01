// swift-tools-version:5.5
import PackageDescription

let package = Package(
  name: "tools",
  platforms: [.macOS(.v11)],
  dependencies: [
    .package(
      name: "swift-format",
      url: "https://github.com/apple/swift-format.git", 
      .exact("0.50500.0")
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
