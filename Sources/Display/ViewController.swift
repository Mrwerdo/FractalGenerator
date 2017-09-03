//
//  ViewController.swift
//  Display
//
//  Created by Andrew Thompson on 3/9/17.
//

import Cocoa
import Support
import Process
import Geometry
import MetalKit

func ƒ(_ n: String = #function) {
    print(n)
}

class ViewController: NSViewController, TrackerDelegate {

    @IBOutlet weak var mtkView: MTKView!
    var delegate: OverTimeFractalComputer?
    var argandRect = ComplexRect(point: Complex(-2, -2), oppositePoint: Complex(2, 2))
    var mandelbrotSet: String = "mandelbrotShaderHighResolution"
    
    var tracker: DualTouchTracker!
    
    override func awakeFromNib() {
        
        tracker = DualTouchTracker()
        tracker.delegate = self
        tracker.view = mtkView
        
        // Make the view interactive.
        mtkView.acceptsTouchEvents = true
        // We require a texture to write into.
        mtkView.framebufferOnly = false
        // `mtkView.delegate` is a weak reference
        // so we need to keep it alive ourselves
        delegate = initalizeDelegate(shaderNamed: mandelbrotSet)
        mtkView.delegate = delegate
        mtkView.device = delegate?.device
        delegate?.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)
    }
    
    enum InitError: Error {
        case noGPU
    }
    
    private func initalizeDelegate(shaderNamed name: String) -> OverTimeFractalComputer? {
        do {
            guard let device = MTLCreateSystemDefaultDevice() else {
                throw InitError.noGPU
            }
            
            let library = try device.makeDefaultLibrary(bundle: Bundle.main)
            let shader = try library.makeFunction(name: name, constantValues: MTLFunctionConstantValues())
            let scroller = try library.makeFunction(name: "scroller", constantValues: MTLFunctionConstantValues())
            return try OverTimeFractalComputer(device: device, shader: shader, scroller: scroller, plane: argandRect)
        } catch {
            print(error) // should be sexy error message
            return nil
        }
    }
    
    func beginTracking(sender: DualTouchTracker) {
        delegate?.isScrolling = false
    }
    
    func updateTracking(sender: DualTouchTracker) {
        let delta = Complex(sender.computeDeltaOrigin() / CGPoint(mtkView.drawableSize))
        delegate?.argandDiagramFrame.translate(by: delta)
        delegate?.isScrolling = true
    }
    
    func endTracking(sender: DualTouchTracker) {
        delegate?.isScrolling = false
    }
}


extension ViewController {
    override func touchesBegan(with event: NSEvent) {
        tracker.touchesBegan(with: event)
    }

    override func touchesEnded(with event: NSEvent) {
        tracker.touchesEnded(with: event)
    }

    override func touchesMoved(with event: NSEvent) {
        tracker.touchesMoved(with: event)
    }

    override func touchesCancelled(with event: NSEvent) {
        tracker.touchesCancelled(with: event)
    }
}
