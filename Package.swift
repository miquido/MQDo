// swift-tools-version:5.7
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
		),
		.library(
			name: "MQDoTest",
			targets: [
				"MQDoTest"
			]
		),
	],
	dependencies: [
		.package(
			url: "https://github.com/miquido/MQ-iOS.git",
			.upToNextMajor(from: "0.8.0")
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
			],
			swiftSettings: [
				.unsafeFlags([
					"-Xfrontend", "-warn-concurrency",
					"-Xfrontend", "-enable-actor-data-race-checks",
				])
			]
		),
		.testTarget(
			name: "MQDoTests",
			dependencies: [
				"MQDo"
			]
		),
		.target(
			name: "MQDoTest",
			dependencies: [
				"MQDo",
				.product(
					name: "MQ",
					package: "mq-ios"
				),
			],
			swiftSettings: [
				.unsafeFlags([
					"-Xfrontend", "-warn-concurrency",
					"-Xfrontend", "-enable-actor-data-race-checks",
				])
			]
		),
	],
	swiftLanguageVersions: [.v5]
)
