// =============================================================================
// FComputer 🖥
//
// Written by Andrew Thompson
// =============================================================================

import Support

public protocol FComputer {
	associatedtype ZValue
	var numberOfIteratinos: Int { get set }
	func computerPoint(C: Complex) -> ZValue
}

