// =============================================================================
// To File 📂
// 
//	Contains objects which can output fractals to files.
// 
// Written by Andrew Thompson
// =============================================================================

import Process
import Support
import Geometry
import LibTIFF

public struct FileController<Comp: FComputer, Colz: FColorizer, Rend: FFileOutputRenderer where Colz.ZValue == Comp.ZValue, Colz.ColorType == Rend.ColorType> : FController {
	public var imageSize: Size
	public var diagramFrame: ComplexRect
	public var computer: Comp
	public var colorizer: Colz
	public var renderer: Rend

	public var path: String {
		return renderer.path
	}

	public init(_ comp: Comp, _ colz: Colz, _ rend: Rend) throws {
		self.imageSize = Size(1024, 1024)
		self.diagramFrame = ComplexRect(Complex(-1, -1), Complex(1, 1))
		self.computer = comp
		self.colorizer = colz
		self.renderer = rend
	}

	public func finish() {
		try! self.renderer.flush()
		self.renderer.close()
	}
}

public struct FileWriter : FFileOutputRenderer {
    public var size: Size = Size(1024, 1024)
    public var image: TIFFImage
    public var path: String

    public init(path: String) throws {
        image = try TIFFImage(writeAt: path, nil, size, hasAlpha: true)
        self.path = path
    }
    
    public func write(at point: Point, color: Color<UInt8>) throws {
        func write(_ offset: Int, _ value: UInt8) {
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
