import Process
import Cocoa

class FAppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    var controller: NSViewController!

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        print("did finish launching")
    }

    init(processName: String = "The Fractal Generator", 
         frame: CGRect) {
        super.init()
    }

    func makeWindow() -> NSWindow {
        window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 400, height: 300),
                          styleMask: NSResizableWindowMask,
                          backing: NSBackingStoreType.buffered,
                          defer: false)

        print("adding view")
        let content = window!.contentView! as NSView
        let view = controller.view
        content.addSubview(view)
        print("returning window")
        return window
    }

    func run() {
        print("running")
        let app = NSApplication.shared()
        print("\(#function)")
        app.delegate = self
        print("\(#function)")
        let w = makeWindow()
        print("after make window")
        print("\(#function)")
        w.makeKeyAndOrderFront(nil)
        print("\(#function)")
        app.activateIgnoringOtherApps(false)
        print("\(#function)")
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

        print("\(#function)")

        super.init(nibName: nil, bundle: nil)!
        print("\(#function)")
    }

    override func loadView() {
        print("\(#function)")
        let view = NSView(frame: CGRect(origin: CGPoint(), size: initialFrame.size))
        view.wantsLayer = true
        view.layer?.borderWidth = 2
        view.layer?.borderColor = NSColor.red().cgColor
        self.view = view
        print("\(#function)")
    }

    override func viewDidAppear() {
        Swift.print("view appeared")
    }
}
