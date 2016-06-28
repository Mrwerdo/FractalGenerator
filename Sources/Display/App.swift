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
        app.activateIgnoringOtherApps(false)
        app.run()
    }
}

class FView<ColorType> : NSImageView, FOutputRenderer {

    var size: Size
    var bitmapRep: NSBitmapImageRep

    override init(frame: CGRect) {
        size = Size(Int(frame.width), Int(frame.height))
        let bps = strideof(ColorType)
        let format = NSBitmapFormat.alphaNonpremultiplied
        Swift.print(ColorType)
        Swift.print(bps)
        Swift.print(size)
        Swift.print(NSDeviceRGBColorSpace)
        Swift.print(format)
        Swift.print(bps * size.width)
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                    pixelsWide: size.width,
                                    pixelsHigh: size.height,
                                    bitsPerSample: bps * 8,
                                    samplesPerPixel: 4,
                                    hasAlpha: true,
                                    isPlanar: false,
                                    colorSpaceName: NSDeviceRGBColorSpace,
                                    bitmapFormat: format,
                                    bytesPerRow: 0, 
                                    bitsPerPixel: 0)
        bitmapRep = rep!
        super.init(frame: frame)
        let image = NSImage(size: frame.size)
        image.addRepresentation(bitmapRep)
        self.image = image
    }

    required init(coder acoder: NSCoder) {
        fatalError("not implemented")
    }

    func write(at point: Point, color: Color<ColorType>) throws {
        func set(pixel: UnsafePointer<ColorType>) {
            bitmapRep.setPixel(UnsafeMutablePointer<Int>(pixel), atX: point.x, y: point.y)
        }

        var pixel = [color.red, color.green, color.blue, color.alpha]
        set(pixel: &pixel)
        DispatchQueue.main.async {
            self.needsDisplay = true
        }
    }
}

class FViewController<ColorType, Cm: FComputer, Cl: FColorizer where Cm.ZValue == Cl.ZValue, Cl.ColorType == ColorType>: NSViewController, FController {

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

    init(_ im: String, _ f: CGRect, _ c: Cm, _ k: Cl) {
        self.initialFrame = f
        self.computer = c
        self.colorizer = k
        self.imageName = im
        self.diagramFrame = ComplexRect(point: Complex(-2, -2), oppositePoint: Complex(2, 2))

        super.init(nibName: nil, bundle: nil)!
    }

    func render(point: Point) {
        let cc = self.cartesianToArgandPlane(point: point)
        let zvalue = self.computer.computerPoint(C: cc)
        let color = colorizer.colorAt(point: point, value: zvalue)

        try! self.renderer.write(at: point, color: color)
    }
    
    override func loadView() {
        let f = CGRect(origin: CGPoint(), size: initialFrame.size)
        self.view = FView<ColorType>(frame: f)
    }

    override func viewDidAppear() {
        let queue = DispatchQueue.global(attributes: DispatchQueue.GlobalAttributes.qosDefault)
        queue.async {
            for y in 0..<self.imageSize.height {
                for x in 0..<self.imageSize.width {
                    let p = Point(x, y)
                    self.render(point: p)
                } 
            }
            print("finished")
        }
        print("returning")
    }
}
