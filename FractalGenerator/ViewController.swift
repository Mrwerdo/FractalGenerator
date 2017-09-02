//
//  ViewController.swift
//  FractalGenerator
//
//  Created by Andrew Thompson on 2/9/17.
//

import UIKit
import MetalKit

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
            return
        }
        
        do {
            delegate = try OverTimeFractalComputer(device: device,
                                                   shaderSource: url,
                                                   functionName: shaderName)
        } catch {
            print(error)
            return
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

