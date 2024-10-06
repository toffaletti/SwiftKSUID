//
//  Base62.swift
//
//
//  Created by Jason Toffaletti on 3/1/22.
//

#if canImport(FoundationEssentials)
	import FoundationEssentials
#else
	import Foundation
#endif

internal struct FastBase62 {
	private static let base62Characters =
		"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz".data(
			using: .ascii)!

	enum Error: Swift.Error {
		case invalidCharacter
		case tooShort
	}

	public static func encode(source: ContiguousBytes) -> String {
		let srcBase: UInt64 = 4_294_967_296
		let dstBase: UInt64 = 62
		let parts = source.withUnsafeBytes { b -> [UInt32] in
			let ptr = b.bindMemory(to: UInt32.self)
			return [
				ptr[0].bigEndian,
				ptr[1].bigEndian,
				ptr[2].bigEndian,
				ptr[3].bigEndian,
				ptr[4].bigEndian,
			]
		}
		// fill with zeros "000000000000000000000000000"
		let dest = Data(repeating: UInt8(ascii: "0"), count: 27)
		dest.withUnsafeBytes { b in
			let ptr = b.bindMemory(to: UInt8.self)
			let dptr = UnsafeMutableBufferPointer(mutating: ptr)
			var bp = parts[0..<parts.count]
			var bq = [UInt32](repeating: 0, count: 5)
			var n = dest.count
			while !bp.isEmpty {
				var qidx: Int = 0
				var remainder: UInt64 = 0
				for c in bp {
					let value = UInt64(c) + remainder * srcBase
					let digit = value / dstBase
					remainder = value % dstBase
					if qidx != 0 || digit != 0 {
						bq[qidx] = UInt32(digit)
						qidx += 1
					}
				}
				n -= 1
				dptr[n] = UInt8(base62Characters[Int(remainder)])
				bp = bq[0..<qidx]
			}
		}
		return String(data: dest, encoding: .ascii)!
	}

	private static func base62Value(digit: UInt8) throws -> UInt8 {
		let offsetUppercase: UInt8 = 10
		let offsetLowercase: UInt8 = 36
		switch digit {
		case UInt8(ascii: "0")...UInt8(ascii: "9"):
			return digit - UInt8(ascii: "0")
		case UInt8(ascii: "A")...UInt8(ascii: "Z"):
			return offsetUppercase + (digit - UInt8(ascii: "A"))
		case UInt8(ascii: "a")...UInt8(ascii: "z"):
			return offsetLowercase + (digit - UInt8(ascii: "a"))
		default:
			throw Error.invalidCharacter
		}
	}

	public static func decode(source: String) throws -> Data {
		let srcBase: UInt64 = 62
		let dstBase: UInt64 = 4_294_967_296

		let dest = Data(repeating: 0, count: 20)
		guard let data = source.data(using: .ascii) else {
			throw Error.invalidCharacter  // TODO: better error
		}
		let parts = try data.map { c in
			try base62Value(digit: UInt8(c))
		}

		try dest.withUnsafeBytes { b in
			let ptr = b.bindMemory(to: UInt8.self)
			let dptr = UnsafeMutableBufferPointer(mutating: ptr)

			var n = dest.count
			var bp = parts[0..<parts.count]
			var bq = [UInt8](repeating: 0, count: 27)
			while !bp.isEmpty {
				var qidx: Int = 0
				var remainder: UInt64 = 0
				for c in bp {
					let value = UInt64(c) + remainder * srcBase
					let digit = value / dstBase
					remainder = value % dstBase
					if qidx != 0 || digit != 0 {
						bq[qidx] = UInt8(truncatingIfNeeded: digit)
						qidx += 1
					}
				}

				if n < 4 {
					throw Error.tooShort
				}

				// truncating casts
				dptr[n - 4] = UInt8(truncatingIfNeeded: remainder >> 24)
				dptr[n - 3] = UInt8(truncatingIfNeeded: remainder >> 16)
				dptr[n - 2] = UInt8(truncatingIfNeeded: remainder >> 8)
				dptr[n - 1] = UInt8(truncatingIfNeeded: remainder)
				n -= 4
				bp = bq[0..<qidx]
			}
		}
		return dest
	}
}
