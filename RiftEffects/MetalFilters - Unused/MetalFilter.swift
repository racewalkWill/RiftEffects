//
//  MetalFilter.swift
//  Glance
//
//  Created by Will on 2/26/19.
//  Copyright © 2019 Will Loew-Blosser. All rights reserved.
//
//  Derived from
//  MetalFilters.swift
//  Filterpedia
//
//  Created by Simon Gladman on 24/01/2016.
//  Copyright © 2016 Simon Gladman. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.

//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>

// THE METAL SHADER KERNELS are not compiled when the -cikernel flags are set..
// COMMENTED OUT the filters.. and MetalFilter class
import MetalKit

// MARK: MetalFilter types


//
//class MetalFilter: CIFilter, MetalRenderable
//{       // uses MTLComputePipelineState process to GPU
//    var device = Renderer.device!
//    let colorSpace = CGColorSpaceCreateDeviceRGB()
//
//    // these vars are set later
//    lazy var ciContext: CIContext =
//        {
//            [unowned self] in
//
//            return CIContext(mtlDevice: self.device)
//            }()
//
//    lazy var commandQueue: MTLCommandQueue =
//        {
//            [unowned self] in
//
//            return self.device.makeCommandQueue()
//            }()!
//
//    lazy var defaultLibrary: MTLLibrary =
//        {
//            [unowned self] in
//
//            return self.device.makeDefaultLibrary()!
//            }()
//
//
//
//    var pipelineState: MTLComputePipelineState?
//
//    var functionName: String = ""
//
//    var threadsPerThreadgroup: MTLSize!
//    var threadgroupsPerGrid: MTLSize?
//    var textureDescriptor: MTLTextureDescriptor?
//    var textureDescriptorOut: MTLTextureDescriptor? //  fixes error in iOS9.1 in #imageFromComputeShader
//
//    var kernelInputTexture: MTLTexture?
//    var kernelOutputTexture: MTLTexture?
//    let emptyImage = CIImage.empty() // allocate only once for logic tests
//
//    override var outputImage: CIImage!
//    {   let outputTexture: CIImage
//        var inputWidth:CGFloat = 640
//        var inputHeight:CGFloat = 640
//
//        if textureInvalid()
//        {
//            self.textureDescriptor = nil // resets textDescriptor in the imageFromComputeShader
//        }
//
//        if let inputImage = self.inputImage(),
//            inputImage != emptyImage
//        {       inputWidth =  inputImage.extent.width
//                inputHeight = inputImage.extent.height
//             outputTexture = imageFromComputeShader(width: inputWidth,
//                                              height: inputHeight,
//                                              inputImage: inputImage)  // for generator inputImage is nil
//
//            return outputTexture
//        } else { return emptyImage}
//
//    }
//
//
//
//    init(kernelFunctionName: String)
//    {
//        super.init()
//        functionName = kernelFunctionName
//        setKernelFunction()
//    }
//
//
//     func setKernelFunction() {
//
//        let kernelFunction = defaultLibrary.makeFunction(name: self.functionName)!
//
//        do
//        {
//            pipelineState = try self.device.makeComputePipelineState(function: kernelFunction)
//
//            let maxTotalThreadsPerThreadgroup = Double(pipelineState!.maxTotalThreadsPerThreadgroup)
//            let threadExecutionWidth = Double(pipelineState!.threadExecutionWidth)
//
//            var threadsPerThreadgroupSide = stride(from: 0,
//                                                   to: Int(sqrt(maxTotalThreadsPerThreadgroup)),
//                                                   by: 1).reduce(16)
//                                                   {
//                                                    return (Double($1 * $1) / threadExecutionWidth).truncatingRemainder(dividingBy: 1) == 0 ? $1 : $0
//            }
//
//            threadsPerThreadgroupSide = max(threadsPerThreadgroupSide, 1) // min of 1
//            threadsPerThreadgroup = MTLSize(width:threadsPerThreadgroupSide,
//                                            height:threadsPerThreadgroupSide,
//                                            depth:1)
//
//        }
//        catch
//        {
//            fatalError("Unable to create pipeline state for kernel function \(functionName)")
//        }
//
//
//
////        if !(self is MetalCIImageFilter) && !(self is MetalCIGeneratorFilter)
////        {
////            fatalError("MetalFilters must subclass either MetalImageFilter or MetalGeneratorFilter")
////        }
//    }
//
//
//
//
//    required init?(coder aDecoder: NSCoder)
//    {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//
//    func inputImage() -> CIImage?  {
//
//        if isImageInput() {
//            return value( forKey: kCIInputImageKey) as? CIImage }
//        else { return nil }
//
//    }
//
//    func isImageInput() -> Bool {
//
//
//      return  inputKeys.contains{ ( keyName: String ) -> Bool in
//           (attributes[keyName] as! [String:AnyObject] )[kCIAttributeClass] as? String == "CIImage"
//        }
//
//    }
//
//    func textureInvalid() -> Bool
//    {
//        if let textureDescriptor = textureDescriptor,
//            let inputImage = inputImage(),
//            textureDescriptor.width != Int(inputImage.extent.width)  ||
//                textureDescriptor.height != Int(inputImage.extent.height)
//        {
//            return true
//        }
//
//        return false
//    }
//
//
//     func setFloatBuffer(_ inputKey: String ) -> MTLBuffer? {
//        
//        guard var bufferValue: Float = self.value(forKey: inputKey) as? Float else {
//            fatalError(" (\(inputKey) key value float is not set. Buffer fails") }
//        return  device.makeBuffer(bytes: &bufferValue ,
//                                        length: MemoryLayout<Float>.size.self,
//                                        options: MTLResourceOptions(rawValue: UInt(MTLCPUCacheMode.defaultCache.rawValue)))
//
//
//
//    }
//
//    func setColorBuffer(_ inputKey: String ) -> MTLBuffer? {
//
//        guard let bufferValue: CIColor = value(forKey: inputKey) as? CIColor else {
//            fatalError(" (\(inputKey) key value  color is not set. Buffer fails") }
//        var color = float4(Float(bufferValue.red),
//                           Float(bufferValue.green),
//                           Float(bufferValue.blue),
//                           Float(bufferValue.alpha))
//
//        return  device.makeBuffer(bytes: &color,
//                                       length: MemoryLayout<float4>.size.self,
//                                       options: MTLResourceOptions(rawValue: UInt(MTLCPUCacheMode.defaultCache.rawValue)))
//
//
//
//    }
//
//    func setVectorBuffer(_ inputKey: String ) -> MTLBuffer? {
//
//        guard let bufferValue: CIVector = value(forKey: inputKey) as? CIVector else {
//            fatalError(" (\(inputKey) key value  vector is not set. Buffer fails") }
//        var pointVector = float2(Float(bufferValue.x),
//                           Float(bufferValue.y))
//
//        return  device.makeBuffer(bytes: &pointVector,
//                                  length: MemoryLayout<float2>.size.self,
//                                  options: MTLResourceOptions(rawValue: UInt(MTLCPUCacheMode.defaultCache.rawValue)))
//
//
//
//    }
//
//    
//    func imageFromComputeShader(width: CGFloat, height: CGFloat, inputImage: CIImage?) -> CIImage
//    {   // this is a computeCommand type of processing on the GPU
//        if textureDescriptor == nil
//        {
//            textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm,
//                                                                         width: Int(width),
//                                                                         height: Int(height),
//                                                                         mipmapped: false)
//            textureDescriptor!.usage = [MTLTextureUsage.shaderRead, MTLTextureUsage.shaderWrite ]
//            kernelInputTexture = device.makeTexture(descriptor: textureDescriptor!)
//
//            textureDescriptorOut = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm,
//                                                                            width: Int(width),
//                                                                            height: Int(height),
//                                                                            mipmapped: false)
//            textureDescriptorOut!.usage = [MTLTextureUsage.shaderRead, MTLTextureUsage.shaderWrite ]
//            kernelOutputTexture =  device.makeTexture(descriptor: textureDescriptorOut!)
//
//            threadgroupsPerGrid = MTLSizeMake(
//                textureDescriptor!.width / threadsPerThreadgroup.width,
//                textureDescriptor!.height / threadsPerThreadgroup.height, 1)
//        }
//
//        let commandBuffer = commandQueue.makeCommandBuffer()
//        if inputImage != nil {
//            ciContext.render(inputImage!,
//                                 to: kernelInputTexture!,
//                                 commandBuffer: commandBuffer,
//                                 bounds: inputImage!.extent,
//                                 colorSpace: colorSpace) }
//
//
//        let commandEncoder = commandBuffer?.makeComputeCommandEncoder()
//
//        commandEncoder?.setComputePipelineState(pipelineState!)
//
//        // populate  buffers using kCIAttributeIdentity as buffer index
//         for inputKey in inputKeys {
//            var inputBuffer: MTLBuffer?
//            if let attributeDict  = attributes[inputKey] as? [String:AnyObject] {
//                if let attributeClass =  attributeDict[kCIAttributeClass] as? String,
//                    let bufferIndex = attributeDict[kCIAttributeIdentity] as? Int {
//                    switch attributeClass {
//                    case "NSNumber":
//                       inputBuffer = setFloatBuffer( inputKey )
//                    case "CIColor" :
//                       inputBuffer = setColorBuffer( inputKey )
//                    case "CIVector":
//                        inputBuffer = setVectorBuffer( inputKey )
//                    default:
//                        break
//                }
//            if inputBuffer != nil {commandEncoder?.setBuffer(inputBuffer, offset: 0, index: bufferIndex) }
//            }
//            
//            }
//        }
//        
//
//        if  self.inputImage() != nil
//        {
//            commandEncoder?.setTexture(kernelInputTexture, index: 0)
//            commandEncoder?.setTexture(kernelOutputTexture, index: 1)
//        }
//        else
//        {
//            commandEncoder?.setTexture(kernelOutputTexture, index: 0)
//        }
//
//        commandEncoder?.dispatchThreadgroups(threadgroupsPerGrid!,
//                                             threadsPerThreadgroup: threadsPerThreadgroup)
//
//        commandEncoder?.endEncoding()
//        // commandBuffer.present.. wait for the GPU !
//
//        commandBuffer?.commit()
//
//        let myValue = CIImage(mtlTexture: kernelOutputTexture!,
//                       options: [CIImageOption.colorSpace: colorSpace])!
//        return myValue
//    }
//}
//protocol MetalRenderable {
//
//}

