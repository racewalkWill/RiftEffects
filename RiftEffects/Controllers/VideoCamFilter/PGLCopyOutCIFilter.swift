//
//  PGLCopyOutCIFilter.swift
//  RiftEffects
//
//  Created by Will on 12/7/23.
//  Copyright © 2023 Will Loew-Blosser. All rights reserved.
//
// Pass the input image to the output without change

import UIKit

class PGLCopyToOutputCIFilter: CIFilter {
    // just return an image.. NO EFFECTS.. Starts the filter chain..

//    @objc dynamic   var inputImage: CIImage?


    class func register() {

        CIFilter.registerName(kPCopyOut, constructor: PGLFilterConstructor(), classAttributes: PGLCopyToOutputCIFilter.customAttributes())
    }

    class override var supportsSecureCoding: Bool { get {
        // subclasses must  implement this
        // Core Data requires secureCoding to store the filter
        return true
    }}


    @objc class func customAttributes() -> [String: Any] {
        let customDict:[String: Any] = [
            kCIAttributeFilterDisplayName : "VideoCam",

            kCIAttributeFilterCategories :
                [ kCICategoryVideo, kCICategoryGenerator]

        ]
        return customDict
    }


}

