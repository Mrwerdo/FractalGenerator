import Process
import Support
import Geometry
import Cocoa
import MetalKit

class FAppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var controller: NSViewController!
    var initialFrame: CGRect

    init(processName: String = "The Fractal Generator", frame: CGRect) {
        setprogname(processName)
        initialFrame = frame
        super.init()
    }
    
    func run() {
        let app = NSApplication.shared
        app.delegate = self
        window = NSWindow(contentRect: initialFrame, 
                            styleMask: [.fullSizeContentView],
                            backing: NSWindow.BackingStoreType.buffered,
                            defer: true)
        window.contentViewController = controller
        window.makeKeyAndOrderFront(nil)
        window.isMovableByWindowBackground = true
        window.center()
        window.title = "The Fractal Generator"
        app.activate(ignoringOtherApps: true)
        app.run()
    }
}

class FView<ColorType> : NSImageView, FOutputRenderer {

    var size: Size2D
    var bitmapRep: NSBitmapImageRep

    override var mouseDownCanMoveWindow: Bool {
        return true
    }

    override init(frame: CGRect) {
        size = Size2D(width: Int(frame.width), height: Int(frame.height))
        let bps = MemoryLayout<ColorType>.stride
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                    pixelsWide: size.width,
                                    pixelsHigh: size.height,
                                    bitsPerSample: bps * 8,
                                    samplesPerPixel: 4,
                                    hasAlpha: true,
                                    isPlanar: false,
                                    colorSpaceName: NSColorSpaceName.deviceRGB,
                                    bytesPerRow: 0, 
                                    bitsPerPixel: 0)
        bitmapRep = rep!
        
        super.init(frame: frame)
        let image = NSImage(size: frame.size)
        image.addRepresentation(bitmapRep)
        self.image = image
        initalizeToBlack()
    }


    func initalizeToBlack() {
        // every 4 * strideof(ColorType) bytes we want to set
        // to be 100%, as this is the alpha channel.
        var c = 3 * MemoryLayout<ColorType>.stride
        let step = 4 * MemoryLayout<ColorType>.stride
        let count = size.width * size.height * 4 * MemoryLayout<ColorType>.stride
        let ptr = bitmapRep.bitmapData!
        while c < count {
            var k = 0
            while k < MemoryLayout<ColorType>.stride {
                ptr[c + k] = 0xFF
                k += 1
            }
            c += step
        }
    }

    required init(coder acoder: NSCoder) {
        fatalError("not implemented")
    }

    func write(at point: Point2D, color: Color<ColorType>) throws {

        let k = MemoryLayout<ColorType>.size
        bitmapRep.bitmapData?.withMemoryRebound(to: ColorType.self, capacity: k) { ptr in
            let index = point.y * size.width * 4 + point.x * 4
            ptr[index + 0] = color.red
            ptr[index + 1] = color.green
            ptr[index + 2] = color.blue
            ptr[index + 3] = color.alpha
            
            DispatchQueue.main.async {
                self.needsDisplay = true
            }
        }
    }
}

class FViewController<ColorType, Cm: FComputer, Cl: FColorizer>: NSViewController, FController where Cm.ZValue == Cl.ZValue, Cl.ColorType == ColorType {

    var imageName: String
    var computer: Cm
    var colorizer: Cl
    var renderer: FView<ColorType> {
        get {
            return self.view as! FView
        }
        set { }
    }
    var initialFrame: CGRect
    var diagramFrame: ComplexRect
    var imageSize: Size2D {
        get {
            let w = frame.width
            let h = frame.height
            return Size2D(width: Int(w), height: Int(h))
        }
        set {
            self.view.frame.size.width = CGFloat(newValue.width)
            self.view.frame.size.height = CGFloat(newValue.height)
        }
    }
    var file: FileWriter<ColorType>

    init(_ im: String, _ f: CGRect, _ c: Cm, _ k: Cl) {
        self.initialFrame = f
        self.computer = c
        self.colorizer = k
        self.imageName = im
        self.diagramFrame = ComplexRect(point: Complex(-2, -2), oppositePoint: Complex(2, 2))
        let size = Size2D(width: Int(f.width), height: Int(f.height))
        self.file = try! FileWriter<ColorType>(path: "/Users/mrwerdo/Desktop/image.tiff", size: size)
        super.init(nibName: nil, bundle: nil)
    }

    required init(coder: NSCoder) {
        fatalError("not implemented")
    }

    func render(point: Point2D) {
        let cc = self.cartesianToArgandPlane(point: point)
        let zvalue = self.computer.computerPoint(C: cc)
        let color = colorizer.colorAt(point: point, value: zvalue)

        try! self.file.write(at: point, color: color)
        try! self.renderer.write(at: point, color: color)
    }
    
    override func loadView() {
        let f = CGRect(origin: CGPoint(), size: initialFrame.size)
        self.view = FView<ColorType>(frame: f)
    }

    override func viewDidAppear() {
        
        let queue = DispatchQueue.global(qos: .default)
        queue.async {
            for y in 0..<self.imageSize.height {
                for x in 0..<self.imageSize.width {
                    let p = Point2D(x: x, y: y)
                    self.render(point: p)
                } 
            }
            try! self.file.flush()
            self.file.close()
        }
    }
}
