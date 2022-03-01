// swift-tools-version:5.5
import PackageDescription

let package = Package(
	name: "MQDo",
	platforms: [
		.iOS(.v14),
		.macOS(.v11),
		.macCatalyst(.v14),
		.tvOS(.v14),
		.watchOS(.v7),
	],
	products: [
		.library(
			name: "MQDo",
			targets: [
				"MQDo"
			]
		)
	],
	dependencies: [
		.package(
			name: "MQ",
			url: "https://github.com/miquido/MQ-iOS.git",
			.upToNextMajor(from: "0.3.0")
		)
	],
	targets: [
		.target(
			name: "MQDo",
			dependencies: [
				"MQ"
			]
		),
		.testTarget(
			name: "MQDoTests",
			dependencies: [
				"MQDo"
			]
		),
	],
	swiftLanguageVersions: [.v5]
)
