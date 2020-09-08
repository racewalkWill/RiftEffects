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

class PGLDisparityFilter: PGLSourceFilter {
    // filters that use depth or disparity
    // some of the filters may have disparity in different attributes..
    // initial user is CI

    var localFilterIsSpecialConstruction = false
        // let the usual pglattribute construction
        // change the local filter to a context created filter when the input is set
        // set

override func setImageValue(newValue: CIImage, keyName: String) {
    //        NSLog("PGLFilterClasses #setImageValue key = \(keyName)")
    //        newValue.clampedToExtent()
            // test changing all inputs to the same extent

            // get the disparity parm inputDisparityImage from the attribute imageList
    if keyName == "inputDisparityImage" {return}
    // the inputDisparityImage is set at the same time as inputImage by the disparityMap methods
    
    if keyName == kCIInputImageKey {
        if let imageAttribute = attribute(nameKey: keyName) as? PGLFilterAttributeImage {
            // does newValue have a disparity in the auxImage data?

                imageAttribute.disparityMap()

        }
        else {
            NSLog("PGLDisparityFilter #setImageValue NOT inputImageAttribut - set imageValue normally")
            super.setImageValue(newValue: newValue, keyName: keyName)}

    }
  }

}
