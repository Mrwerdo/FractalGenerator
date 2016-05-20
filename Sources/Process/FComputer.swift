// =============================================================================
// FComputer 🖥
//
// Written by Andrew Thompson
// =============================================================================

import Support
import Geometry

public protocol FComputer {
	associatedtype ZValue
	var numberOfIterations: Int { get set }
	func computerPoint(C: Complex) -> ZValue
}
