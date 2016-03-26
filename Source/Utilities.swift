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

/* -------------------------------------------------------------------------- */
/*                                 OS X Only                                  */
/* -------------------------------------------------------------------------- */

#if os(OSX)

import Cocoa

extension NSImage {
	public func saveAsTIFF(filename: String) -> Bool {
		return TIFFRepresentation?.writeToFile(filename, atomically: false) ?? false
	}
}

extension NSURL {
	enum FileErrors : ErrorType {
		case CouldNotMakeUniqueFilename
	}

	convenience init(uniqueName name: String, type: String, version: String, base: NSURL) throws {
		let fm = NSFileManager()
		let filedir = base.URLByAppendingPathComponent(name).path!
		var uniqueNumber = 0
		var path = filedir + "\(uniqueNumber)" + "\(version)" + type
		while fm.fileExistsAtPath(path) {
			uniqueNumber += 1
			path = filedir + "\(uniqueNumber)" + "\(version)" + type
		}
		self.init(fileURLWithPath: path)
	}
}

#endif // #if os(OSX)
