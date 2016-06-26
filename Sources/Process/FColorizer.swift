// =============================================================================
// FColorizer 🖌
// 
//  This defines the coloring protocol along with some common coloring functions 
//  which are used to make good looking fractals.
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

public struct ModulusColorizerUInt8 : FColorizer {
    public var redMax: UInt8
    public var greenMax: UInt8
    public var blueMax: UInt8

    public init(rmax: UInt8 = 128, gmax: UInt8 = 64, bmax: UInt8 = 32) {
        self.redMax = rmax
        self.greenMax = gmax
        self.blueMax = bmax
    }

    public func colorAt(point: Point, value: Int) -> Color<UInt8> {
        let r = UInt8(value % 128) * 2
        let g = UInt8(value % 64) * 4
        let b = UInt8(value % 32) * 8
        return Color(r, g, b, 255)
    }
}

