/// FOutput
///
/// Outputs the data given in some way (for example, a file).
///
/// This is third in the process model, i.e.
///
///		FComputer -> FColoring -> FOuput
///								  ^^^^^^

public protocol FOutput {
	associatedtype ColorType
	var size: Size { get set }
	func writeAt(_ point: Point, color: Color<ColorType>)
}

extension FOutput {
	func writeAll(buffer: ColorBuffer<ColorType>) {
		for y in 0..<size.height {
			for x in 0..<size.width {
				writeAt(Point(x, y), color: buffer[y * size.width + x])
			}
		}
	}
}
