import Support
import Geometry
import Process
import Cocoa
import MetalKit

class ViewController: NSViewController {
    
    let mtkview = MTKView()
    let source = URL(fileURLWithPath: "/Users/mrwerdo/Developer/FractalGenerator/Sources/Shaders/Shaders.metal")
    let shaderName = "mandelbrotShaderHighResolution"
    var delegate: OverTimeFractalComputer?
    
    override func loadView() {
        view = mtkview
        mtkview.framebufferOnly = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let device = MTLCreateSystemDefaultDevice() else {
            return
        }

        let f = ComplexRect(point: Complex(-2, -2), oppositePoint: Complex(2, 2))

        do {
            mtkview.device = device
            mtkview.colorPixelFormat = MTLPixelFormat.bgra8Unorm
            delegate = try OverTimeFractalComputer(device: device,
                                                   shaderSource: source,
                                                   functionName: shaderName,
                                                   argandFrame: f)
            mtkview.delegate = delegate
        } catch {
            print(error)
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        delegate?.reset()
    }
}

let k = 100
let frame = CGRect(x: 0, y: 0, width: 16 * k, height: 9 * k)
let app = FAppDelegate(frame: frame)
app.controller = ViewController()
app.controller.view.frame = frame
app.run()
