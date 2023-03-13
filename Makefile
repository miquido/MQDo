SHELL = sh
.ONESHELL:
.SHELLFLAGS = -e

clean:
	swift package reset

build:
	swift build

ci_build:
	# build debug and release for all supported platforms
	# iOS
	xcodebuild build -workspace MQDo.xcworkspace -scheme MQDo -destination generic/platform=iOS -configuration debug
	xcodebuild build -workspace MQDo.xcworkspace -scheme MQDo -destination generic/platform=iOS -configuration release
	xcodebuild build -workspace MQDo.xcworkspace -scheme MQDummy -destination generic/platform=iOS -configuration debug
	xcodebuild build -workspace MQDo.xcworkspace -scheme MQDummy -destination generic/platform=iOS -configuration release
	# macOS
	xcodebuild build -workspace MQDo.xcworkspace -scheme MQDo -destination platform="macOS" -configuration debug
	xcodebuild build -workspace MQDo.xcworkspace -scheme MQDo -destination platform="macOS" -configuration release
	xcodebuild build -workspace MQDo.xcworkspace -scheme MQDummy -destination platform="macOS" -configuration debug
	xcodebuild build -workspace MQDo.xcworkspace -scheme MQDummy -destination platform="macOS" -configuration release
	# Catalyst
	xcodebuild build -workspace MQDo.xcworkspace -scheme MQDo -destination platform="macOS,variant=Mac Catalyst" -configuration debug
	xcodebuild build -workspace MQDo.xcworkspace -scheme MQDo -destination platform="macOS,variant=Mac Catalyst" -configuration release
	xcodebuild build -workspace MQDo.xcworkspace -scheme MQDummy -destination platform="macOS,variant=Mac Catalyst" -configuration debug
	xcodebuild build -workspace MQDo.xcworkspace -scheme MQDummy -destination platform="macOS,variant=Mac Catalyst" -configuration release
	# watchOS
	xcodebuild build -workspace MQDo.xcworkspace -scheme MQDo -destination generic/platform=watchOS -configuration debug
	xcodebuild build -workspace MQDo.xcworkspace -scheme MQDo -destination generic/platform=watchOS -configuration release
	xcodebuild build -workspace MQDo.xcworkspace -scheme MQDummy -destination generic/platform=watchOS -configuration debug
	xcodebuild build -workspace MQDo.xcworkspace -scheme MQDummy -destination generic/platform=watchOS -configuration release
	# tvOS
	xcodebuild build -workspace MQDo.xcworkspace -scheme MQDo -destination generic/platform=tvOS -configuration debug
	xcodebuild build -workspace MQDo.xcworkspace -scheme MQDo -destination generic/platform=tvOS -configuration release
	xcodebuild build -workspace MQDo.xcworkspace -scheme MQDummy -destination generic/platform=tvOS -configuration debug
	xcodebuild build -workspace MQDo.xcworkspace -scheme MQDummy -destination generic/platform=tvOS -configuration release

test:
	swift test

lint:
	swift run --configuration release --package-path ./FormatTool --scratch-path ./.toolsCache -- swift-format lint --configuration ./FormatTool/formatterConfig.json --parallel --recursive ./Package.swift ./Sources ./Tests

format:
	swift run --configuration release --package-path ./FormatTool --scratch-path ./.toolsCache -- swift-format format --configuration ./FormatTool/formatterConfig.json --parallel --recursive ./Package.swift ./Sources ./Tests --in-place
