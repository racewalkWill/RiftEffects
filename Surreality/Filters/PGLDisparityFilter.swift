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

    func requestDepthBlurEffect(inputImage: CIImage?, disparityImage: CIImage?) -> CIFilter? {

        if localFilterIsSpecialConstruction {
            // Special depthBlur filter is setup - just return
            return nil }

        let ciContext = Renderer.ciContext // global context

        let filter = ciContext!.depthBlurEffectFilter(for: inputImage!,
                                                      disparityImage: disparityImage!,
                                                     portraitEffectsMatte: nil,
                                                     orientation: CGImagePropertyOrientation.up,
                                                     options: nil)!
    //    filter.setValue(4, forKey: "inputAperture")
        filter.setValue(0.5, forKey: "inputScaleFactor")
    //    filter.setValue(CIVector(x: 0, y: 100, z: 100, w: 100), forKey: "inputFocusRect")
        //


        return filter
    }

    fileprivate func setImageWithDepth(_ imageAttribute: PGLFilterAttributeImage, _ newValue: CIImage) {
        // does newValue have a depth or portrait in the auxImage data?
        // also sets  inputDisparityImage attribute if inputImage has depth
        // if the inputDisparityImage


        imageAttribute.useDepthList()
        // replaces PGLImageList with PGLImageDepthList if needed
        if imageAttribute.isDepthListAssigned {
            guard let myDepthList = imageAttribute.inputCollection?.asPGLImageDepthList()
            else {
                // without depth just assign the image
                super.setImageValue(newValue: newValue, keyName: imageAttribute.attributeName!)
                return }
            myDepthList.getFirstImageDepth(newImage: newValue)

            hasDisparity = myDepthList.hasDisparity()
            if hasDisparity {

                if  !localFilterIsSpecialConstruction {
                    if let newSpecialDepthFilter = requestDepthBlurEffect(inputImage: myDepthList.inputImage, disparityImage: myDepthList.auxDepthImage) {
                        localFilterIsSpecialConstruction = true
                        localFilter = newSpecialDepthFilter
                        // replaces the standard filter installed in the init(filter:, position:)
                    }
                } else {
                    // special filter is installed .. assign new disparity map
                    guard let _ = myDepthList.auxDepthImage else {
                        // without depth just assign the image
                        super.setImageValue(newValue: newValue, keyName: imageAttribute.attributeName!)
                        return
                    }
                    switch imageAttribute.attributeName {
                        case kCIInputImageKey:
                            super.setImageValue(newValue: myDepthList.auxDepthImage!, keyName: inputDisparityKey)
                            super.setImageValue(newValue: newValue, keyName: kCIInputImageKey)
                            NSLog("PGLDisparityFilter #setImageWithDepth sets both input and disparity")
                        case inputDisparityKey:
                            super.setImageValue(newValue: myDepthList.auxDepthImage!, keyName: inputDisparityKey)
                        default:
                            super.setImageValue(newValue: newValue, keyName: imageAttribute.attributeName!)
                    }
                }
            }
            else {
                // hasDisparity = false
                // without depth just assign the image
                super.setImageValue(newValue: newValue, keyName: imageAttribute.attributeName!)
                 }
        }

        else {
            // isDepthListAssigned = false
            // without depth just assign the image
            super.setImageValue(newValue: newValue, keyName: imageAttribute.attributeName!)
             }
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
