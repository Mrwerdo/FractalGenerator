// =============================================================================
// main 📝
// Written by Andrew Thompson
// =============================================================================

import Generators
import Darwin
import Geometry
import Support

func f(z: Complex) -> Complex {
    return sin(theta: z) + Complex(0.2, 0)
}

let mandelbrotSet = JuliaSet(numberOfIterations: 4000, function: f)
let colorizer = ModulusColorizer(rmax: 64, gmax: 4, bmax: 64)
let fileWriter = try FileWriter(path: "/Users/mrwerdo/Desktop/Image.tiff", size: Size(4096, 4096))
var c = try FileController(mandelbrotSet, colorizer, fileWriter)
try c.render()
c.finish()
system("open \(c.path)")