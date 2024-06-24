// swift-tools-version:5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "SwiftKSUID",
	platforms: [
		.iOS(.v13), .macOS(.v13), .macCatalyst(.v13), .tvOS(.v13), .visionOS(.v1),
		.watchOS(.v6),
	],
	products: [
		.library(
			name: "SwiftKSUID",
			targets: ["SwiftKSUID"])
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-testing.git", revision: "0.9.0"),
		.package(
			url: "https://github.com/ordo-one/package-benchmark",
			.upToNextMajor(from: "1.4.0")),
	],
	targets: [
		.target(
			name: "SwiftKSUID",
			dependencies: []),
		.testTarget(
			name: "SwiftKSUIDTests",
			dependencies: [
				"SwiftKSUID", .product(name: "Testing", package: "swift-testing"),
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
