import Foundation
import Testing

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

struct SwiftKSUIDTests {
	@Test func zero() throws {
		let data = Data(repeating: 0, count: 20)
		let zero = try KSUID(data: data)
		#expect(zero.rawTimestamp == 0)
		#expect(zero.payload == data[4..<data.count])
	}

	@Test func parse() throws {
		let a = try KSUID("1srOrx2ZWZBpBUvZwXKQmoEYga2")
		#expect(a.timestamp == Date(timeIntervalSince1970: 1_621_627_443))
		#expect(a.payload.base64EncodedString() == "4ZM+N/J1cIdjrcd0WvXn8g==")
	}

	@Test func parseFuzz1() throws {
		let src = Data(base64Encoded: "TExMTExMTExMTEz///8BTExMTExMTExMTEwK")!
		#expect(throws: (any Error).self) {
			try KSUID(data: src)
		}
	}

	@Test func parseInvalid() throws {
		#expect(throws: (any Error).self) {
			try KSUID("***************************")
		}
		#expect(throws: (any Error).self) {
			try KSUID("123")
		}
		#expect(throws: (any Error).self) {
			try KSUID("fffffffffffffffffffffffffff")
		}
	}

	@Test func parseMax() throws {
		let max = try KSUID("aWgEPTl1tmebfsQzFP4bxwgy80V")
		#expect(max.timestamp == Date(timeIntervalSince1970: 5_694_967_295))
		let expected = Data(repeating: 0xff, count: 16)
		#expect(max.payload == expected)
	}

	@Test func format() throws {
		let data = Data(base64Encoded: "Bmn377WhzTS1+Z0RVPtoUzRclzU=")!
		let a = try KSUID(data: data)
		#expect(a.description == "0ujtsYcgvSTl8PAuAdqWYSMnLOv")
	}

	@Test func formatMin() throws {
		let data = Data(repeating: 0, count: 20)
		let a = try KSUID(data: data)
		#expect(a.description == "000000000000000000000000000")
	}

	@Test func testFormatMax() throws {
		let data = Data(repeating: 0xff, count: 20)
		let a = try KSUID(data: data)
		#expect(a.description == "aWgEPTl1tmebfsQzFP4bxwgy80V")
	}

	@Test func tooLongData() throws {
		let data = Data(repeating: 0xff, count: 21)
		#expect(throws: (any Error).self) {
			try KSUID(data: data)
		}
	}

	@Test func random() throws {
		var generator = NonRandomNumberGenerator(seed: 123_456)
		let now = Date()
		let a = KSUID(using: &generator, timestamp: now)
		#expect(
			a.timestamp.timeIntervalSince1970
				== now.timeIntervalSince1970.rounded(.down))
		#expect(a.payload.base64EncodedString() == "QeIBAAAAAABC4gEAAAAAAA==")
	}

	@Test func basic() throws {
		let k = KSUID()
		#expect(k.description.count == 27)
	}

	@Test func equatable() throws {
		let k = KSUID()
		#expect(k == k)
	}

	@Test func comparabl() throws {
		let min = try KSUID(data: Data(repeating: 0, count: 20))
		let max = try KSUID(data: Data(repeating: 0xff, count: 20))
		#expect(min < max)
		#expect(!(min < min))
		#expect(max > min)
	}

	@Test func hashable() throws {
		let a = KSUID()
		let b = KSUID()
		#expect(a.hashValue != b.hashValue)
		#expect(a.hashValue == a.hashValue)
		#expect(b.hashValue == b.hashValue)
	}

	@Test func codable() throws {
		let k = KSUID()
		let e = JSONEncoder()
		let data = try e.encode(k)
		let d = JSONDecoder()
		let k2 = try d.decode(KSUID.self, from: data)
		#expect(k == k2)

		let dataCorrupted = Data(repeating: 0xff, count: 10)
		// attempt to decode some garbage that isn't even JSON
		#expect(throws: (any Error).self) {
			try d.decode(KSUID.self, from: dataCorrupted)
		}
		// decode a JSON string that is not a valid KSUID string
		#expect(throws: (any Error).self) {
			try d.decode(KSUID.self, from: #""astring""#.data(using: .ascii)!)
		}
	}
}

struct FastBase62Tests {
	@Test func encode() throws {
		let src = Data(base64Encoded: "Bmn377WhzTS1+Z0RVPtoUzRclzU=")!
		let out = FastBase62.encode(source: src)
		#expect(out == "0ujtsYcgvSTl8PAuAdqWYSMnLOv")
	}

	@Test func decode() throws {
		let out = try FastBase62.decode(source: "0ujtsYcgvSTl8PAuAdqWYSMnLOv")
		#expect(out.base64EncodedString() == "Bmn377WhzTS1+Z0RVPtoUzRclzU=")
	}

	@Test func invalidDecode() throws {
		#expect(throws: (any Error).self) {
			try FastBase62.decode(source: "$$$$$$$$$$$$$$$$$$$$$$$$$$$")
		}
	}
}
