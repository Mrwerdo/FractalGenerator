/// FComputer
///
/// Declares the functionality of a fractal computer.
///
/// In the process model, it is the first, i.e.
///
///		FComputer -> FColoring -> FOutput
///     ^^^^^^^^^
///

protocol FComputer {
	associatedtype ZValue
	var numberOfIteratinos: Int { get set }
	func computerPoint(C: Complex) -> ZValue
}

