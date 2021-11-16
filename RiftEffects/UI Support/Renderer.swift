//
//  Renderer.swift
//  Glance
//
//  Created by Will on 2/27/19.
//  Copyright © 2019 Will Loew-Blosser. All rights reserved.
//  Based on Metal By Tutorials, Caroline Begbie & Marius Horga

/**
 * Copyright (c) 2018 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import MetalKit
import os
var TargetSize = CGSize(width: 1040, height: 768)
var DoNotDrawWhileSave = false

class Renderer: NSObject {

    static var device: MTLDevice!
    static var commandQueue: MTLCommandQueue!
    static var ciContext: CIContext!  // global for filter detectors

    var pipelineState: MTLRenderPipelineState!
    var ciContext: CIContext!
    let colorSpace = CGColorSpaceCreateDeviceRGB() // or CGColorSpaceCreateDeviceCMYK() ?
    var mtkViewSize: CGSize!

    var appStack: PGLAppStack! = nil  // model object
    var filterStack: () -> PGLFilterStack?  = { PGLFilterStack() } // a function is assigned to this var that answers the filterStack

    let debugRender = false

    var currentPhotoFileFormat: PhotoLibSaveFormat!



    init(metalView: MTKView) {
        super.init()
        guard let device = MTLCreateSystemDefaultDevice() else {
            Logger(subsystem: LogSubsystem, category: LogCategory).fault ("Renderer init(metalView fatalError( GPU not available")
            return
        }
        metalView.device = device
        metalView.framebufferOnly = false // from WWDC 2020 "Optimize the Core Image pipeline for your video app"
            // see code at 7:24
        Renderer.device = device
        Renderer.commandQueue = device.makeCommandQueue()!

//        let mdlMesh = Primitive.cube(device: device, size: 1.0)
//        mesh = try! MTKMesh(mesh: mdlMesh, device: device)
//        vertexBuffer = mesh.vertexBuffers[0].buffer

        _ = device.makeDefaultLibrary()

        metalView.device = device

        
        ciContext = CIContext(mtlDevice: device,
                                options: [CIContextOption.workingFormat: CIFormat.RGBAh,
                                          .cacheIntermediates : true,
                                          .name : "metalView"] )
            //.cacheIntermediates : should be false if showing video per WWDC "Optimize the Core Image pipeline"
            // but this app is NOT video !! and  value = false causes memory growth
            // therefore use .cacheIntermediates : true 2020-10-16

        // set to half float intermediates for CIDepthBlurEffect as suggested in WWDC 2017
         // Editing with Depth 508
        //          https://developer.apple.com/videos/play/wwdc2017/508

        Renderer.ciContext = ciContext
        
        metalView.autoResizeDrawable = true



        metalView.clearColor = MTLClearColor(red: 1.0, green: 1.0,
                                             blue: 0.8, alpha: 1)
        metalView.delegate = self
        guard let myAppDelegate =  UIApplication.shared.delegate as? AppDelegate
            else {
            Logger(subsystem: LogSubsystem, category: LogCategory).error ("Renderer init(metalView fatalError( AppDelegate not loaded")
            return

        }

        appStack = myAppDelegate.appStack
        filterStack = { self.appStack.outputFilterStack() }

//        let fileType = UserDefaults.init().string(forKey:  "photosFileType")
            // above works..
        
        let fileType = AppUserDefaults.string(forKey:  "photosFileType")
        currentPhotoFileFormat = PhotoLibSaveFormat.init(rawValue: fileType ?? "JPEG")


        NSLog("Renderer init currentPhotoFileFormat \(String(describing: currentPhotoFileFormat))")
    }

    func captureImage() throws -> UIImage? {
        // capture the current image in the context
        // provide a UIImage for save to photoLibrary
        // uses existing ciContext in a background process..

        if let ciOutput = filterStack()?.stackOutputImage(false) {
            let currentRect = filterStack()!.cropRect
            Logger(subsystem: LogSubsystem, category: LogCategory).debug ("Renderer #captureImage currentRect ")
            let croppedOutput = ciOutput.cropped(to: currentRect)
            guard let currentOutputImage = ciContext.createCGImage(croppedOutput, from: croppedOutput.extent) else { return nil }

           

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
            guard let heifData =  ciContext.heifRepresentation(of: ciOutput, format: .RGBA8, colorSpace: rgbSpace, options: options)
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
         mtkViewSize = size
        TargetSize = size
        appStack.resetDrawableSize()
    }

    func draw(in view: MTKView) {
        var sizedciOutputImage: CIImage
        if DoNotDrawWhileSave { return }
        guard let descriptor = view.currentRenderPassDescriptor,
            let commandBuffer = Renderer.commandQueue.makeCommandBuffer(),
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            Logger(subsystem: LogSubsystem, category: LogCategory).fault ("Renderer draw fatalError (Render did not get the renderEncoder - draw(in: view")
                return
        }
        if let currentStack = filterStack()  {
            if currentStack.activeFilters.isEmpty {
                renderEncoder.endEncoding()
                return
            }
            let ciOutputImage = currentStack.stackOutputImage((appStack.showFilterImage))

            if mainViewImageResize {
            // var mainViewImageResize defined globally in AppDelegate.swift
                 sizedciOutputImage = ciOutputImage.cropped(to: currentStack.cropRect) }
            else
                { sizedciOutputImage = ciOutputImage }

            if sizedciOutputImage.extent.isInfinite {
//                           NSLog("Renderer  #draw has output image infinite extent")
                       }


        if let currentDrawable = view.currentDrawable {
            
            if let commandBuffer = Renderer.commandQueue.makeCommandBuffer() {
                if view.currentRenderPassDescriptor != nil {
            ciContext?.render(sizedciOutputImage ,
                to: currentDrawable.texture,
                commandBuffer: commandBuffer , // nil , commandBuffer   // a command buffer that is not nil is used again. this is the old images coming in..
                bounds: sizedciOutputImage.extent , // ciOutputImage.extent,
                colorSpace: colorSpace)


            renderEncoder.endEncoding()

            commandBuffer.present(currentDrawable)
            commandBuffer.commit()

            // possible metal refs that are not released
            // compare to the allocations listing
//            NSLog("draw descriptor \(descriptor)")
//            NSLog("draw commandBuffer \(commandBuffer)")
//            NSLog("draw renderEncoder \(renderEncoder)")
//            NSLog("draw currentDrawable \(currentDrawable)")

                }
                else {
                    Logger(subsystem: LogSubsystem, category: LogCategory).error ("Renderer draw fatalError( Render did not get the current currentRenderPassDescriptor - draw(in: view")}
            }
            else {Logger(subsystem: LogSubsystem, category: LogCategory).error ("Renderer draw fatalError( fatalError(Render did not get the current view.commandBuffer - draw(in: view")}
        }
        else { Logger(subsystem: LogSubsystem, category: LogCategory).error ("Renderer drawfatalError( Render did not get the current view.currentDrawable - draw(in: view") }
        }
        else { Logger(subsystem: LogSubsystem, category: LogCategory).error ("Renderer draw fatalError(Render did not get the current filterStack - draw(in: view")}

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
