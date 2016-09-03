import Support
import Geometry
import Process
import Cocoa

func **(lhs: Int, rhs: Int) -> Int {
  return Int(pow(Double(lhs), Double(rhs)))
}

func af(Z: Complex) -> Complex {
    return Z*Z + Complex(1,-0.2321)
}

func bf(Z: Complex) -> Complex {
    return Z + 0.279
}

struct Zipper : FComputer {
    var numberOfIterations: Int
    var ac: JuliaSet
    var bc: JuliaSet
    
    init(numberOfIterations: Int) {
        self.numberOfIterations = numberOfIterations
        ac = JuliaSet(numberOfIterations: numberOfIterations, function: af)
        bc = JuliaSet(numberOfIterations: numberOfIterations, function: bf)
    }

    func computerPoint(C: Complex) -> UInt {
        let a = Double(ac.computerPoint(C: C))
        let b = Double(bc.computerPoint(C: C))
        let c = (Double(abs(a-b))/Double(abs(b-a)+1))
        return UInt(abs(c) * 100)
    }
}

let mandelbrotSet = MandelbrotSet(numberOfIterations: 4000)

public struct ModulusColorizerCGFloat: FColorizer {
    public typealias Channel = UInt8
    public var redMax: Channel
    public var greenMax: Channel
    public var blueMax: Channel

    public init(rmax: Channel, gmax: Channel, bmax: Channel) {
        self.redMax = rmax
        self.greenMax = gmax
        self.blueMax = bmax
    }

    public func colorAt(point: Point2D, value: Int) -> Color<Channel> {
        let r = Channel(value % (2**6)) * Channel(2**2)
        let g = Channel(value % (2**4)) * Channel(2**4)
        let b = Channel(value % (2**2)) * Channel(2**6)
        return Color(r, g, b, Channel(2**8 - 1))
    }
}

let colorizer = ModulusColorizerCGFloat(rmax: 64, gmax: 4, bmax: 64)

var frame = CGRect(x: 0, y: 0, width: 400, height: 400)
let app = FAppDelegate(frame: frame)
let v = FViewController("MandelbrotSet", frame, mandelbrotSet, colorizer)
app.controller = v
app.run()

