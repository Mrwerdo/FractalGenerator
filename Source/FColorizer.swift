// =============================================================================
// Written by Andrew Thompson
// =============================================================================

public protocol FColoring {
	associatedtype ColorType
	associatedtype ZValue
	func colorAt(point: Point, value: ZValue) -> Color<ColorType>
}


