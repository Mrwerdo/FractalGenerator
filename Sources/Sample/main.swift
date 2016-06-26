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

    public func colorAt(point: Point, value: Int) -> Color<Channel> {
        let r = Channel(value % (2**16)) * UInt32(2**16)
        let g = Channel(value % (2**12)) * UInt32(2**20)
        let b = Channel(value % (2**8)) * UInt32(2**24)
        return Color(r, g, b, Channel(2**32 - 1))
    }
}

let colorizer = ModulusColorizerUInt32(rmax: 64, gmax: 4, bmax: 64)
let fileWriter = try FileWriter<UInt32>(path: "/Users/mrwerdo/Desktop/Image.tiff", size: Size(4000, 4000))

try fileWriter.image.attributes.write(UInt32.max, for: 281)
try fileWriter.image.attributes.write(UInt32.min, for: 280)

var c = try FileController(mandelbrotSet, colorizer, fileWriter)
c.diagramFrame = ComplexRect(point: Complex(-2, -2), oppositePoint: Complex(2, 2))
try c.render()
c.finish()
print(c.path)
