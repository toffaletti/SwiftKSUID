import XCTest

@testable import SwiftKSUID

struct NonRandomNumberGenerator {
	var state: UInt64

	init(seed: UInt64) {
		self.state = seed
	}
}

extension NonRandomNumberGenerator: RandomNumberGenerator {
	mutating func next() -> UInt64 {
		self.state += 1
		return self.state
	}
}

final class SwiftKSUIDTests: XCTestCase {
	func testZero() throws {
		let data = Data(repeating: 0, count: 20)
		let zero = try KSUID(data: data)
		XCTAssertEqual(zero.rawTimestamp, 0)
		XCTAssertEqual(zero.payload, data[4..<data.count])
	}

	func testParse() throws {
		let a = try KSUID("1srOrx2ZWZBpBUvZwXKQmoEYga2")
		XCTAssertEqual(a.timestamp, Date(timeIntervalSince1970: 1_621_627_443))
		XCTAssertEqual(a.payload.base64EncodedString(), "4ZM+N/J1cIdjrcd0WvXn8g==")
	}

	func testParseInvalid() throws {
		XCTAssertThrowsError(try KSUID("***************************"))
		XCTAssertThrowsError(try KSUID("123"))
		XCTAssertThrowsError(try KSUID("fffffffffffffffffffffffffff"))
	}

	func testParseMax() throws {
		let max = try KSUID("aWgEPTl1tmebfsQzFP4bxwgy80V")
		XCTAssertEqual(max.timestamp, Date(timeIntervalSince1970: 5_694_967_295))
		let expected = Data(repeating: 0xff, count: 16)
		XCTAssertEqual(max.payload, expected)
	}

	func testFormat() throws {
		let data = Data(base64Encoded: "Bmn377WhzTS1+Z0RVPtoUzRclzU=")!
		let a = try KSUID(data: data)
		XCTAssertEqual(a.description, "0ujtsYcgvSTl8PAuAdqWYSMnLOv")
	}

	func testFormatMin() throws {
		let data = Data(repeating: 0, count: 20)
		let a = try KSUID(data: data)
		XCTAssertEqual(a.description, "000000000000000000000000000")
	}

	func testFormatMax() throws {
		let data = Data(repeating: 0xff, count: 20)
		let a = try KSUID(data: data)
		XCTAssertEqual(a.description, "aWgEPTl1tmebfsQzFP4bxwgy80V")
	}

	func testRandom() throws {
		var randomSource = NonRandomNumberGenerator(seed: 123_456)
		let now = Date()
		let a = KSUID(randomSource: &randomSource, timestamp: now)
		XCTAssertEqual(
			a.timestamp.timeIntervalSince1970, now.timeIntervalSince1970.rounded(.down))
		XCTAssertEqual(a.payload.base64EncodedString(), "QeIBAAAAAABC4gEAAAAAAA==")
	}
}

final class FastBase62Tests: XCTestCase {
	func testEncode() throws {
		let src = Data(base64Encoded: "Bmn377WhzTS1+Z0RVPtoUzRclzU=")!
		let out = FastBase62.encode(source: src)
		XCTAssertEqual(out, "0ujtsYcgvSTl8PAuAdqWYSMnLOv")
	}

	func testDecode() throws {
		let out = try FastBase62.decode(source: "0ujtsYcgvSTl8PAuAdqWYSMnLOv")
		XCTAssertEqual(out.base64EncodedString(), "Bmn377WhzTS1+Z0RVPtoUzRclzU=")
	}

	func testInvalidDecode() throws {
		XCTAssertThrowsError(try FastBase62.decode(source: "$$$$$$$$$$$$$$$$$$$$$$$$$$$"))
	}
}
