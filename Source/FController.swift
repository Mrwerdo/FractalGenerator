/// FRenderer
///
/// Coordinates the process of creating a fractal.
///

public protocol FRenderer {
	associatedtype ColorType
	associatedtype ZValue
        associatedtype Computer: FComputer
        associatedtype Painter: FColoring
        associatedtype Writer: FOutput
	
	var size: Size { get set }
	
	var computer: Computer { get set }
	var painetr: Painter { get set }
	var writer: Writer { get set }
}	
