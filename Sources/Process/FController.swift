// =============================================================================
// FController 🛂
// 
// Written by Andrew Thompson
// =============================================================================

import Geometry
import Support
import Dispatch

public protocol FController {
    associatedtype Computer: FComputer
    associatedtype Colorizer: FColorizer
    associatedtype Renderer: FOutputRenderer
    
    var imageSize: Size { get set }
    var diagramFrame: ComplexRect { get set }
    
    var computer: Computer { get set }
    var colorizer: Colorizer { get set }
    var renderer: Renderer { get set }
}

extension FController {
    public func cartesianToArgandPlane(point: Point) -> Complex {
        
        let tl = diagramFrame.topLeft
        let br = diagramFrame.bottomRight
        let width = Double(imageSize.width)
        let height = Double(imageSize.height)
        
        let real = tl.real + (Double(point.x) / width) * (br.real - tl.real)
        let imag = tl.imaginary + (Double(point.y) / height) * (br.imaginary - tl.imaginary)
        
        return Complex(real, imag)
    }
}

extension FController where Computer.ZValue == Colorizer.ZValue, Colorizer.ColorType == Renderer.ColorType {
    public func render() throws {
        print("Started computing mandelbrot points...")
        let start = Time.now()
        var loopStart = start
        let fraction = 1.0 / Double(imageSize.width)
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
        
        for x in 0..<imageSize.width {
            let times = imageSize.height
            dispatch_apply(times, queue) { (y) in
                let point = Point(x, y)
                let cc = self.cartesianToArgandPlane(point: point)
                let zvalue = self.computer.computerPoint(C: cc)
                let color = self.colorizer.colorAt(point: point, value: zvalue)
                try! self.renderer.write(at: point, color: color)
            }
            let percentage = fraction * Double(x)
            if percentage * 100 == Double(Int(percentage * 100)) {
                let elapsedTime = Time.difference(then: start)
                let difference = Time.difference(then: loopStart)
                print("Percent complete: \(percentage * 100)%\t\twhich took \(elapsedTime) seconds, difference: \(difference)")
                loopStart = Time.now()
            }
        }
    }
}