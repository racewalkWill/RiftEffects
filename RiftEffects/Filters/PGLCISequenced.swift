//
//  PGLSequencedFilters.swift
//  RiftEffects
//
//  Created by Will on 9/27/22.
//  Copyright © 2022 Will Loew-Blosser. All rights reserved.
//

import UIKit

class PGLCISequenced: CIFilter {
    // just return an image.. NO EFFECTS.. Starts the filter chain..

    @objc dynamic   var inputImage: CIImage?
    @objc dynamic   var inputTime: NSNumber = 10.0
    var myFilterSequence: PGLSequenceStack!

    // need to set input of myFilterSequence as the inputImage
    
    class func register() {
        //       let attr: [String: AnyObject] = [:]
//        NSLog("PGLSequencedFilters #register()")
        CIFilter.registerName(kPSequencedFilter, constructor: PGLFilterConstructor(), classAttributes: PGLCISequenced.customAttributes())
    }

    class override var supportsSecureCoding: Bool { get {
        // subclasses must  implement this
        // Core Data requires secureCoding to store the filter
        return true
    }}


    @objc class func customAttributes() -> [String: Any] {
        let customDict:[String: Any] = [
            kCIAttributeFilterDisplayName : kPSequencedFilter,

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

        get { let sequenceInputImage = inputImage
            myFilterSequence.imageUpdate(sequenceInputImage, true)
            return myFilterSequence.outputImage() }
    }
}
