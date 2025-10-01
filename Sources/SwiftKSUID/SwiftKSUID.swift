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
	internal typealias ksuid_t = InlineArray<20, UInt8>
	internal var storage: ksuid_t = .init(repeating: 0)

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
		for i in lhs.storage.indices {
			if lhs.storage[i] != rhs.storage[i] {
				return false
			}
		}
		return true
	}
}

extension KSUID: Hashable {
	public func hash(into hasher: inout Hasher) {
		withUnsafeBytes(of: self.storage) {
			hasher.combine(bytes: $0)
		}
	}
}

extension KSUID: Comparable {
	public static func < (lhs: KSUID, rhs: KSUID) -> Bool {
		for i in lhs.storage.indices {
			if lhs.storage[i] != rhs.storage[i] {
				return lhs.storage[i] < rhs.storage[i]
			}
		}
		return false
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
