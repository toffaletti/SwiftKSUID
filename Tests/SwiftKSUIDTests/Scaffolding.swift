import XCTest
import Testing

@testable import SwiftKSUID

final class AllTests: XCTestCase {
  func testAll() async {
    await XCTestScaffold.runAllTests(hostedBy: self)
  }

  func testBenchmarkCreate() {
    var k: KSUID?
    measure(metrics: [XCTMemoryMetric(), XCTCPUMetric()]) {
    	for _ in 0...100000 {
    		k = KSUID()
    	}
    }
    XCTAssertNotNil(k)
  }
}
