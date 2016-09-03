import Process
import Support
import Geometry
import Cocoa

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
        let app = NSApplication.shared()
        app.delegate = self
        window = NSWindow(contentRect: initialFrame, 
                            styleMask: NSWindowStyleMask.fullSizeContentView,
                            backing: NSBackingStoreType.buffered,
                            defer: false)
        window.contentView!.addSubview(controller.view)
        window.isMovableByWindowBackground = true
        window.makeKeyAndOrderFront(nil)
        window.center()
        app.activate(ignoringOtherApps: false)
        app.run()
    }
}

class FView<ColorType> : NSImageView, FOutputRenderer {

    var size: Size
    var bitmapRep: NSBitmapImageRep

    override var mouseDownCanMoveWindow: Bool {
        return true
    }

    override init(frame: CGRect) {
        size = Size(Int(frame.width), Int(frame.height))
        let bps = MemoryLayout<ColorType>.stride
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                    pixelsWide: size.width,
                                    pixelsHigh: size.height,
                                    bitsPerSample: bps * 8,
                                    samplesPerPixel: 4,
                                    hasAlpha: true,
                                    isPlanar: false,
                                    colorSpaceName: NSDeviceRGBColorSpace,
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
    var imageSize: Size {
        get {
            let w = frame.width
            let h = frame.height
            return Size(Int(w), Int(h))
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
        let size = Size(Int(f.width), Int(f.height))
        self.file = try! FileWriter<ColorType>(path: "/Users/mrwerdo/Desktop/image.tiff", size: size)
        super.init(nibName: nil, bundle: nil)!
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
                    let p = Point2D(x, y)
                    self.render(point: p)
                } 
            }
            try! self.file.flush()
            self.file.close()
        }
    }
}
