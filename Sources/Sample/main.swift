// =============================================================================
// main 📝
// Written by Andrew Thompson
// =============================================================================

import Generators
import Darwin

let mandelbrotSet = MandelbrotSet(numberOfIterations: 2000)
let colorizer = ModulusColorizer()
let fileWriter = try FileWriter(path: "/Users/mrwerdo/Desktop/Image.tiff")
let c: FileController<MandelbrotSet, ModulusColorizer, FileWriter> = try FileController(mandelbrotSet, colorizer, fileWriter)
try c.render()
c.finish()
system("open \(c.path)")