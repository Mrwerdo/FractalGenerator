// =============================================================================
// FController 🛂
// 
//	Contains objects which can output fractals to files.
// 
// Written by Andrew Thompson
// =============================================================================

import Geometry
import Support
import Dispatch
import LibTIFF

public protocol FController {
    associatedtype Computer: FComputer
    associatedtype Colorizer: FColorizer
    associatedtype Renderer: FOutputRenderer
    
    var imageSize: Size2D { get set }
    var diagramFrame: ComplexRect { get set }
    
    var computer: Computer { get set }
    var colorizer: Colorizer { get set }
    var renderer: Renderer { get set }
}

extension FController {
    public func cartesianToArgandPlane(point: Point2D) -> Complex {
        
        let tl = diagramFrame.topLeft
        let br = diagramFrame.bottomRight
        let width = Double(imageSize.width)
        let height = Double(imageSize.height)
        
        let real = tl.real + (Double(point.x) / width) * (br.real - tl.real)
        let imag = tl.imaginary + (Double(point.y) / height) * (br.imaginary - tl.imaginary)
        
        return Complex(real, imag)
    }
}

extension FController where Computer.ZValue == Colorizer.ZValue, Colorizer.ColorType == Renderer.ColorType {
    public func render() throws {
        print("Started computing mandelbrot points...")
        let start = Time.now()
        var loopStart = start
        let fraction = 1.0 / Double(imageSize.width)
        
        for x in 0..<imageSize.width {
            let times = imageSize.height

            DispatchQueue.concurrentPerform(iterations: times) { (y) in 
                let point = Point2D(x: x, y: y)
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
    }
}

public struct FileController<Comp: FComputer, Colz: FColorizer, Rend: FFileOutputRenderer> : FController where Colz.ZValue == Comp.ZValue, Colz.ColorType == Rend.ColorType {
	public var imageSize: Size2D {
        get {
            return renderer.size
        }
        set {
            renderer.size = newValue
        }
    }
	public var diagramFrame: ComplexRect
	public var computer: Comp
	public var colorizer: Colz
	public var renderer: Rend

	public var path: String {
		return renderer.path
	}

	public init(_ comp: Comp, _ colz: Colz, _ rend: Rend) throws {
		self.diagramFrame = ComplexRect(point: Complex(-1, -1), oppositePoint: Complex(1, 1))
		self.computer = comp
		self.colorizer = colz
		self.renderer = rend
		self.imageSize = rend.size
	}

	public func finish() {
		try! self.renderer.flush()
		self.renderer.close()
	}
}

public struct FileWriter<Channel> : FFileOutputRenderer {
    public var size: Size2D
    public var image: TIFFImage<Channel>
    public var path: String

    public init(path: String, size: Size2D) throws {
        image = try TIFFImage(writingAt: path, size: size, hasAlpha: true)
        self.size = size
        self.path = path
    }
    
    public func write(at point: Point2D, color: Color<Channel>) throws {
        func write(_ offset: Int, _ value: Channel) {
            image.buffer[4 * point.y * size.width + 4 * point.x + offset] = value
        }
        write(0, color.red)
        write(1, color.green)
        write(2, color.blue)
        write(3, color.alpha)
    }
    
    public func flush() throws {
        try image.write()
    }
    public func close() {
        image.close()
    }
}
