import Support
import Geometry
import Process
import Cocoa

let mandelbrotSet = MandelbrotSet(numberOfIterations: 2000)

func **(lhs: Int, rhs: Int) -> Int {
  return Int(pow(Double(lhs), Double(rhs)))
}

public struct ModulusColorizerCGFloat: FColorizer {
    public typealias Channel = UInt16
    public var redMax: Channel
    public var greenMax: Channel
    public var blueMax: Channel

    public init(rmax: Channel, gmax: Channel, bmax: Channel) {
        self.redMax = rmax
        self.greenMax = gmax
        self.blueMax = bmax
    }

    public func colorAt(point: Point, value: Int) -> Color<Channel> {
        let r = Channel(value % (2**8)) * Channel(2**8)
        let g = Channel(value % (2**6)) * Channel(2**10)
        let b = Channel(value % (2**4)) * Channel(2**12)
        return Color(r, g, b, Channel(2**16 - 1))
    }
}

let colorizer = ModulusColorizerCGFloat(rmax: 64, gmax: 4, bmax: 64)

var frame = CGRect(x: 0, y: 0, width: 400, height: 400)
let app = FAppDelegate(frame: frame)
let v = FViewController("MandelbrotSet", frame, mandelbrotSet, colorizer)
app.controller = v
app.run()
