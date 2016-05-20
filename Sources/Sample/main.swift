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
        let r = UInt8(value % 128)
        let g = UInt8(value % 64)
        let b = UInt8(value % 32)
        return Color(r, g, b, 255)
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
            image.buffer[4 * point.y * size.width + 4 * point.x + offset] = value
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
    func finish() {
        try! self.renderer.flush()
        c.renderer.image.close()
        system("open \(self.renderer.path)")
    }
}

let c = try FileController(path: "/Users/mrwerdo/Desktop/MandelbrotSet.tiff")
try c.render()
c.finish()
