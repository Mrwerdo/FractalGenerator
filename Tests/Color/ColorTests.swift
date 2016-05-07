import XCTest
@testable import Color

class ColorTests: XCTestCase {

	func basicArrayAccess() {
		// Use ssert and related functions to verify your tests produce the correct results.
		let size = 20
		let ptr = UnsafeMutablePointer<UInt8>(allocatingCapacity: size)
		var colorBuffer = ColorBuffer<UInt8>(buffer: ptr, length: size)

		colorBuffer[0] = Color(127, 127, 127, 127)
		colorBuffer[4] = Color(255, 255, 255, 255)
		colorBuffer[1] = colorBuffer[4]
		colorBuffer[2] = colorBuffer[0]
		colorBuffer[3] = Color(0, 0, 0, 255)

		XCTAssert(colorBuffer[0].red == 127, "value returned is not what was expected")
		XCTAssert(colorBuffer[2].red == 127, "value returned is not what was expected")
		XCTAssert(colorBuffer[4].green == 255, "value returned is not what was expected")
		XCTAssert(colorBuffer[1].blue == 255, "value returned is not what was expected")
		XCTAssert(colorBuffer[3].alpha == 255, "value returned is not what was expected")
	}
}
extension ColorTests {
	static var allTests : [(String, ColorTests -> () throws -> Void)] {
		return [
			("testExample", testExample),
		]
	}
}
