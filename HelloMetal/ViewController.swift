//
//  ViewController.swift
//  HelloMetal
//
//  Created by Russell Gordon on 2015-12-20.
//  Copyright © 2015 Royal St. George's College. All rights reserved.
//
//  Implementation based on tutorial at:
//  http://www.raywenderlich.com/77488/ios-8-metal-tutorial-swift-getting-started
//
//  With bits from:
//  https://github.com/rlnasuti/HelloMetakitOSX
//  ... to make this work on Xcode7 and iOS 9.

import UIKit
import Metal
import QuartzCore       // Needed to get backing layer (CAMetalLayer)

class ViewController: UIViewController {
    
    // Establish connection to GPU on this device
    var device: MTLDevice! = nil
    
    // The backing layer required to render Metal graphics
    var metalLayer: CAMetalLayer! = nil
    
    // The buffer that will store the shape to draw
    var vertexBuffer: MTLBuffer! = nil
    
    // The render pipeline property, to keep track of compiled render pipeline
    var pipelineState: MTLRenderPipelineState! = nil
    
    // Timer object to ensure screen is drawn again when device screen refreshes
    var timer: CADisplayLink! = nil

    // Ordered list of commands you tell the GPU to execute, one at a time
    var commandQueue : MTLCommandQueue! = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // GETTING STARTED, STEP 1: Create a connection to GPU (device that will run Metal commands)
        
        // Returns a reference to the default MTL device (GPU)
        device = MTLCreateSystemDefaultDevice()
        
        // GETTING STARTED, STEP 2: Create a CAMetal Layer
        
        metalLayer = CAMetalLayer()             // Create a new metal backing layer
        metalLayer.device = device              // Set layer's device to one just created
        metalLayer.pixelFormat = .BGRA8Unorm    // Set pixel format
        metalLayer.framebufferOnly = true       // Set for performance reasons (see tutorial for further explanation)
        metalLayer.frame = view.layer.frame     // Frame of layer matches the frame of this view
        view.layer.addSublayer(metalLayer)      // Add metal layer as sub layer of the view's main layer
        
        // GETTING STARTED, STEP 3: Create a Vertex Buffer
        
        // Create a buffer to represent simple triangle shown here:
        // http://cdn5.raywenderlich.com/wp-content/uploads/2014/07/4_vertices-320x320.jpg
        let vertexData:[Float] = [
         0.0,  1.0, 0.0,
        -1.0, -1.0, 0.0,
         1.0, -1.0, 0.0]
        
        // Get the size of the vertex data in bytes
        //              count of elements * size of first element
        let dataSize = vertexData.count * sizeofValue(vertexData[0])
        
        // Create a new buffer on the GPU, passing in the data from the CPU
        // Options argument varies from tutorial where 'nil' was passed
        // Found options list for this parameter here:
        //  https://developer.apple.com/library/ios/documentation/Metal/Reference/MTLResource_Ref/index.html#//apple_ref/swift/struct/c:@E@MTLResourceOptions
        vertexBuffer = device.newBufferWithBytes(vertexData, length: dataSize, options: MTLResourceOptions.CPUCacheModeDefaultCache)
        
        // GETTING STARTED, STEP 6: Create a Render Pipeline
        
        // Shaders are pre-compiled, creating a library lets us look them up and use them by name later
        let defaultLibrary = device.newDefaultLibrary()
        let vertexProgram = defaultLibrary!.newFunctionWithName("basic_vertex")
        let fragmentProgram = defaultLibrary!.newFunctionWithName("basic_fragment")
        
        // Set up render pipeline configuration (shaders and pixel format for color attachment)
        // Set color system to same as the output buffer – the CAMetalLayer.
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .BGRA8Unorm
        
        // Compile the pipeline configuration (more efficient to use this going forward)
        do {
            try pipelineState = device.newRenderPipelineStateWithDescriptor(pipelineStateDescriptor)
        } catch let pipelineError {
            print("Failed to create pipeline state, error \(pipelineError)")
        }
        
        // GETTING STARTED, STEP 7: Create a Command Queue
        
        // A command queue is an ordered list of commands that you tell the GPU to execute
        commandQueue = device.newCommandQueue()
        
        // RENDERING THE TRIANGLE, STEP 1: Create a display link
        
        // Set things up so that the gameLoop() method is called every time the screen refreshes
        timer = CADisplayLink(target: self, selector: Selector("gameLoop"))
        timer.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // RENDERING THE TRIANGLE, STEP 2: Create a Render Pass Descritor
    // A render pass descriptor is an object that configures what texture is being rendered to, what the clear color is,
    // and a few other things (not sure what though – seems to be only two lines?)
    func render() {

        // Get a drawable layer
        let drawable = metalLayer.nextDrawable()

        // Create the render pass descriptor
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable!.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .Clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 104.0/255.0, blue: 5/255.0, alpha: 1.0)

        // RENDERING THE TRIANGLE, STEP 3: Create a command buffer
        // This is the list of render commands that you wish to execute for this frame of animation
        // Note that nothing actually happens until you commit the command buffer; this gives very
        // fine grained control over when things occur on the GPU
        let commandBuffer = commandQueue.commandBuffer()
        
        // RENDERING THE TRIANGLE, STEP 4: Create a render command encoder
        // Creating a render command requires a helper object called a 'render command encoder'
        let renderEncoderOptional: MTLRenderCommandEncoder! = commandBuffer.renderCommandEncoderWithDescriptor(renderPassDescriptor)
        if let renderEncoder = renderEncoderOptional {
            renderEncoder.setRenderPipelineState(pipelineState)
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, atIndex: 0)
            // Here we tell the GPU to draw a set of traingles, based on the vertex buffer created earlier
            // Each triangle consists of 3 vertices, starting at index 0 inside the buffer, and there is 1 triangle total
            renderEncoder.drawPrimitives(.Triangle, vertexStart: 0, vertexCount: 3, instanceCount: 1)
            // NOTE TO SELF: Could you draw many instances at once? Why would you want to do that?
            //               Wouldn't they draw on top of each other in the same position?
            // NOTE TO SELF: Could we draw many primitives at once on this same render command encoder?
            renderEncoder.endEncoding()
            
        }
        
    }
    
    // gameLoop calls render for each frame of animation
    func gameLoop() {
        autoreleasepool {
            self.render()
        }
    }


}

