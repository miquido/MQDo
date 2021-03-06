// swift-tools-version:5.6
import PackageDescription

let package = Package(
	name: "MQDo",
	platforms: [
		.iOS(.v13),
		.macOS(.v11),
		.macCatalyst(.v13),
		.tvOS(.v13),
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
			url: "https://github.com/miquido/MQ-iOS.git",
			.upToNextMajor(from: "0.5.0")
		)
	],
	targets: [
		.target(
			name: "MQDo",
			dependencies: [
				.product(
					name: "MQ",
					package: "mq-ios"
				)
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
