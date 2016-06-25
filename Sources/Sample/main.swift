// =============================================================================
// main 📝
// Written by Andrew Thompson
// =============================================================================

import Process
import Darwin
import Geometry
import Support

let mandelbrotSet = MandelbrotSet(numberOfIterations: 2000)

let colorizer = ModulusColorizer(rmax: 64, gmax: 4, bmax: 64)
let fileWriter = try FileWriter(path: "/Users/mrwerdo/Desktop/Image.tiff", size: Size(4096, 4096))
var c = try FileController(mandelbrotSet, colorizer, fileWriter)
c.diagramFrame = ComplexRect(point: Complex(-2, -2), oppositePoint: Complex(2, 2))
try c.render()
c.finish()
print(c.path)
