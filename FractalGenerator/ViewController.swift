//
//  ViewController.swift
//  FractalGenerator
//
//  Created by Andrew Thompson on 2/9/17.
//

import UIKit
import MetalKit

func ƒ(_ s: String = #function) {
    print(s)
}

class ViewController: UIViewController {

    @IBOutlet var mtkView: MTKView!
    var delegate: OverTimeFractalComputer!
    let shaderName = "mandelbrotShaderHighResolution"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let device = MTLCreateSystemDefaultDevice() else {
            return
        }
        
        mtkView.device = device
        mtkView.colorPixelFormat = MTLPixelFormat.bgra8Unorm
        
        guard let url = Bundle.main.url(forResource: "Shaders", withExtension: "metal") else {
            print("could not find shader source files!")
            return
        }
        
        do {
            delegate = try OverTimeFractalComputer(device: device,
                                                   shaderSource: url,
                                                   functionName: shaderName)
            delegate.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)
            mtkView.delegate = delegate
        } catch {
            print(error)
            return
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        delegate.reset()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

