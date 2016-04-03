/// FRenderer
///
/// Coordinates the process of creating a fractal.
///

public protocol FRenderer {
	associatedtype ColorType
	associatedtype ZValue
	
	var size: Size { get set }
	
	var computer: FComputer { get set }
	var painetr: FColoring { get set }
	var writer: FOutput { get set }
}	
