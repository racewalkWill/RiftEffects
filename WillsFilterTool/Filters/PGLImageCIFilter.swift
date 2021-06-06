//
//  PGLNullCIFilter.swift
//  Glance
//
//  Created by Will on 2/2/19.
//  Copyright © 2019 Will Loew-Blosser. All rights reserved.
//


import UIKit

class PGLImageCIFilter: CIFilter {
    // just return an image.. NO EFFECTS.. Starts the filter chain..

    @objc dynamic   var inputImage: CIImage?
    @objc dynamic   var inputTime: NSNumber = 10.0

    class func register() {
        //       let attr: [String: AnyObject] = [:]
//        NSLog("PGLImageCIFilter #register()")
        CIFilter.registerName(kPImages, constructor: PGLFilterConstructor(), classAttributes: PGLImageCIFilter.customAttributes())
    }

    class override var supportsSecureCoding: Bool { get {
        // subclasses must  implement this
        // Core Data requires secureCoding to store the filter
        return true
    }}


    @objc class func customAttributes() -> [String: Any] {
        let customDict:[String: Any] = [
            kCIAttributeFilterDisplayName : "Images",

            kCIAttributeFilterCategories :
                [kCICategoryTransition, kCICategoryStillImage],
            "inputTime" :  [

                kCIAttributeDefault   : 0.00,
                kCIAttributeIdentity  :  0.0,
                kCIAttributeType      : kCIAttributeTypeTime
                ]
        ]
        return customDict
    }


    override var outputImage: CIImage? {
        get { return inputImage }
    }
}
