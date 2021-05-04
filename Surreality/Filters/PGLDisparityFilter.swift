//
//  PGLDisparityFilter.swift
//  Surreality
//
//  Created by Will on 9/2/20.
//  Copyright © 2020 Will Loew-Blosser. All rights reserved.
//

import Foundation

import CoreImage
import simd
import UIKit
import Photos

class PGLDisparityFilter: PGLRectangleFilter {
    // filters that use depth or disparity
    // some of the filters may have disparity in different attributes..
    // initial user is CIDepthBlurEffect

    var localFilterIsSpecialConstruction = false
        // let the usual pglattribute construction
        // change the local filter to a context created filter when the input is set
        // set
    var hasDisparity = false
    let inputDisparityKey = "inputDisparityImage"
    var auxImage: CIImage?

    var scaledInputImage: CIImage?
    var scaledDepthImage: CIImage?

    func postUIChange(attribute: PGLFilterAttribute) {
        let uiNotification = Notification(name:PGLAttributeAnimationChange, object: attribute,userInfo: nil)

        NotificationCenter.default.post(uiNotification)
    }

    func requestDepthBlurEffect(inputImage: CIImage?, disparityImage: CIImage?) -> CIFilter? {

        if localFilterIsSpecialConstruction {
            // Special depthBlur filter is setup - just return
            return nil }
        guard let inputImage = inputImage, let disparityImage = disparityImage
            else {return nil}
        let ciContext = Renderer.ciContext // global context

         guard let filter = ciContext!.depthBlurEffectFilter(
            for: inputImage,
            disparityImage: disparityImage,
            portraitEffectsMatte: smallColorImage(),
            hairSemanticSegmentation: smallColorImage(),
            glassesMatte: smallColorImage(),
            gainMap: smallColorImage(),
            orientation: CGImagePropertyOrientation.up,
                options: nil)
         else {
            return nil
         }

    //    filter.setValue(4, forKey: "inputAperture")
        filter.setValue(0.5, forKey: "inputScaleFactor")
    //    filter.setValue(CIVector(x: 0, y: 100, z: 100, w: 100), forKey: "inputFocusRect")
        //


        return filter
    }

    override func setDefaults() {
        // set all  image inputs to CGImage.empty
        for anImageParmKey in imageInputAttributeKeys {
            setImageValue(newValue: smallColorImage(), keyName: anImageParmKey)

        }
    }

    override func imageInputIsEmpty() -> Bool {
        // used for images filter to remove if no input is set
        // for disparity only two images are needed.. others are optional
        for imageAttributeKey in [kCIInputImageKey] {
            // not included the inputDisparityKey
            if let inputAttribute = attribute(nameKey: imageAttributeKey )
            {
                if  inputAttribute.inputParmType() == ImageParm.missingInput
                        {
                    return true }
            }
        }
        return false // default return - all inputs are populated or none are image inputs
    }

    func smallColorImage() -> CIImage{
        // for  defaults
        let colorFilter = CIFilter(name: "CIConstantColorGenerator")
        colorFilter?.setDefaults()
        let smallRect = CGRect(x: 0, y: 0, width: 768, height: 576)
        let output = colorFilter?.outputImage
        return output?.cropped(to: smallRect) ?? CIImage.empty()
    }

    fileprivate func setImageWithDepth(_ imageAttribute: PGLFilterAttributeImage, _ newValue: CIImage) {
        // does newValue have a depth or portrait in the auxImage data?
        // also sets  inputDisparityImage attribute if inputImage has depth
        // if the inputDisparityImage

        if  !localFilterIsSpecialConstruction {
            if let newSpecialDepthFilter = requestDepthBlurEffect(inputImage: newValue, disparityImage: nil ) {
                localFilterIsSpecialConstruction = true
                localFilter = newSpecialDepthFilter
                // replaces the standard filter installed in the init(filter:, position:)
            }
        } else {
            super.setImageValue(newValue: newValue, keyName: imageAttribute.attributeName!)
        }

        // get the asset and request the aux images .. returns in a completion handler

        guard let inputAsset = imageAttribute.inputCollection?.firstAsset()
         else { return }

        let options = PHContentEditingInputRequestOptions()

        inputAsset.asset.requestContentEditingInput(with: options, completionHandler: { input, info in
            guard let input = input
                else { NSLog ("contentEditingInput not loaded")
                     return
                }

         // the completion handler can run after the requestDisparityMap function returns
        //  the completion handler has to assign a value not return a value
        // and notify the UI to update

            if !info.isEmpty {
                // is PHContentEditingInputErrorKey in the info
                NSLog("PGLImageList #requestDisparityMap has info returned \(info)")
            }
            self.auxImage = CIImage(contentsOf: input.fullSizeImageURL!, options: [CIImageOption.auxiliaryDisparity: true])

            guard var depthData = self.auxImage?.depthData
            else {return }
            if depthData.depthDataType != kCVPixelFormatType_DisparityFloat32 {
                depthData = depthData.converting(toDepthDataType: kCVPixelFormatType_DisparityFloat32) }

            _ = depthData.depthDataMap.normalizeDisparity(pixelFormat:depthData.depthDataType)
                // vector processing method in Accelerate framework
                //  depthData?.depthDataMap.normalize()
                // or
                //should depthDataByReplacingDepthDataMapWithPixelBuffer:error be used?
                //this is creating a derivative depth map reflecting whatever edits you make to the corresponding image

            if depthData.depthDataType != kCVPixelFormatType_DisparityFloat16 {
                // convert to half-float16
                depthData = depthData.converting(toDepthDataType: kCVPixelFormatType_DisparityFloat16) }

            // depthData needs to scale too...

            self.scaledInputImage = newValue.applyingFilter("CILanczosScaleTransform", parameters: ["inputScale": 0.5])

            self.scaledDepthImage = self.auxImage?.applyingFilter("CIEdgePreserveUpsampleFilter",
                                                                  parameters: ["inputImage": self.scaledInputImage as Any ,
                                                                   "inputSmallImage":  self.auxImage as Any])


            // update the filter
            if (self.scaledInputImage == nil) || (self.scaledDepthImage == nil ) {
                return
                }
            switch imageAttribute.attributeName {
                case kCIInputImageKey:


                    super.setImageValue(newValue: self.scaledInputImage!, keyName: kCIInputImageKey)
                    if let affectedDisparityAttribute = self.attribute(nameKey: self.inputDisparityKey) {
                        if let newList = imageAttribute.inputCollection?.clone(toParm: affectedDisparityAttribute) {
                            affectedDisparityAttribute.setImageCollectionInput(cycleStack: newList)
                                // setImageCollectionInput invokes setImageValue.
                                // now set it directly with the actual depth image
                            super.setImageValue(newValue: self.scaledDepthImage!, keyName: self.inputDisparityKey)
                            self.postUIChange(attribute: affectedDisparityAttribute) }
                    }
                case self.inputDisparityKey:
                    super.setImageValue(newValue: self.scaledDepthImage!, keyName: self.inputDisparityKey)
                default:
                    super.setImageValue(newValue: newValue, keyName: imageAttribute.attributeName!)
            }

            self.postUIChange(attribute: imageAttribute)
            // notify UI for update

        } ) // completion handler end

    }



    override func setImageValue(newValue: CIImage, keyName: String) {
            // also set the disparity parm inputDisparityImage from the attribute imageList

    if let imageAttribute = attribute(nameKey: keyName) as? PGLFilterAttributeImage {
            switch keyName {
                case kCIInputImageKey ,inputDisparityKey :
                     setImageWithDepth( imageAttribute,  newValue)

                default:
                    super.setImageValue(newValue: newValue, keyName: keyName)
            }
        }

  }

    

}
