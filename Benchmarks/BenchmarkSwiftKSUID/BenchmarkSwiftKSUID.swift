import Benchmark
import SwiftKSUID

let benchmarks = {
	Benchmark("BenchmarkCreateKSUID") { benchmark in
		for _ in benchmark.scaledIterations {
			var k = KSUID()
		}
	}
}
