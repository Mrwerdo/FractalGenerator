// =============================================================================
// FComputer 🖥
//
// Written by Andrew Thompson
// =============================================================================

public protocol FComputer {
	associatedtype ZValue
	var numberOfIteratinos: Int { get set }
	func computerPoint(C: Complex) -> ZValue
}

