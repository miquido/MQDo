// swift-tools-version:5.7
import PackageDescription

let package = Package(
	name: "MQDo",
	platforms: [
		.iOS(.v14),
		.macOS(.v12),
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
		),
		.library(
			name: "MQBase",
			targets: [
				"MQBase"
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
			.upToNextMajor(from: "0.10.0")
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
		.target(
			name: "MQBase",
			dependencies: [
				"MQDo",
				.product(
					name: "MQ",
					package: "mq-ios"
				),
			]
		),
		.testTarget(
			name: "MQBaseTests",
			dependencies: [
				"MQBase"
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
			]
		),
	],
	swiftLanguageVersions: [.v5]
)
