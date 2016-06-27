import Process
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

class FViewController<ColorType, Cm: FComputer, Cl: FColorizer where Cm.ZValue == Cl.ZValue, Cl.ColorType == ColorType>: NSViewController {

    var imageName: String
    var computer: Cm
    var colorizer: Cl
    var initialFrame: CGRect

    init(_ im: String, _ f: CGRect, _ c: Cm, _ k: Cl) {
        self.initialFrame = f
        self.computer = c
        self.colorizer = k
        self.imageName = im

        super.init(nibName: nil, bundle: nil)!
    }

    override func loadView() {
        let view = NSView(frame: CGRect(origin: CGPoint(), size: initialFrame.size))
        view.wantsLayer = true
        view.layer?.borderWidth = 2
        view.layer?.borderColor = NSColor.red().cgColor
        self.view = view
    }

    override func viewDidAppear() {
        // Do stuff here.
    }
    override func viewWillAppear() {
        // And here.
    }
}
