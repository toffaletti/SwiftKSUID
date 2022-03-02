import Foundation

public struct KSUID {
	private static let epochStamp: Int64 = 1_400_000_000
	let data: Data

	public enum Error: Swift.Error {
		case invalidLength
	}

	public init<T: RandomNumberGenerator>(randomSource: inout T, timestamp: Date) {
		let r1 = UInt64.random(in: .min ... .max, using: &randomSource)
		let r2 = UInt64.random(in: .min ... .max, using: &randomSource)
		let ts = UInt32(Int64(timestamp.timeIntervalSince1970) - KSUID.epochStamp)
		data = Data(repeating: 0, count: 20)
		data.withUnsafeBytes { b in
			let ptr = b.bindMemory(to: UInt32.self)
			let dptr = UnsafeMutableBufferPointer(mutating: ptr)
			dptr[0] = ts.bigEndian
		}
		data[4..<data.count].withUnsafeBytes { b in
			let ptr = b.bindMemory(to: UInt64.self)
			let dptr = UnsafeMutableBufferPointer(mutating: ptr)
			dptr[0] = r1
			dptr[1] = r2
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
		data = try FastBase62.decode(source: base62String)
	}

	public init(data: Data) throws {
		guard data.count == 20 else {
			throw Error.invalidLength
		}
		self.data = data
	}

	public var timestamp: Date {
		return Date(
			timeIntervalSince1970:
				TimeInterval(Int64(self.rawTimestamp) + KSUID.epochStamp))
	}

	public var rawTimestamp: UInt32 {
		return data.withUnsafeBytes { b in
			let ptr = b.bindMemory(to: UInt32.self)
			return ptr[0].bigEndian
		}
	}

	public var payload: Data {
		return data[4..<data.count]
	}
}

extension KSUID: CustomStringConvertible {
	public var description: String {
		return FastBase62.encode(source: data)
	}
}
