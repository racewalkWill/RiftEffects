//
//  PGLSaliencyBlur.swift
//  Surreality
//
//  Created by Will on 1/18/21.
//  Copyright © 2021 Will Loew-Blosser. All rights reserved.
//

import Foundation
import CoreImage
import Vision

class PGLSaliencyBlurFilter: CIFilter {
    // attention based saliency with Gaussian Blur
    class override var supportsSecureCoding: Bool { get {
        // subclasses must  implement this
        // Core Data requires secureCoding to store the filter
        return true
    }}
    
    @objc dynamic   var inputImage: CIImage?
    @objc dynamic   var inputRadius: NSNumber = 10.0

    @objc    class func customAttributes() -> [String: Any] {
            let customDict:[String: Any] = [
                kCIAttributeFilterDisplayName : "Saliency Blur",

                kCIAttributeFilterCategories :
                    [kCICategoryBlur, kCICategoryInterlaced, kCICategoryNonSquarePixels, kCICategoryStillImage] ,

                "inputRadius" :  [
                        kCIAttributeMin       :  0.0,
                        kCIAttributeSliderMin :  0.0,
                        kCIAttributeSliderMax : 30.0,
                        kCIAttributeDefault   : 10.0,
                        kCIAttributeIdentity  :  0.0,
                        kCIAttributeType      : kCIAttributeTypeScalar
                ] as [String : Any]

                ]


            return customDict
        }


    @objc dynamic  override var outputImage: CIImage? {
        get { return imageChain()  }
    }

    func createHeatMapMask(from observation: VNSaliencyImageObservation) -> CIImage? {
        let pixelBuffer = observation.pixelBuffer
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let vector = CIVector(x: 0, y: 0, z: 0, w: 1)
        let saliencyImage = ciImage.applyingFilter("CIColorMatrix", parameters: ["inputBVector": vector])

        return saliencyImage
    }

    func processSaliency() ->  CIImage {
        guard let input = inputImage else {
            return CIImage.empty()
        }
        let requestHandler = VNImageRequestHandler(ciImage: input, options: [ : ]) // <#T##[VNImageOption : Any]#>

        let request = VNGenerateObjectnessBasedSaliencyImageRequest()
            // VNGenerateObjectnessBasedSaliencyImageRequest()
            //VNGenerateAttentionBasedSaliencyImageRequest()

        try? requestHandler.perform([request])

        guard let observation = request.results?.first as? VNSaliencyImageObservation
            else { return CIImage.empty() } //VNSaliencyImageObservation
        guard let heatMask =  createHeatMapMask(from: observation) else { return CIImage.empty() }
//        let fitScale =  min(inputImage!.extent.width / heatMask.extent.width, inputImage!.extent.height / heatMask.extent.height)
        let scaleT = CGAffineTransform(scaleX: inputImage!.extent.width / heatMask.extent.width, y: inputImage!.extent.height / heatMask.extent.height)
       let scaledUpHeatMask =  heatMask.transformed(by: scaleT)
        return scaledUpHeatMask

    }
    func imageChain() -> CIImage? {
        if ( (inputRadius.floatValue) < 0.16 )  {
            // if radius is too small to have any effect just return input image
            return inputImage }
//        let opaqueGreen = CIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0 )
//        let transparentGreen =  CIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 0.0 )

        var blurredImage = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": inputRadius, kCIInputImageKey: inputImage as Any])?.outputImage
        blurredImage = blurredImage?.cropped(to: (inputImage?.extent)!)

        // capture the saliency transformed to matching coordinates of inputImage

        let maskImage = processSaliency() // of input

        let blendMask = CIFilter(name: "CIBlendWithMask" )
           blendMask?.setValue(blurredImage, forKey: kCIInputBackgroundImageKey)
           blendMask?.setValue(maskImage, forKey: kCIInputMaskImageKey)
           blendMask?.setValue(inputImage, forKey: kCIInputImageKey )


       let returnImage = blendMask?.outputImage

        return returnImage

    }



    class func register()   {
 //       let attr: [String: AnyObject] = [:]
//        NSLog("Saliency Blur #register()")
        CIFilter.registerName(kSaliencyBlurFilter, constructor: PGLFilterConstructor(), classAttributes: [
            kCIAttributeFilterCategories :    [
                kCICategoryBlur, kCICategoryInterlaced, kCICategoryNonSquarePixels, kCICategoryStillImage
                                               ],
            kCIAttributeFilterDisplayName : "Saliency Blur"
            ])
    }

}
