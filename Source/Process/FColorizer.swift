// =============================================================================
// FColorizer 🖌
// 
// Written by Andrew Thompson
// =============================================================================

import Geometry
import Support

public protocol FColorizer {
	associatedtype ColorType
	associatedtype ZValue
	func colorAt(point: Point, value: ZValue) -> Color<ColorType>
}


