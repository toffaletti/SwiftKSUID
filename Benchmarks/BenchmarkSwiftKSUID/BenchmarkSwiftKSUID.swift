import Benchmark
import SwiftKSUID

let benchmarks: @Sendable () -> Benchmark? = {
	Benchmark("BenchmarkCreateKSUID") { benchmark in
		for _ in benchmark.scaledIterations {
			var k = KSUID()
		}
	}
}
