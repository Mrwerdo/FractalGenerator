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
		var n = Time.now()
		return n - then
	}
}


