//
//  OverTimeFractalGenerator.swift
//  FractalGenerator
//
//  Created by Andrew Thompson on 2/9/17.
//

import Foundation
import MetalKit
import Support

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
                // http://stackoverflow.com/a/2745086/23649
                
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

extension Complex {
    var real_uint32: UInt32 {
        return Float32(real).bitPattern
    }
    
    var imag_uint32: UInt32 {
        return Float32(imaginary).bitPattern
    }
}

public class OverTimeFractalComputer: NSObject, MTKViewDelegate {
    
    private var commandQueue: MTLCommandQueue
    public private(set) var device: MTLDevice
    
    private var threadgroupSizes: ThreadgroupSizes
    private var shaderFunction: MTLFunction
    private var scrollerFunction: MTLFunction
    private var realtimeShaderPipeline: MTLComputePipelineState
    private var scrollerPipeline: MTLComputePipelineState
    private var renderPageA: MTLTexture!
    private var renderPageB: MTLTexture!
    private var userArgumentsBuffer: MTLBuffer
    private var argumentsPaths: [KeyPath<OverTimeFractalComputer, UInt32>] = [
        \.iterationCount,
        \.framesThisIteration,
        \.argandDiagramFrame.topLeft.real_uint32,
        \.argandDiagramFrame.topLeft.imag_uint32,
        \.argandDiagramFrame.bottomRight.real_uint32,
        \.argandDiagramFrame.bottomRight.imag_uint32
    ]
    
    private var needsClear: Bool = true
    public var isComplete: Bool {
        return iterationCount >= iterationLimit
    }
    public private(set) var iterationCount: UInt32 = 0
    public var argandDiagramFrame: ComplexRect {
        didSet {
            needsClear = true
        }
    }
    public var iterationLimit: UInt32 = 2000
    public var iterationsPerFrame: UInt32 = 100
    public var minimumIterationCount: UInt32 = 200
    public var isScrolling: Bool = false
    
    private var isInitialIterationComplete: Bool = false
    
    private var framesThisIteration: UInt32 {
        return isInitialIterationComplete ? iterationsPerFrame : minimumIterationCount
    }
    
    public var shaderName: String {
        return shaderFunction.name
    }
    
    public enum InitError: Error {
        case couldNotMakeCommandQueue
        case couldNotMakeBuffer
    }
    
    public init(device d: MTLDevice, shader sf: MTLFunction, scroller: MTLFunction, plane: ComplexRect) throws {
        device = d
        threadgroupSizes = .zeros
        argandDiagramFrame = plane
        shaderFunction = sf
        scrollerFunction = scroller
        
        guard let cq = device.makeCommandQueue() else {
            throw InitError.couldNotMakeCommandQueue
        }
        
        let length = MemoryLayout<UInt32>.size * argumentsPaths.count
        guard let bf = device.makeBuffer(length: length, options: []) else {
            throw InitError.couldNotMakeBuffer
        }
        
        realtimeShaderPipeline = try device.makeComputePipelineState(function: sf)
        scrollerPipeline = try device.makeComputePipelineState(function: scroller)
        commandQueue = cq
        userArgumentsBuffer = bf
    }
    
    public func reset() {
        renderPageA.zero(pixelSize: MemoryLayout<Float32>.size * 4)
        renderPageB.zero(pixelSize: MemoryLayout<Float32>.size * 4)
        iterationCount = 0
        needsClear = false
        isInitialIterationComplete = false
    }
    
    private func resizePages(for size: CGSize) {
        renderPageA = nil
        renderPageB = nil
        
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
        threadgroupSizes = realtimeShaderPipeline.threadgroupSizesForDrawableSize(size)
        reset()
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
    
    func drawRealTimeShader(encoder: MTLComputeCommandEncoder, drawable: CAMetalDrawable) {
        if needsClear {
            reset()
        }
        if !isInitialIterationComplete {
            iterationCount = minimumIterationCount
        } else {
            iterationCount += 1
        }
        synchronizeBuffer()
        isInitialIterationComplete = true
        
        encoder.setTexture(drawable.texture, index: 0)
        encoder.setTexture(renderPageA, index: 1)
        encoder.setTexture(renderPageB, index: 2)
        encoder.setBuffer(userArgumentsBuffer, offset: 0, index: 0)
        encoder.setComputePipelineState(realtimeShaderPipeline)
        
        swap(&renderPageA, &renderPageB)
    }
    
    func drawScrolling(encoder: MTLComputeCommandEncoder, drawable: CAMetalDrawable) {
        synchronizeBuffer()
        encoder.setTexture(drawable.texture, index: 0)
        encoder.setTexture(renderPageA, index: 1)
        encoder.setBuffer(userArgumentsBuffer, offset: 0, index: 0)
        encoder.setComputePipelineState(scrollerPipeline)
    }
    
    public func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable else {
            return
        }
        
        if threadgroupSizes.hasZeroDimension {
            return
        }
        
        autoreleasepool {
            guard let buffer = commandQueue.makeCommandBuffer(),
                let encoder = buffer.makeComputeCommandEncoder() else {
                    return
            }

            if isScrolling {
                drawScrolling(encoder: encoder, drawable: drawable)
            } else {
                drawRealTimeShader(encoder: encoder, drawable: drawable)
            }
            
            encoder.dispatchThreadgroups(threadgroupSizes.threadgroupsPerGrid, threadsPerThreadgroup: threadgroupSizes.threadsPerThreadgroup)
            encoder.endEncoding()
            
            buffer.present(drawable)
            buffer.commit()
        }
    }
}
