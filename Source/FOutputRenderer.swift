// =============================================================================
// Written by Andrew Thompson
// =============================================================================

public protocol FOutputRenderer {
    associatedtype ColorType
    var size: Size { get set }
    func writeAt(_ point: Point, color: Color<ColorType>)
}

extension FOutputRenderer {
    func writeAll(buffer: ColorBuffer<ColorType>) {
        for y in 0..<size.height {
            for x in 0..<size.width {
                writeAt(Point(x, y), color: buffer[y * size.width + x])
            }
        }
    }
}

