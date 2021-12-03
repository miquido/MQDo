SHELL = sh
.ONESHELL:
.SHELLFLAGS = -e

clean:
	swift package reset

build:
	swift build
	
test:
	swift test

lint:
	swift run --configuration release --package-path ./FormatTool --build-path ./.toolsCache -- swift-format lint --configuration ./FormatTool/formatterConfig.json --parallel --recursive ./Package.swift ./Sources ./Tests

format:
	swift run --configuration release --package-path ./FormatTool --build-path ./.toolsCache -- swift-format format --configuration ./FormatTool/formatterConfig.json --parallel --recursive ./Package.swift ./Sources ./Tests --in-place
