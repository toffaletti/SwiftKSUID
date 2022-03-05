import Foundation

@frozen
public struct KSUID {
	private static let epochStamp: Int64 = 1_400_000_000

	internal var storage:
		(
			UInt8, UInt8, UInt8, UInt8,
			UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
			UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8
		) = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)

	public enum Error: Swift.Error {
		case invalidLength
	}

	public init<T: RandomNumberGenerator>(randomSource: inout T, timestamp: Date) {
		var r1 = UInt64.random(in: .min ... .max, using: &randomSource)
		var r2 = UInt64.random(in: .min ... .max, using: &randomSource)
		let ts = UInt32(Int64(timestamp.timeIntervalSince1970) - KSUID.epochStamp)
		withUnsafeMutableBytes(of: &storage) {
			$0.bindMemory(to: UInt32.self)[0] = ts.bigEndian
			($0.baseAddress! + 4).copyMemory(from: &r1, byteCount: 8)
			($0.baseAddress! + 12).copyMemory(from: &r2, byteCount: 8)
		}
	}

	public init() {
		var randomSource = SystemRandomNumberGenerator()
		self.init(randomSource: &randomSource, timestamp: Date())
	}

	public init(_ base62String: String) throws {
		guard base62String.count == 27 else {
			throw Error.invalidLength
		}
		try withUnsafeMutableBytes(of: &storage) {
			$0.copyBytes(from: try FastBase62.decode(source: base62String))
		}
	}

	public init(data: Data) throws {
		guard data.count == 20 else {
			throw Error.invalidLength
		}
		withUnsafeMutableBytes(of: &self.storage) {
			$0.copyBytes(from: data)
		}
	}

	public var timestamp: Date {
		return Date(
			timeIntervalSince1970:
				TimeInterval(Int64(self.rawTimestamp) + KSUID.epochStamp))
	}

	public var rawTimestamp: UInt32 {
		return withUnsafeBytes(of: storage) {
			$0.bindMemory(to: UInt32.self)[0].bigEndian
		}
	}

	public var payload: Data {
		return withUnsafeBytes(of: storage) {
			return Data.init(bytes: $0.baseAddress! + 4, count: 16)
		}
	}
}

extension KSUID: CustomStringConvertible {
	public var description: String {
		withUnsafeBytes(of: storage) {
			return FastBase62.encode(source: $0)
		}
	}
}
