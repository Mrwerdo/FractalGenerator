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

class OverTimeFractalComputer: NSObject, MTKViewDelegate {
    
    private var commandQueue: MTLCommandQueue
    private var device: MTLDevice
    
    private var shaderSource: String
    private var threadgroupSizes: ThreadgroupSizes
    private var shaderFunction: MTLFunction
    private var pipeline: MTLComputePipelineState
    private var renderPageA: MTLTexture!
    private var renderPageB: MTLTexture!
    private var userArgumentsBuffer: MTLBuffer
    private var argumentsPaths: [KeyPath<OverTimeFractalComputer, UInt32>] = [
        \.iterationCount,
        \.iterationsPerFrame
    ]
    
    public var isComplete: Bool {
        return iterationCount >= iterationLimit
    }
    public private(set) var iterationCount: UInt32 = 0
    public var iterationLimit: UInt32 = 1000
    public var iterationsPerFrame: UInt32 = 1
    
    public var shaderName: String {
        return shaderFunction.name
    }
    
    public enum InitError: Error {
        case couldNotMakeCommandQueue
        case couldNotMakeShaderFunction
        case couldNotMakeBuffer
    }
    
    public init(device d: MTLDevice, shaderSource url: URL, functionName: String) throws {
        device = d
        threadgroupSizes = .zeros
        shaderSource = try String(contentsOf: url)
        
        let library = try device.makeLibrary(source: shaderSource, options: nil)
        
        guard let sf = library.makeFunction(name: functionName) else {
            throw InitError.couldNotMakeShaderFunction
        }
        
        guard let cq = device.makeCommandQueue() else {
            throw InitError.couldNotMakeCommandQueue
        }
        
        let length = MemoryLayout<UInt32>.size * argumentsPaths.count
        guard let bf = device.makeBuffer(length: length, options: []) else {
            throw InitError.couldNotMakeBuffer
        }
        
        pipeline = try device.makeComputePipelineState(function: sf)
        shaderFunction = sf
        commandQueue = cq
        userArgumentsBuffer = bf
    }
    
    public func reset() {
        let size = CGSize(width: renderPageA.width, height: renderPageA.height)
        resizePages(for: size)
        iterationCount = 0
    }
    
    private func resizePages(for size: CGSize) {
        guard size.width * size.height != 0 else {
            renderPageA = nil
            renderPageB = nil
            return
        }
        
        let d = MTLTextureDescriptor()
        d.pixelFormat = .rgba32Float
        d.width = Int(size.width)
        d.height = Int(size.height)
        d.cpuCacheMode = .writeCombined
        d.usage = [.shaderRead, .shaderWrite]
        
        renderPageA = device.makeTexture(descriptor: d)
        renderPageB = device.makeTexture(descriptor: d)
        renderPageA.zero(pixelSize: MemoryLayout<Float32>.size * 4)
        renderPageB.zero(pixelSize: MemoryLayout<Float32>.size * 4)
        
        threadgroupSizes = pipeline.threadgroupSizesForDrawableSize(size)
    }
    
    private func synchronizeBuffer() {
        let ptr = userArgumentsBuffer.contents().bindMemory(to: UInt32.self, capacity: argumentsPaths.count)
        for i in 0..<argumentsPaths.count {
            let p = argumentsPaths[i]
            ptr[i] = self[keyPath: p]
        }
    }
    
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        resizePages(for: size)
    }
    
    public func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable else {
            return
        }
        
        commandQueue.computeAndDraw(into: drawable, with: threadgroupSizes) {
            iterationCount += 1
            synchronizeBuffer()
            
            $0.setTexture(renderPageA, index: 1)
            $0.setTexture(renderPageB, index: 2)
            $0.setBuffer(userArgumentsBuffer, offset: 0, index: 0)
            $0.setComputePipelineState(pipeline)
            
            swap(&renderPageA, &renderPageB)
        }
    }
}

class ViewController: NSViewController {
    
    let mtkview = MTKView()
    let source = URL(fileURLWithPath: "/Users/mrwerdo/Developer/FractalGenerator/Sources/Display/Shaders.metal")
    let shaderName = "mandelbrotShaderHighResolution"
    var delegate: OverTimeFractalComputer?
    
    override func loadView() {
        view = mtkview
        mtkview.framebufferOnly = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let device = MTLCreateSystemDefaultDevice() else {
            return
        }
        
        do {
            mtkview.device = device
            mtkview.colorPixelFormat = MTLPixelFormat.bgra8Unorm
            delegate = try OverTimeFractalComputer(device: device,
                                                   shaderSource: source,
                                                   functionName: shaderName)
            mtkview.delegate = delegate
        } catch {
            print(error)
        }
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        mtkview.delegate?.mtkView(mtkview, drawableSizeWillChange: mtkview.frame.size)
    }
}

let k = 100
let frame = CGRect(x: 0, y: 0, width: 16 * k, height: 9 * k)
let app = FAppDelegate(frame: frame)
app.controller = ViewController()
app.controller.view.frame = frame
app.run()
