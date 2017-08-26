// =============================================================================
// FOutputRenderer 🖼
// 
// Written by Andrew Thompson
// =============================================================================

import Geometry
import Support

public protocol FOutputRenderer {
    associatedtype ColorType
    
    var size: Size2D { get set }
    func write(at point: Point2D, color: Color<ColorType>) throws
    func write(buffer: ColorBuffer<ColorType>) throws
}

public protocol FFileOutputRenderer : FOutputRenderer {
    var path: String { get }
    func flush() throws
    func close()
}

extension FOutputRenderer {
    public func write(buffer: ColorBuffer<ColorType>) throws {
        for y in 0..<size.height {
            for x in 0..<size.width {
                try write(at: Point2D(x: x, y: y), color: buffer[y * size.width + x])
            }
        }
    }
}

