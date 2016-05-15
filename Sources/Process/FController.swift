// =============================================================================
// FController 🛂
// 
// Written by Andrew Thompson
// =============================================================================

import Geometry
import Support
import Dispatch

public protocol FController {
    //associatedtype ColorType
    //associatedtype ZValue
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
