// =============================================================================
// FColorizer 🖌
// 
// Written by Andrew Thompson
// =============================================================================

public protocol FColorizer {
	associatedtype ColorType
	associatedtype ZValue
	func colorAt(point: Point, value: ZValue) -> Color<ColorType>
}


