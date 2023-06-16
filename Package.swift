// swift-tools-version:5.8
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
		// to be extracted as a separate package
		.library(
			name: "MQBase",
			targets: [
				"MQBase"
			]
		),
		.library(
			name: "MQDummy",
			targets: [
				"MQDummy"
			]
		),
		.library(
			name: "MQAssert",
			targets: [
				"MQAssert"
			]
		),
	],
	dependencies: [
		.package(
			url: "https://github.com/miquido/MQ-iOS.git",
			.upToNextMajor(from: "0.13.2")
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
			name: "MQDummy",
			dependencies: [
				"MQDo",
				.product(
					name: "MQ",
					package: "mq-ios"
				),
			]
		),
		.target(
			name: "MQAssert",
			dependencies: [
				"MQDummy",
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
