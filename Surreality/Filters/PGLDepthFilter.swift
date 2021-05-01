//
//  PGLDepthFilter.swift
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

    func requestDepthBlurEffect(inputImage: CIImage?, disparityImage: CIImage?) -> CIFilter? {

        let ciContext = Renderer.ciContext // global context

        let filter = ciContext!.depthBlurEffectFilter(for: inputImage!,
                                                      disparityImage: disparityImage!,
                                                     portraitEffectsMatte: nil,
                                                     // the orientation of you input image
                                                     orientation: CGImagePropertyOrientation.up,
                                                     options: nil)!
    //    filter.setValue(4, forKey: "inputAperture")
        filter.setValue(0.5, forKey: "inputScaleFactor")
    //    filter.setValue(CIVector(x: 0, y: 100, z: 100, w: 100), forKey: "inputFocusRect")
        //


        return filter
    }

override func setImageValue(newValue: CIImage, keyName: String) {
            // also set the disparity parm inputDisparityImage from the attribute imageList

    super.setImageValue(newValue: newValue, keyName: keyName)
    if keyName == "inputDisparityImage" {return}
    // the inputDisparityImage is set at the same time as inputImage by the disparityMap methods
    
    if keyName == kCIInputImageKey {
        if let imageAttribute = attribute(nameKey: keyName) as? PGLFilterAttributeImage {
            // does newValue have a disparity in the auxImage data?
            imageAttribute.useDepthList()
                // replaces PGLImageList with PGLImageDepthList if needed
            if imageAttribute.isDepthListAssigned {
                guard let myDepthList = imageAttribute.inputCollection?.asPGLImageDepthList()
                else { return }
                myDepthList.getFirstImageDepth(newImage: newValue)
                hasDisparity = myDepthList.hasDisparity()
                if !hasDisparity { return }
                if  !localFilterIsSpecialConstruction {
                    if let newSpecialDepthFilter = requestDepthBlurEffect(inputImage: myDepthList.inputImage, disparityImage: myDepthList.auxDepthImage) {
                        localFilterIsSpecialConstruction = true

                        localFilter = newSpecialDepthFilter
                            // replaces the standard filter installed in the init(filter:, position:)

                    }
                } else {
                    // special filter is installed .. assign new disparity map
                    if let newDepth = myDepthList.auxDepthImage {

                        super.setImageValue(newValue: newDepth, keyName: "inputDisparityImage")
                    }
                }

            }
        }

    }
  }

    

}
