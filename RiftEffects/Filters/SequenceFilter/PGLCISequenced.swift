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
    @objc dynamic   var inputBackgroundImage: CIImage?
    @objc dynamic   var inputMaskImage: CIImage?
    @objc dynamic   var inputDissolveTime: NSNumber = 10.0
    @objc dynamic   var inputSingleFilterDisplayTime: NSNumber = (60) as NSNumber
                            // 3 seconds * 60 frames = frames to pause
    @objc dynamic   var inputSequence: CIImage?

    
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
            
            "inputSequence" : [
                kCIAttributeType : kPChildSequenceStack
            ] as [String : Any] ,

            kCIinputDissolveTime :  [
                kCIAttributeDefault   : 10.0,
                kCIAttributeIdentity  :  0.0,
                kCIAttributeType      : kCIAttributeTypeTime,
                kCIAttributeClass   : "NSNumber" ,
                kCIAttributeMax     : 100.0,
                kCIAttributeMin     : 0 ,
                kCIAttributeSliderMax : 100 ,
                kCIAttributeSliderMin :  0,
                kCIAttributeDisplayName : "Fade Time"
            ] as [String : Any],

            kCIinputSingleFilterDisplayTime : [
                // values are frame counts, usually 60 fps
                // divide by 60 to estimate time in seconds
                kCIAttributeDefault   : 60,
                kCIAttributeIdentity  :  60,
//                kCIAttributeType      : ,
                // if attributeType is empty then goes to PGLFilterAttributeNumber
                kCIAttributeClass   : "NSNumber",
                kCIAttributeMax     : 600,
                kCIAttributeMin     : 1 ,
                kCIAttributeSliderMax : 600,
                kCIAttributeSliderMin :  1,
                kCIAttributeDisplayName : "Display Time"
            ] as [String : Any],

        ]
        return customDict
    }


//    override var outputImage: CIImage? {
//
//        get { let sequenceInputImage = inputImage
//            myFilterSequence.imageUpdate(sequenceInputImage, true)
//            return myFilterSequence.outputImage() }
//    }
}
