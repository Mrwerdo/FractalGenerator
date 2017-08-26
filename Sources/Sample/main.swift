// =============================================================================
// main 📝
// Written by Andrew Thompson
// =============================================================================

import Process
import Darwin
import Geometry
import Support

let mandelbrotSet = MandelbrotSet(numberOfIterations: 2000)

func **(lhs: Int, rhs: Int) -> Int {
  return Int(pow(Double(lhs), Double(rhs)))
}

public struct ModulusColorizerUInt32 : FColorizer {
    public typealias Channel = UInt32
    public var redMax: Channel
    public var greenMax: Channel
    public var blueMax: Channel

    public init(rmax: Channel, gmax: Channel, bmax: Channel) {
        self.redMax = rmax
        self.greenMax = gmax
        self.blueMax = bmax
    }

    public func colorAt(point: Point2D, value: Int) -> Color<Channel> {
        let r = Channel(value % (2**7)) * UInt32(2**13)
        let g = Channel(value % (2**4)) * UInt32(2**16)
        let b = Channel(value % (2**16)) * UInt32(2**4)
        return Color(r, g, b, Channel(2**32 - 1))
    }
}

let colorizer = ModulusColorizerUInt8(rmax: 64, gmax: 4, bmax: 64)
let fileWriter = try FileWriter<UInt8>(path: "/Users/mrwerdo/Desktop/Image.tiff", size: Size2D(width: 4000, height: 4000))

//try fileWriter.image.attributes.set(tag: 281, with: UInt32.max)
//try fileWriter.image.attributes.set(tag: 280, with: UInt32.min)

var c = try FileController(mandelbrotSet, colorizer, fileWriter)
c.diagramFrame = ComplexRect(point: Complex(-2, -2), oppositePoint: Complex(2, 2))
try c.render()
c.finish()
print(c.path)
 
