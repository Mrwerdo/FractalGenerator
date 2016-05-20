// =============================================================================
// Computers 🖥
//
//	Provides common fractal generator functions, such as the mandelbrot set
//	or the newton's method fractals.
//
// Written by Andrew Thompson
// =============================================================================

import Support
import Process

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

