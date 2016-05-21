// =============================================================================
// main 📝
// Written by Andrew Thompson
// =============================================================================

import Generators
import Darwin
import Geometry
import Support

let mandelbrotSet = JuliaSet(numberOfIterations: 2000, constant: Complex(0.279, 0))
let colorizer = ModulusColorizer(rmax: 16, gmax: 32, bmax: 64)
let fileWriter = try FileWriter(path: "/Users/mrwerdo/Desktop/Image.tiff")
let c = try FileController(mandelbrotSet, colorizer, fileWriter)
try c.render()
c.finish()
system("open \(c.path)")
