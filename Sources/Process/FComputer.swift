// =============================================================================
// FComputer 🖥
//
//	Provides common fractal generator functions, such as the mandelbrot set
//	or the newton's method fractals.
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

public struct MandelbrotSet : FComputer {
    public var numberOfIterations: Int
    public init(numberOfIterations: Int) {
        self.numberOfIterations = numberOfIterations
    }
    public func computerPoint(C: Complex) -> Int {
        var z = C
        for it in 1...numberOfIterations {
            z = z*z + C
            if modulus(z) > 2 {
                return it
            }
        }
        return 0
    }
}

public struct JuliaSet : FComputer {
    public var numberOfIterations: Int
    public var function: (Complex) -> Complex
    
    public init(numberOfIterations: Int, function: @escaping (Complex) -> Complex) {
        self.numberOfIterations = numberOfIterations
        self.function = function
    }
    public func computerPoint(C: Complex) -> Int {
        var z = C
        for it in 1...numberOfIterations {
            z = function(z)
            if modulus(z) > 2 {
                return it
            }
        }
        return 0
    }
}
