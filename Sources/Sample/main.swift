import Support
import Process
import LibTIFF
import Geometry
import Dispatch

struct MandelbrotSet : FComputer {
    
    var numberOfIteratinos: Int
    
    func computerPoint(C: Complex) -> Int {
        
        var z = C
        
        for it in 1...numberOfIteratinos {
            z = z*z + C
            if modulus(z) > 2 {
                return it
            }
        }
        
        return 0
    }
}

struct ModulusColorizer : FColorizer {
    
    func colorAt(point: Point, value: Int) -> Color<UInt8> {
        let r = UInt8(value % 64)
        let g = UInt8(value % 32)
        let b = UInt8(value % 16)
        return Color(r, g, b, 0)
    }
}

struct FileWriter : FFileOutputRenderer {
    var size: Size = Size(100, 100)
    var image: TIFFImage
    var path: String

    init(path: String) throws {
        image = try TIFFImage(writeAt: path, nil, size, hasAlpha: true)
        self.path = path
    }
    
    func write(at point: Point, color: Color<UInt8>) throws {
        func write(_ offset: Int, _ value: UInt8) {
            image.buffer[point.y + 4 * point.x + offset] = value
        }
        write(0, color.red)
        write(1, color.green)
        write(2, color.blue)
        write(3, color.alpha)
    }
    
    func flush() throws {
        try image.write()
    }
}

struct FileController : FController {
    
    var imageSize: Size
    var diagramFrame: ComplexRect
    var computer: MandelbrotSet
    var colorizer: ModulusColorizer
    var renderer: FileWriter

    var numberOfIterations: Int
    
    init(path: String) throws {
        self.imageSize = Size(100, 100)
        self.diagramFrame = ComplexRect(Complex(-1, -1), Complex(1, 1))
        self.numberOfIterations = 2000
        self.computer = MandelbrotSet(numberOfIteratinos: numberOfIterations)
        self.colorizer = ModulusColorizer()
        self.renderer = try FileWriter(path: path)
    }
    func render() throws {
        print("Started computing mandelbrot points...")
        let start = Time.now()
        var loopStart = start
        let fraction = 1.0 / Double(imageSize.width)
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
        
        for x in 0..<imageSize.width {
            let times = imageSize.height
            dispatch_apply(times, queue) { (y) in
                let point = Point(x, y)
                let cc = self.cartesianToArgandPlane(point: point)
                let zvalue = self.computer.computerPoint(C: cc)
                let color = self.colorizer.colorAt(point: point, value: zvalue)
                try! self.renderer.write(at: point, color: color)
            }
            let percentage = fraction * Double(x)
            if percentage * 100 == Double(Int(percentage * 100)) {
                let elapsedTime = Time.difference(then: start)
                let difference = Time.difference(then: loopStart)
                print("Percent complete: \(percentage * 100)%\t\twhich took \(elapsedTime) seconds, difference: \(difference)")
                loopStart = Time.now()
            }
        }
        try renderer.flush()
    }
}


let c = try FileController(path: "/Users/mrwerdo/Desktop/MandelbrotSet.tiff")
try c.render()