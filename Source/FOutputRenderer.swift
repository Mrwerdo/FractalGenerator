// =============================================================================
// FOutputRenderer 🖼
// 
// Written by Andrew Thompson
// =============================================================================

public protocol FOutputRenderer {
    associatedtype ColorType
    var size: Size { get set }
    func write(at point: Point, color: Color<ColorType>) throws
    func write(buffer: ColorBuffer<ColorType>) throws
}

extension FOutputRenderer {
    func write(buffer: ColorBuffer<ColorType>) throws {
        for y in 0..<size.height {
            for x in 0..<size.width {
                try write(at: Point(x, y), color: buffer[y * size.width + x])
            }
        }
    }
}

