// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "SwiftKSUID",
	platforms: [
		.iOS(.v26), .macOS(.v26), .macCatalyst(.v26), .tvOS(.v26), .visionOS(.v26),
		.watchOS(.v26),
	],
	products: [
		.library(
			name: "SwiftKSUID",
			targets: ["SwiftKSUID"])
	],
	dependencies: [
		.package(
			url: "https://github.com/ordo-one/package-benchmark",
			.upToNextMajor(from: "1.29.0"))
	],
	targets: [
		.target(
			name: "SwiftKSUID",
			dependencies: []),
		.testTarget(
			name: "SwiftKSUIDTests",
			dependencies: [
				"SwiftKSUID"
			]),
	]
)

// Benchmark of BenchmarkSwiftKSUID
package.targets += [
	.executableTarget(
		name: "BenchmarkSwiftKSUID",
		dependencies: [
			"SwiftKSUID",
			.product(name: "Benchmark", package: "package-benchmark"),
		],
		path: "Benchmarks/BenchmarkSwiftKSUID",
		plugins: [
			.plugin(name: "BenchmarkPlugin", package: "package-benchmark")
		]
	)
]
