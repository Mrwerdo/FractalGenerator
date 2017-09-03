//
//  ViewController.swift
//  Display
//
//  Created by Andrew Thompson on 3/9/17.
//

import Cocoa
import Support
import Process
import MetalKit

class ViewController: NSViewController {

    @IBOutlet weak var mtkView: MTKView!
    var delegate: OverTimeFractalComputer?
    var argandRect = ComplexRect(point: Complex(-2, -2), oppositePoint: Complex(2, 2))
    var mandelbrotSet: String = "mandelbrotShaderHighResolution"
    
    override func awakeFromNib() {
        do {
            // We require a texture to write into.
            mtkView.framebufferOnly = false
            // `mtkView.delegate` is a weak reference
            // so we need to keep it alive ourselves
            delegate = try initalizeDelegate(shaderNamed: mandelbrotSet)
            mtkView.delegate = delegate
            mtkView.device = delegate?.device
        } catch {
            print(error)
        }
    }
    
    enum InitError: Error {
        case noGPU
    }
    
    private func initalizeDelegate(shaderNamed name: String) throws -> OverTimeFractalComputer {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw InitError.noGPU
        }
        
        let library = try device.makeDefaultLibrary(bundle: Bundle.main)
        let function = try library.makeFunction(name: name, constantValues: MTLFunctionConstantValues())
        return try OverTimeFractalComputer(device: device, shader: function, plane: argandRect)
    }
}

