// =============================================================================
// Common Colors 🎨
// 
//	This file contains common coloring functions which are used to make 
// 	good looking fractals.
//
// Written by Andrew Thompson
// =============================================================================

import Process
import Support
import Geometry

public struct ModulusColorizer : FColorizer {
    public init() {}
    public func colorAt(point: Point, value: Int) -> Color<UInt8> {
        let r = UInt8(value % 128)
        let g = UInt8(value % 64)
        let b = UInt8(value % 32)
        return Color(r, g, b, 255)
    }
}
