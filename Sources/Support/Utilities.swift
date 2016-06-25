// =============================================================================
// Utilities.swift 🛠
// 
// Written by Andrew Thompson
// =============================================================================

#if os(Linux)
	import GLibc
#else
	import Darwin
#endif

public struct Time {
	public static func now() -> time_t {
		var t = time_t()
		time(&t)
		return t
	}
	public static func difference(then: time_t) -> time_t {
		let n = Time.now()
		return n - then
	}
}

// =============================================================================
//                                 OS X Only
// =============================================================================

#if os(OSX)

import Foundation

extension NSURL {
	enum FileErrors : ErrorProtocol {
		case CouldNotMakeUniqueFilename
	}

	convenience init(uniqueName name: String, type: String, version: String, base: NSURL) throws {
		let fm = FileManager()
		let filedir = base.appendingPathComponent(name)!.path!
		var uniqueNumber = 0
		var path = filedir + "\(uniqueNumber)" + "\(version)" + type
		while fm.fileExists(atPath: path) {
			uniqueNumber += 1
			path = filedir + "\(uniqueNumber)" + "\(version)" + type
		}
		self.init(fileURLWithPath: path)
	}
}

#endif // #if os(OSX)
