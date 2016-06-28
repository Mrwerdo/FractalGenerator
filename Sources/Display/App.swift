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

class FView<Cm: FComputer, Cl: FColorizer where Cm.ZValue == Cl.ZValue> : NSView, FController, FOutputRenderer {

    var computer: Cm
    var colorizer: Cl
    var renderer: FView {
        get {
            return self
        }
        set { }
    }
    
    var castToCGFloat: (Cl.ColorType) -> CGFloat

    var imageSize: Size
    var size: Size {
        get {
            return imageSize
        }
        set {
            imageSize = newValue
        }
    }
    var diagramFrame: ComplexRect
    var buffer: UnsafeMutablePointer<CGFloat>

    init(frame: CGRect, cm: Cm, cl: Cl, castingFunction: (Cl.ColorType) -> CGFloat) {
        computer = cm
        colorizer = cl
        imageSize = Size(Int(frame.width), Int(frame.height))
        diagramFrame = ComplexRect(point: Complex(-2, -2), oppositePoint: Complex(2, 2))
        buffer = UnsafeMutablePointer<CGFloat>(allocatingCapacity: imageSize.width * imageSize.height * 3)
        buffer.initialize(with: -2, count: imageSize.width * imageSize.height * 3)
        castToCGFloat = castingFunction
        super.init(frame: frame)
    }

    func write(at point: Point, color: Color<Cl.ColorType>) throws {
        let index = point.y * size.width * 3 + point.x * 3
        buffer[index + 0] = castToCGFloat(color.red)
        buffer[index + 1] = castToCGFloat(color.green)
        buffer[index + 2] = castToCGFloat(color.blue)
    }

    func render() throws {
        fatalError("do not call this method")
    }

    func render(point: Point) {
        let cc = self.cartesianToArgandPlane(point: point)
        let zvalue = self.computer.computerPoint(C: cc)
        let color = colorizer.colorAt(point: point, value: zvalue)
        try! self.write(at: point, color: color)
    }

    func draw(context: CGContext, colors: UnsafePointer<CGFloat>, point: CGPoint) {

        if colors[0] == -2 {
            render(point: Point(Int(point.x), Int(point.y)))
        }

        context.setFillColor(colors)
        context.fill(CGRect(origin: point, size: CGSize(width: 2, height: 2)))
    }

    override func draw(_ r: CGRect) {
        let ctx = NSGraphicsContext.current()!.cgContext
        let updateFrame = r
        for y in Int(updateFrame.minY)..<Int(updateFrame.maxY) {
            for x in Int(updateFrame.minX)..<Int(updateFrame.maxX) {
                let colors = buffer.advanced(by: y * size.width * 3 + x * 3)
                draw(context: ctx, colors: colors, point: CGPoint(x: x, y: y))
            }
        }
    }
}

class FViewController<ColorType, Cm: FComputer, Cl: FColorizer where Cm.ZValue == Cl.ZValue, Cl.ColorType == ColorType>: NSViewController {

    var imageName: String
    var computer: Cm
    var colorizer: Cl
    var initialFrame: CGRect

    var cf: (ColorType) -> CGFloat

    init(_ im: String, _ f: CGRect, _ c: Cm, _ k: Cl, castingFunction: (ColorType) -> CGFloat) {
        self.initialFrame = f
        self.computer = c
        self.colorizer = k
        self.imageName = im
        self.cf = castingFunction

        super.init(nibName: nil, bundle: nil)!
    }

    override func loadView() {
        let f = CGRect(origin: CGPoint(), size: initialFrame.size)
        self.view = FView(frame: f, cm: computer, cl: colorizer, castingFunction: cf)
    }

    override func viewDidAppear() {
        // Do stuff here.
    }
    override func viewWillAppear() {
        // And here.
    }
}
