import Support
import Geometry
import Process
import Cocoa
import MetalKit

extension MTLSize
{
    var hasZeroDimension: Bool {
        return depth * width * height == 0
    }
}

/// Encapsulates the sizes to be passed to `MTLComputeCommandEncoder.dispatchThreadgroups(_:threadsPerThreadgroup:)`.
public struct ThreadgroupSizes
{
    var threadsPerThreadgroup: MTLSize
    var threadgroupsPerGrid: MTLSize
    
    public static let zeros = ThreadgroupSizes(
        threadsPerThreadgroup: MTLSize(),
        threadgroupsPerGrid: MTLSize())
    
    var hasZeroDimension: Bool {
        return threadsPerThreadgroup.hasZeroDimension || threadgroupsPerGrid.hasZeroDimension
    }
}

public extension MTLComputePipelineState
{
    /// Selects "reasonable" values for threadsPerThreadgroup and threadgroupsPerGrid for the given `drawableSize`.
    /// - Remark: The heuristics used here are not perfect. There are many ways to underutilize the GPU,
    /// including selecting suboptimal threadgroup sizes, or branching in the shader code.
    ///
    /// If you are certain you can always use threadgroups with a multiple of `threadExecutionWidth`
    /// threads, then you may want to use MTLComputePipleineDescriptor and its property
    /// `threadGroupSizeIsMultipleOfThreadExecutionWidth` to configure your pipeline state.
    ///
    /// If your shader is doing some more interesting calculations, and your threads need to share memory in some
    /// meaningful way, then you’ll probably want to do something less generalized to choose your threadgroups.
    func threadgroupSizesForDrawableSize(_ drawableSize: CGSize) -> ThreadgroupSizes
    {
        let waveSize = self.threadExecutionWidth
        let maxThreadsPerGroup = self.maxTotalThreadsPerThreadgroup
        
        let drawableWidth = Int(drawableSize.width)
        let drawableHeight = Int(drawableSize.height)
        
        if drawableWidth == 0 || drawableHeight == 0 {
            print("drawableSize is zero")
            return .zeros
        }
        
        // Determine the set of possible sizes (not exceeding maxThreadsPerGroup).
        var candidates: [ThreadgroupSizes] = []
        for groupWidth in 1...maxThreadsPerGroup {
            for groupHeight in 1...(maxThreadsPerGroup/groupWidth) {
                // Round up the number of groups to ensure the entire drawable size is covered.
                // <http://stackoverflow.com/a/2745086/23649>
                let groupsPerGrid = MTLSize(width: (drawableWidth + groupWidth - 1) / groupWidth,
                                            height: (drawableHeight + groupHeight - 1) / groupHeight,
                                            depth: 1)
                
                candidates.append(ThreadgroupSizes(
                    threadsPerThreadgroup: MTLSize(width: groupWidth, height: groupHeight, depth: 1),
                    threadgroupsPerGrid: groupsPerGrid))
            }
        }
        
        /// Make a rough approximation for how much compute power will be "wasted" (e.g. when the total number
        /// of threads in a group isn’t an even multiple of `threadExecutionWidth`, or when the total number of
        /// threads being dispatched exceeds the drawable size). Smaller is better.
        func _estimatedUnderutilization(_ s: ThreadgroupSizes) -> Int {
            let excessWidth = s.threadsPerThreadgroup.width * s.threadgroupsPerGrid.width - drawableWidth
            let excessHeight = s.threadsPerThreadgroup.height * s.threadgroupsPerGrid.height - drawableHeight
            
            let totalThreadsPerGroup = s.threadsPerThreadgroup.width * s.threadsPerThreadgroup.height
            let totalGroups = s.threadgroupsPerGrid.width * s.threadgroupsPerGrid.height
            
            let excessArea = excessWidth * drawableHeight + excessHeight * drawableWidth + excessWidth * excessHeight
            let excessThreadsPerGroup = (waveSize - totalThreadsPerGroup % waveSize) % waveSize
            
            return excessArea + excessThreadsPerGroup * totalGroups
        }
        
        // Choose the threadgroup sizes which waste the least amount of execution time/power.
        let result = candidates.min { _estimatedUnderutilization($0) < _estimatedUnderutilization($1) }
        return result ?? .zeros
    }
}

public extension MTLCommandQueue
{
    /// Helper function for running compute kernels and displaying the output onscreen.
    ///
    /// This function configures a MTLComputeCommandEncoder by setting the given `drawable`'s texture
    /// as the 0th texture (so it will be available as a `[[texture(0)]]` parameter in the kernel).
    /// It calls `drawBlock` to allow further configuration, then dispatches the threadgroups and
    /// presents the results.
    ///
    /// - Requires: `drawBlock` must call `setComputePipelineState` on the command encoder to select a compute function.
    func computeAndDraw(into drawable: @autoclosure () -> CAMetalDrawable?, with threadgroupSizes: ThreadgroupSizes, drawBlock: (MTLComputeCommandEncoder) -> Void)
    {
        if threadgroupSizes.hasZeroDimension {
            print("dimensions are zero; not drawing")
            return
        }
        
        autoreleasepool {  // Ensure drawables are freed for the system to allocate new ones.
            guard let drawable = drawable() else {
                print("no drawable")
                return
            }
            
            guard let buffer = self.makeCommandBuffer(),
                let encoder = buffer.makeComputeCommandEncoder() else {
                    return
            }
            encoder.setTexture(drawable.texture, index: 0)
            
            drawBlock(encoder)
            
            encoder.dispatchThreadgroups(threadgroupSizes.threadgroupsPerGrid, threadsPerThreadgroup: threadgroupSizes.threadsPerThreadgroup)
            encoder.endEncoding()
            
            buffer.present(drawable)
            buffer.commit()
            buffer.waitUntilCompleted()
        }
    }
}

extension MTLTexture {
    func zero(pixelSize: Int) {
        var region = MTLRegion()
        region.size = MTLSize(width: width, height: height, depth: 1)
        let byteCount = width * height * pixelSize
        let buffer = UnsafeMutablePointer<Int8>.allocate(capacity: byteCount)
        buffer.initialize(to: 0, count: byteCount)
        replace(region: region, mipmapLevel: 0, withBytes: buffer, bytesPerRow: width * pixelSize)
        buffer.deinitialize(count: byteCount)
        buffer.deallocate(capacity: byteCount)
    }
}

class ViewController: NSViewController, MTKViewDelegate {
    
    var mview: MTKView!
    var commandQueue: MTLCommandQueue!
    var device: MTLDevice!
    let shaderSourcePath = URL(fileURLWithPath: "/Users/mrwerdo/Developer/FractalGenerator/Sources/Display/Shaders.metal")
    var library: MTLLibrary!
    var dispatchQueue: DispatchQueue!
    var threadgroupSizes: ThreadgroupSizes!
    
    var mandelbrotShader: MTLFunction!
    var mandelbrotPipelineState: MTLComputePipelineState!
    var floatTexturePageA: MTLTexture!
    var floatTexturePageB: MTLTexture!
    var alphaBuffer: MTLBuffer!
    let maxIterations: UInt32 = 1000
    var alphaCounter: UInt32 = 0 {
        didSet {
            if alphaCounter >= maxIterations {
                mview.isPaused = true
                print("done")
            }
        }
    }
    var iter_step: UInt32 = 1
    
    override func loadView() {
        mview = MTKView()
        mview.framebufferOnly = false
        view = mview
    }
    
    func textureDescriptor(format: MTLPixelFormat, size: CGSize) -> MTLTextureDescriptor {
        let d = MTLTextureDescriptor()
        d.textureType = .type2D
        d.pixelFormat = format
        d.width = Int(size.width)
        d.height = Int(size.height)
        d.depth = 1
        d.arrayLength = 1
        d.mipmapLevelCount = 1
        d.sampleCount = 1
        d.cpuCacheMode = .writeCombined
        d.storageMode = .managed
        d.usage = [.shaderRead, .shaderWrite]
        return d
    }
    
    func createFloatTexture(for size: CGSize) {
        guard size.width * size.height != 0 else {
            return
        }
        
        let d = textureDescriptor(format: .rgba32Float, size: size)
        floatTexturePageA = device.makeTexture(descriptor: d)
        floatTexturePageB = device.makeTexture(descriptor: d)
        floatTexturePageA.zero(pixelSize: MemoryLayout<Float32>.size * 4)
        floatTexturePageB.zero(pixelSize: MemoryLayout<Float32>.size * 4)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        device = MTLCreateSystemDefaultDevice()
        mview.device = device
        mview.colorPixelFormat = MTLPixelFormat.bgra8Unorm
        mview.delegate = self
        commandQueue = device.makeCommandQueue()
        createFloatTexture(for: mview.frame.size)
        
        do {
        
            let source = try String(contentsOf: shaderSourcePath)
            library = try device.makeLibrary(source: source, options: nil)
            mandelbrotShader = library.makeFunction(name: "mandelbrotShaderHighResolution")
            alphaBuffer = device.makeBuffer(length: 2 * MemoryLayout<UInt32>.size, options: [])!
            
            mandelbrotPipelineState = try device.makeComputePipelineState(function: mandelbrotShader)
            
            dispatchQueue = DispatchQueue.global(qos: .userInitiated)
            
        } catch {
            print(error)
            return
        }
    }
    
    override func viewDidLayout() {
        threadgroupSizes = mandelbrotPipelineState.threadgroupSizesForDrawableSize(mview.drawableSize)
    }
    
    func drawMandelbrotSet(drawable: CAMetalDrawable) {
        commandQueue.computeAndDraw(into: drawable, with: threadgroupSizes) {
            
            alphaCounter += 1
            
            let buff = alphaBuffer.contents().bindMemory(to: UInt32.self, capacity: 2)
            buff[0] = alphaCounter
            buff[1] = iter_step
            
            $0.setTexture(floatTexturePageB, index: 1)
            $0.setTexture(floatTexturePageA, index: 2)
            $0.setBuffer(alphaBuffer, offset: 0, index: 0)
            $0.setComputePipelineState(mandelbrotPipelineState)
            
            swap(&floatTexturePageA, &floatTexturePageB)
        }
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        createFloatTexture(for: size)
    }
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable else {
            return
        }
        
        drawMandelbrotSet(drawable: drawable)
    }
}

let k = 100
let frame = CGRect(x: 0, y: 0, width: 16 * k, height: 9 * k)
let app = FAppDelegate(frame: frame)
app.controller = ViewController()
app.controller.view.frame = frame
app.run()
