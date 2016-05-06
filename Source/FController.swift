// =============================================================================
// FController 🛂
// 
// Written by Andrew Thompson
// =============================================================================

public protocol FController {
    associatedtype ColorType
    associatedtype ZValue
    associatedtype Computer: FComputer
    associatedtype Colorizer: FColorizer
    associatedtype Renderer: FOutputRenderer
    
    var size: Size { get set }
    
    var computer: Computer { get set }
    var colorizer: Colorizer { get set }
    var renderer: Renderer { get set }
}


