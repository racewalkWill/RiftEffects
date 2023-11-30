//
//  PGLScaleImageCIFilter.swift
//  RiftEffects
//
//  Created by Will on 11/29/23.
//  Copyright © 2023 Will Loew-Blosser. All rights reserved.
//

import UIKit

class PGLScaleImageCIFilter: CIFilter {
    // just return an image.. NO EFFECTS.. Starts the filter chain..

    @objc dynamic   var inputImage: CIImage?
    @objc dynamic   var inputRectangle: CIVector?

    class func register() {
        //       let attr: [String: AnyObject] = [:]
//        NSLog("PGLImageCIFilter #register()")
        CIFilter.registerName(kPScaleDown, constructor: PGLFilterConstructor(), classAttributes: PGLScaleImageCIFilter.customAttributes())
    }

    class override var supportsSecureCoding: Bool { get {
        // subclasses must  implement this
        // Core Data requires secureCoding to store the filter
        return true
    }}


    @objc class func customAttributes() -> [String: Any] {
        let customDict:[String: Any] = [
            kCIAttributeFilterDisplayName : "Scale",

            kCIAttributeFilterCategories :
                [kCICategoryGeometryAdjustment, kCICategoryStillImage],

            "inputRectangle" :
                [ kCIAttributeType      : kCIAttributeTypeRectangle
                ] as [String : Any],


        ]
        return customDict
    }


    override var outputImage: CIImage? {
        get { return inputImage }
    }
}
