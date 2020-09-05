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



   override  func setImageValue(newValue: CIImage, keyName: String) {
    //        NSLog("PGLFilterClasses #setImageValue key = \(keyName)")
    //        newValue.clampedToExtent()
            // test changing all inputs to the same extent

            // get the disparity parm inputDisparityImage from the attribute imageList


    if keyName == kCIInputImageKey {
        if let imageAttribute = attribute(nameKey: keyName) as? PGLFilterAttributeImage {
            if let disparityValue = imageAttribute.disparityMap() {
                NSLog("PGLDisparityFilter #setImageValue has disparityValue set both attributes")
                localFilter.setValue( newValue, forKey: keyName)
                localFilter.setValue(disparityValue, forKey: "inputDisparityImage")
                postImageChange()
            } else {
                NSLog("PGLDisparityFilter #setImageValue no disparity - set imageValue normally")
                super.setImageValue(newValue: newValue, keyName: keyName)}
        }
    } else {NSLog("PGLDisparityFilter #setImageValue NOT inputImageAttribut - set imageValue normally")
            super.setImageValue(newValue: newValue, keyName: keyName)}

    }

}
