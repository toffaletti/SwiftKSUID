#if canImport(FoundationEssentials)
	import FoundationEssentials
#else
	import Foundation
#endif

/// KSUID is a 20-byte K-Sortable Unique Identifier
///
/// KSUID are globally unique identifiers that are naturally sortable by their generation timestamp.
///
/// 20 bytes:
///
/// 00-03 big endian UTC timestamp with custom epoch
///
/// 04-19 random payload for uniqueness
public struct KSUID: Sendable {
	private static let epochStamp: Int64 = 1_400_000_000

	@usableFromInline
	internal typealias ksuid_t =
		(
			UInt8, UInt8, UInt8, UInt8,
			UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
			UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8
		)
	internal var storage: ksuid_t = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)

	/// Errors for KSUID
	public enum Error: Swift.Error {
		/// Returned when passing a parameter of the wrong length
		case invalidLength
	}

	/// Create a new KSUID
	///
	/// Use this to control the source of random data used for payload and the timestamp.
	///
	/// - Parameters:
	///   - using: A RandomNumberGenerator for generating the 16 byte payload
	///   - timestamp: A Date for the 4 byte timestamp
	public init<T: RandomNumberGenerator>(using generator: inout T, timestamp: Date = Date()) {
		var r1 = UInt64.random(in: .min ... .max, using: &generator)
		var r2 = UInt64.random(in: .min ... .max, using: &generator)
		let ts = UInt32(Int64(timestamp.timeIntervalSince1970) - KSUID.epochStamp)
		withUnsafeMutableBytes(of: &storage) {
			$0.bindMemory(to: UInt32.self)[0] = ts.bigEndian
			($0.baseAddress! + 4).copyMemory(from: &r1, byteCount: 8)
			($0.baseAddress! + 12).copyMemory(from: &r2, byteCount: 8)
		}
	}

	/// Create a new KSUID with SystemRandomNumberGenerator and current timestamp
	public init() {
		var generator = SystemRandomNumberGenerator()
		self.init(using: &generator)
	}

	/// Create a new KSUID from base62 textual representation
	///
	///  Parses the textual representation into a KSUID.
	///
	/// - Parameters:
	///   - base62String: A String containing  27 bytes of base62 encoded KSUID
	///
	/// - Throws: ``Error/invalidLength`` if base62String length is not 27
	/// - Throws: `FastBase62.Error.invalidCharacter` if base62String contains a character not in the base-62 alphabet
	/// - Throws: `FastBase62.Error.tooShort` if base62String contains base-62 that doesn't decode to 20 bytes
	public init(_ base62String: String) throws {
		guard base62String.count == 27 else {
			throw Error.invalidLength
		}
		try withUnsafeMutableBytes(of: &storage) {
			$0.copyBytes(from: try FastBase62.decode(source: base62String))
		}
	}

	/// Create a new KSUID from 20 bytes of Data
	///
	/// Copies 20 bytes of Data into a KSUID
	///
	/// - Parameters:
	///   - data: Data that must be 20 bytes
	///
	///  - Throws: ``Error/invalidLength`` if data is not 20 bytes
	public init(data: Data) throws {
		guard data.count == 20 else {
			throw Error.invalidLength
		}
		withUnsafeMutableBytes(of: &self.storage) {
			$0.copyBytes(from: data)
		}
	}

	/// A Date representing the timestamp part of the KSUID
	public var timestamp: Date {
		return Date(
			timeIntervalSince1970:
				TimeInterval(Int64(self.rawTimestamp) + KSUID.epochStamp))
	}

	/// The timestamp part of the KSUID as a UInt32 without the Epoch applied
	public var rawTimestamp: UInt32 {
		return withUnsafeBytes(of: storage) {
			$0.bindMemory(to: UInt32.self)[0].bigEndian
		}
	}

	/// The 16 byte random payload without timestamp
	public var payload: Data {
		return withUnsafeBytes(of: storage) {
			return Data.init(bytes: $0.baseAddress! + 4, count: 16)
		}
	}

	/// A String containing the 27-byte base62 textual representation of the KSUID
	///
	/// Can be parsed with KSUID("1srOrx2ZWZBpBUvZwXKQmoEYga2")
	public var ksuidString: String {
		withUnsafeBytes(of: storage) {
			return FastBase62.encode(source: $0)
		}
	}
}

extension KSUID: CustomStringConvertible {
	/// A String representing the KSUID
	///
	/// See: ``KSUID/ksuidString``
	public var description: String {
		return self.ksuidString
	}
}

extension KSUID: Equatable {
	public static func == (lhs: KSUID, rhs: KSUID) -> Bool {
		return lhs.storage.0 == rhs.storage.0
			&& lhs.storage.1 == rhs.storage.1
			&& lhs.storage.2 == rhs.storage.2
			&& lhs.storage.3 == rhs.storage.3
			&& lhs.storage.4 == rhs.storage.4
			&& lhs.storage.5 == rhs.storage.5
			&& lhs.storage.6 == rhs.storage.6
			&& lhs.storage.7 == rhs.storage.7
			&& lhs.storage.8 == rhs.storage.8
			&& lhs.storage.9 == rhs.storage.9
			&& lhs.storage.10 == rhs.storage.10
			&& lhs.storage.11 == rhs.storage.11
			&& lhs.storage.12 == rhs.storage.12
			&& lhs.storage.13 == rhs.storage.13
			&& lhs.storage.14 == rhs.storage.14
			&& lhs.storage.15 == rhs.storage.15
			&& lhs.storage.16 == rhs.storage.16
			&& lhs.storage.17 == rhs.storage.17
			&& lhs.storage.18 == rhs.storage.18
			&& lhs.storage.19 == rhs.storage.19
	}
}

extension KSUID: Hashable {
	public func hash(into hasher: inout Hasher) {
		hasher.combine(storage.0)
		hasher.combine(storage.1)
		hasher.combine(storage.2)
		hasher.combine(storage.3)
		hasher.combine(storage.4)
		hasher.combine(storage.5)
		hasher.combine(storage.6)
		hasher.combine(storage.7)
		hasher.combine(storage.8)
		hasher.combine(storage.9)
		hasher.combine(storage.10)
		hasher.combine(storage.11)
		hasher.combine(storage.12)
		hasher.combine(storage.13)
		hasher.combine(storage.14)
		hasher.combine(storage.15)
		hasher.combine(storage.16)
		hasher.combine(storage.17)
		hasher.combine(storage.18)
		hasher.combine(storage.19)
	}
}

extension KSUID: Comparable {
	public static func < (lhs: KSUID, rhs: KSUID) -> Bool {
		if lhs.storage.0 != rhs.storage.0 { return lhs.storage.0 < rhs.storage.0 }
		if lhs.storage.1 != rhs.storage.1 { return lhs.storage.1 < rhs.storage.1 }
		if lhs.storage.2 != rhs.storage.2 { return lhs.storage.2 < rhs.storage.2 }
		if lhs.storage.3 != rhs.storage.3 { return lhs.storage.3 < rhs.storage.3 }
		if lhs.storage.4 != rhs.storage.4 { return lhs.storage.4 < rhs.storage.4 }
		if lhs.storage.5 != rhs.storage.5 { return lhs.storage.5 < rhs.storage.5 }
		if lhs.storage.6 != rhs.storage.6 { return lhs.storage.6 < rhs.storage.6 }
		if lhs.storage.7 != rhs.storage.7 { return lhs.storage.7 < rhs.storage.7 }
		if lhs.storage.8 != rhs.storage.8 { return lhs.storage.8 < rhs.storage.8 }
		if lhs.storage.9 != rhs.storage.9 { return lhs.storage.9 < rhs.storage.9 }
		if lhs.storage.10 != rhs.storage.10 { return lhs.storage.10 < rhs.storage.10 }
		if lhs.storage.11 != rhs.storage.11 { return lhs.storage.11 < rhs.storage.11 }
		if lhs.storage.12 != rhs.storage.12 { return lhs.storage.12 < rhs.storage.12 }
		if lhs.storage.13 != rhs.storage.13 { return lhs.storage.13 < rhs.storage.13 }
		if lhs.storage.14 != rhs.storage.14 { return lhs.storage.14 < rhs.storage.14 }
		if lhs.storage.15 != rhs.storage.15 { return lhs.storage.15 < rhs.storage.15 }
		if lhs.storage.16 != rhs.storage.16 { return lhs.storage.16 < rhs.storage.16 }
		if lhs.storage.17 != rhs.storage.17 { return lhs.storage.17 < rhs.storage.17 }
		if lhs.storage.18 != rhs.storage.18 { return lhs.storage.18 < rhs.storage.18 }
		return lhs.storage.19 < rhs.storage.19
	}
}

extension KSUID: Codable {
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let string = try container.decode(String.self)

		guard let k = try? KSUID(string) else {
			throw DecodingError.dataCorrupted(
				DecodingError.Context(
					codingPath: decoder.codingPath,
					debugDescription:
						"Attempted to decode from invalid KSUID string.")
			)
		}

		self = k
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(self.ksuidString)
	}
}
