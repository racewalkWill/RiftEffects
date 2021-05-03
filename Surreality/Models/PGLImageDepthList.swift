//
//  PGLImageDepthList.swift
//  Surreality
//
//  Created by Will on 4/29/21.
//  Copyright © 2021 Will Loew-Blosser. All rights reserved.
//

import Foundation
import UIKit
import Photos
import CoreImage

class PGLImageDepthList: PGLImageList {
    // cache the image and the aux depth info
    // only 1 image.. not a collection

    //2021/04/29 noon  to do...
    // next get CIDepthBlurEffect in the PGLDisparityFilter class to use this list
    // and get the specialContstructor to run with PGLDisparityFilter.

    var inputImage: CIImage?
    var auxDepthImage: CIImage?

    func hasDisparity() -> Bool {
        return (inputImage != nil ) && (auxDepthImage != nil )
    }
    func getFirstImageDepth(newImage: CIImage) {
        // only one image used for depth... not a transition filter
        let theAsset = imageAssets[0]
        inputImage = newImage
            // cache this one
        requestDisparityMap(asset: theAsset.asset, image: newImage)
    }

    func requestDisparityMap(asset: PHAsset, image: CIImage)  {
            // may not have depthData in many cases
            // process timing.. run in background for callback.
            // suggested to downSample the image to improve performance
            // should end with disparity and image matching...
            var auxImage: CIImage?
            var scaledDisparityImage: CIImage?

            let options = PHContentEditingInputRequestOptions()


            asset.requestContentEditingInput(with: options, completionHandler: { input, info in
                guard let input = input
                    else { NSLog ("contentEditingInput not loaded")
                         return
                    }

             // the completion handler can run after the requestDisparityMap function returns
            //  the completion handler has to assign a value not return a value

                if !info.isEmpty {
                    // is PHContentEditingInputErrorKey in the info
                    NSLog("PGLImageList #requestDisparityMap has info returned \(info)")
                }
             auxImage = CIImage(contentsOf: input.fullSizeImageURL!, options: [CIImageOption.auxiliaryDepth: true])  // CIImageOption.auxiliaryDisparity: true

                NSLog("PGLImageList #requestDisparityMap completionHandler auxImage = \(String(describing: auxImage))")
                // is the rest of the datatype and normalizing still needed???
                
            if auxImage != nil {

                var depthData = auxImage!.depthData

            if depthData?.depthDataType != kCVPixelFormatType_DisparityFloat32 {
                // convert to half-float16 but the normalize seems to expect float32..
                depthData = depthData?.converting(toDepthDataType: kCVPixelFormatType_DisparityFloat32) }

                _ = depthData?.depthDataMap.normalizeDisparity(pixelFormat:depthData!.depthDataType)  // vector processing method in Accelerate framework
//                depthData?.depthDataMap.normalize()
                // or

                //should depthDataByReplacingDepthDataMapWithPixelBuffer:error be used?
                //this is creating a derivative depth map reflecting whatever edits you make to the corresponding image

                if depthData?.depthDataType != kCVPixelFormatType_DisparityFloat16 {
                    // convert to half-float16
                    depthData = depthData?.converting(toDepthDataType: kCVPixelFormatType_DisparityFloat16) }

                // depthData needs to scale too...
                let doScaleDown = true
                // otherwise the auxData needs to scale up to the image..

                if doScaleDown {
                    let scaledDownInput = image.applyingFilter("CILanczosScaleTransform", parameters: ["inputScale": 0.5])
                    scaledDisparityImage = auxImage?.applyingFilter("CIEdgePreserveUpsampleFilter",
                                                        parameters: ["inputImage": scaledDownInput ,"inputSmallImage":  auxImage as Any])
                    self.inputImage = scaledDownInput
                    self.auxDepthImage = scaledDisparityImage

                    }
                else {
                    self.auxDepthImage = auxImage
                }
                }

            } )



    }

}
