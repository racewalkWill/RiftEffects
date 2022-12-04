//
//  Renderer.swift
//  Glance
//
//  Created by Will on 2/27/19.
//  Copyright © 2019 Will Loew-Blosser. All rights reserved.
//  Based on Apple Sample App "BasicTexturing"


import MetalKit
import os

var TargetSize = CGSize(width: 1040, height: 768)
var DoNotDraw = false

enum VertexInputIndex : Int {
    case vertices = 0
    case viewportSize = 1
}

enum TextureIndex : Int {
    case baseColor = 0
}
struct RenderVertex {
    var position: simd_float2
        //  A vector of two 32-bit floating-point numbers.
    var textureCoordinate: simd_float2
}


class Renderer: NSObject {

     var device: MTLDevice!
     var commandQueue: MTLCommandQueue!
     var colorPixelFormat: MTLPixelFormat!
//    var texture: MTLTexture!


    static let quadVertices: [Float] = [
        -1,  1,  0,    // triangle 1
         1, -1,  0,
        -1, -1,  0,
        -1,  1,  0,    // triangle 2
         1,  1,  0,
         1, -1,  0
      ]

//    var translation: matrix_float4x4


    var pipelineState: MTLRenderPipelineState!

    let colorSpace = CGColorSpaceCreateDeviceRGB() // or CGColorSpaceCreateDeviceCMYK() ?
    var mtkViewSize: CGSize!
    var viewportSize: vector_uint2!

    var library: MTLLibrary!
    var textureLoader: MTKTextureLoader!
    var vertexFunction: MTLFunction!
    var fragmentFunction: MTLFunction!
    var pipelineStateDescriptor: MTLRenderPipelineDescriptor! = MTLRenderPipelineDescriptor()
    var vertices: MTLBuffer?
    var numVertices: UInt32!

    var ciMetalContext: CIContext!
    static var ciContext: CIContext!  // global for filter detectors
    var appStack: PGLAppStack! = nil  // model object
    var filterStack: () -> PGLFilterStack?  = { PGLFilterStack() } // a function is assigned to this var that answers the filterStack
    let debugRender = false

    var currentPhotoFileFormat: PhotoLibSaveFormat!
    var offScreenRender: PGLOffScreenRender = PGLOffScreenRender()
    var numVerticesInt: Int!

    init(metalView: MTKView) {

        
        super.init()

        device = metalView.device
        metalView.framebufferOnly = true
            // "To optimize a drawable from an MTKView for GPU access, set the view’s framebufferOnly
            // property to true. This property configures the texture exclusively
            //  as a render target and displayable resource."
            // in WWDC 2020 "Optimize the Core Image pipeline for your video app" suggest false setting
            // see code at 7:24


        library = device.makeDefaultLibrary()
        vertexFunction = library.makeFunction(name: "vertexShader")
        fragmentFunction = library.makeFunction(name: "samplingShader")

        colorPixelFormat = metalView.colorPixelFormat
        // setup descriptor for creating a pipeline
        pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.label = "Texturing Pipeline"
        pipelineStateDescriptor.vertexFunction = vertexFunction
        pipelineStateDescriptor.fragmentFunction = fragmentFunction
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat

        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        }
        catch { return }
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        }
        catch { return }

        commandQueue = device.makeCommandQueue()!

// Rift related init
        metalView.delegate = self
        textureLoader = MTKTextureLoader(device: device)


        ciMetalContext = CIContext(mtlDevice: device,
                                options: [CIContextOption.workingFormat: CIFormat.RGBAh,
                                          .cacheIntermediates : false,
                                          .name : "metalView"] )
            //.cacheIntermediates : should be false if showing video per WWDC "Optimize the Core Image pipeline"
                    // but this app is NOT video !! and  value = false causes memory growth
                    // therefore use .cacheIntermediates : true 2020-10-16
            // changed to false 2022-07-27 the old buffer showing is fixed with the value false

        // set to half float intermediates for CIDepthBlurEffect as suggested in WWDC 2017
         // Editing with Depth 508
        //          https://developer.apple.com/videos/play/wwdc2017/508

        Renderer.ciContext = ciMetalContext

        metalView.autoResizeDrawable = true

        metalView.clearColor = MTLClearColor(red: 0.5, green: 0.5,
                                             blue: 0.8, alpha: 0.5)



        guard let myAppDelegate =  UIApplication.shared.delegate as? AppDelegate
            else {
            Logger(subsystem: LogSubsystem, category: LogCategory).error ("Renderer init(metalView fatalError( AppDelegate not loaded")
            return
        }

        appStack = myAppDelegate.appStack
        filterStack = { self.appStack.outputFilterStack() }

        let fileType = UserDefaults.standard.string(forKey:  "photosFileType")
        currentPhotoFileFormat = PhotoLibSaveFormat.init(rawValue: fileType ?? "HEIF")

        Logger(subsystem: LogSubsystem, category: LogCategory).info ("Renderer init currentPhotoFileFormat \(String(describing: self.currentPhotoFileFormat))")
    }

    func captureImage() throws -> UIImage? {
        // capture the current image in the context
        // provide a UIImage for save to photoLibrary
        // uses existing ciContext in a background process..

        if let ciOutput = filterStack()?.stackOutputImage(false) {
            let currentRect = filterStack()!.cropRect
            Logger(subsystem: LogSubsystem, category: LogCategory).debug ("Renderer #captureImage currentRect ")
            let croppedOutput = ciOutput.cropped(to: currentRect)
            guard let currentOutputImage = ciMetalContext.createCGImage(croppedOutput, from: croppedOutput.extent) else { return nil }

           

            Logger(subsystem: LogSubsystem, category: LogCategory).debug("Renderer #captureImage croppedOutput = \(croppedOutput)")

            return UIImage( cgImage: currentOutputImage, scale: UIScreen.main.scale, orientation: .up)
            // kaliedoscope needs down.. portraits need up.. why.. they both look .up in the imageController

            // let theOrientation = CGImagePropertyOrientation(theImage.imageOrientation)
//             pickedCIImage = convertedImage.oriented(theOrientation)

        } else {
            throw savePhotoError.jpegError}

    }

    func captureHEIFImage() throws -> Data? {
        // capture the current image in the context
        // provide a UIImage for save to photoLibrary
        // uses existing ciContext in a background process..

        if let ciOutput = filterStack()?.stackOutputImage(false) {

            let rgbSpace = CGColorSpaceCreateDeviceRGB()
            let options = [kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: 1.0 as CGFloat]
            guard let heifData =  ciMetalContext.heifRepresentation(of: ciOutput, format: .RGBA8, colorSpace: rgbSpace, options: options)
            else {
                    throw savePhotoError.nilReturn
            }

            Logger(subsystem: LogSubsystem, category: LogCategory).debug("Renderer #captureHEIFImage ")

            return heifData


            // kaliedoscope needs down.. portraits need up.. why.. they both look .up in the imageController

        } else {
            throw savePhotoError.heifError}

    }

}

extension Renderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
//        NSLog("Renderer mtkView drawableSize = \(view.drawableSize) drawableSizeWillChange = \(size)")
        if !((size.width > 0) && (size.height > 0)) {
            Logger(subsystem: LogSubsystem, category: LogCategory).fault("Renderer #drawableSizeWillChange size.width or height = 0 error")
            // this will cause Renderer draw fatalError (Render did not get the renderEncoder - draw(in: view
            // and [CAMetalLayer nextDrawable] returning nil because allocation failed.
        }
         mtkViewSize = size
        TargetSize = size
        viewportSize = vector_uint2(x: UInt32(size.width), y: UInt32(size.height))
        appStack.resetDrawableSize()
    }

    func draw(in view: MTKView) {
        var sizedciOutputImage: CIImage
        var imageTexture: MTLTexture
        if DoNotDraw {
            view.isHidden = DoNotDraw
            // view.isHidden for iPhone navigation to different mtkViews
            // view.isHidden = true so both mktViews are black.
            // reset to false if there is an image to show from the stack.. see below
            // and notification PGLImageCollectionOpen

            return }

        guard let currentStack = filterStack()
        else { return }
        let ciOutputImage = currentStack.stackOutputImage((appStack.showFilterImage))
        if view.isHidden {
                // check if there is now an image to show
            if ciOutputImage == CIImage.empty() {
                    // skip the render on empty image
                return
            } else {
                    // there is an image to show..
                view.isHidden = false
            }
        }
        if MainViewImageResize {
                // var MainViewImageResize defined globally in AppDelegate.swift
                // userSettings control the value
            sizedciOutputImage = ciOutputImage.cropped(to: currentStack.cropRect) }
        else
        { sizedciOutputImage = ciOutputImage }

            // image section
        guard let cgOutputImage = offScreenRender.basicRenderCGImage(source: sizedciOutputImage)
        else {
                return }
//        let loaderOptions = [ MTKTextureLoader.Option.textureStorageMode: MTLStorageMode.private ]
        
        do {  imageTexture = try textureLoader.newTexture(cgImage: cgOutputImage, options: nil ) }
        catch {
            return
        }


        // start render logic
        guard let descriptor = view.currentRenderPassDescriptor,
          let commandBuffer = commandQueue.makeCommandBuffer(),
          let renderEncoder =
          commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }
        commandBuffer.label = "RiftCommandBuffer"
        renderEncoder.label = "RiftRenderEncoder"

            // Set the region of the drawable to draw into.
        // origin is upper left corner, width,height are pixels
        // scale for aspectFit

//        let aspectFitViewportRect = aspectFitTransform(viewFrame: view.bounds, imageExtent: sizedciOutputImage.extent)



        // consider renderEncoder.setScissorRect(_:) to further trim
        // The rendering pipeline discards fragments that lie outside the scissor rectangle
        renderEncoder.setRenderPipelineState(pipelineState)


        // move vertices back to class? only changes on size change
        let scalar: Float32 = RendererScale
        var scalarX = scalar
        var scalarY = scalar

        if sizedciOutputImage.extent.width < sizedciOutputImage.extent.height {
            scalarY = scalar * Float((sizedciOutputImage.extent.height/sizedciOutputImage.extent.width))
            scalarX = scalar * Float((sizedciOutputImage.extent.width/sizedciOutputImage.extent.height)) // the inverse..
        }

        let quadVertices: [AAPLVertex] = [
            AAPLVertex(position: simd_float2(x: scalarX, y: -scalarY), textureCoordinate: simd_float2(x: 1.0, y: 1.0)),
            AAPLVertex(position: simd_float2(x: -scalarX, y: -scalarY), textureCoordinate: simd_float2(x: 0.0, y: 1.0)),
          AAPLVertex(position: simd_float2(x: -scalarX, y:  scalarY), textureCoordinate: simd_float2(x: 0.0, y: 0.0)),

          AAPLVertex(position: simd_float2(x: scalarX, y: -scalarY), textureCoordinate: simd_float2(x: 1.0, y: 1.0)),
          AAPLVertex(position: simd_float2(x: -scalarX, y:  scalarY), textureCoordinate: simd_float2(x: 0.0, y: 0.0)),
          AAPLVertex(position: simd_float2(x:scalarX, y: scalarY), textureCoordinate: simd_float2(x: 1.0, y: 0.0)),
              ]


            // The output position of every vertex shader is in clip space (also known as normalized device
            //   coordinate space, or NDC). A value of (-1.0, -1.0) in clip-space represents the
            //   lower-left corner of the viewport whereas (1.0, 1.0) represents the upper-right corner of
            //   the viewport.

        let bufferBytes =  quadVertices.count * MemoryLayout<AAPLVertex>.stride

        vertices = view.device?.makeBuffer(bytes: quadVertices,
                                                    length: bufferBytes,
                                                    options: MTLResourceOptions.storageModeShared)
        numVertices = UInt32(quadVertices.count)
        numVerticesInt = quadVertices.count
        renderEncoder.setVertexBuffer(vertices, offset: 0,
                                      index: VertexInputIndex.vertices.rawValue)
        renderEncoder.setVertexBytes( &viewportSize!,
                                      length: MemoryLayout<vector_uint2>.size,
                                      index: VertexInputIndex.viewportSize.rawValue)

            // create the transform matrix

//            // image section
//            guard let cgOutputImage = offScreenRender.basicRenderCGImage(source: sizedciOutputImage)
//        else {  renderEncoder.endEncoding()
//                    return } // no image to show }
//            do {  imageTexture = try textureLoader.newTexture(cgImage: cgOutputImage, options: nil ) }
//            catch {renderEncoder.endEncoding()
//                    return }
            // end image section

        renderEncoder.setFragmentTexture(imageTexture, index: TextureIndex.baseColor.rawValue)
        renderEncoder.drawPrimitives(type: MTLPrimitiveType.triangle, vertexStart: 0, vertexCount: numVerticesInt )

            // [MTKTextureLoader.Option : Any]? MTKTextureLoader.Option must be added)
            // release cgOutputImage after loading into texture
            // NOT clear how to do a release...

        renderEncoder.endEncoding()
        
        commandBuffer.present(view.currentDrawable!)
        commandBuffer.commit()
    }


}

class Primitive {
    class func cube(device: MTLDevice, size: Float) -> MDLMesh {
        let allocator = MTKMeshBufferAllocator(device: device)
        let mesh = MDLMesh(boxWithExtent: [size, size, size],
                           segments: [1, 1, 1],
                           inwardNormals: false, geometryType: .triangles,
                           allocator: allocator)
        return mesh
    }
}
