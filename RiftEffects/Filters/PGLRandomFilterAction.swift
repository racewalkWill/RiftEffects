//
//  PGLRandomFilterAction.swift
//  WillsFilterTool
//
//  Created by Will on 8/10/21.
//  Copyright © 2021 Will Loew-Blosser. All rights reserved.
//

import UIKit

class PGLRandomFilterAction: CIFilter {
    //holds user picked image collection and sets into the PGLDemo object
    // generages a set of 5 or more  filter (may haver child stacks created) into the stack
    // uses the picked image collection for the various filter parms in the
    // generated random filters

    @objc dynamic   var inputImage: CIImage?
    @objc dynamic   var inputTime: NSNumber = 10.0

    class func register() {
        //       let attr: [String: AnyObject] = [:]
//        NSLog("PGLRandomFilterAction #register()")
        CIFilter.registerName(kPRandom, constructor: PGLFilterConstructor(), classAttributes:
                                 [
                                    kCIAttributeFilterDisplayName : kPRandom,

                                    kCIAttributeFilterCategories :
                                        [ kCICategoryStillImage,

                                        kCICategoryTransition],

                                    kCIAttributeDescription : PGLRandomFilterMaker.localizedDescription(filterName: kPRandom)

                                ]
        )
    }

    class override var supportsSecureCoding: Bool { get {
        // subclasses must  implement this
        // Core Data requires secureCoding to store the filter
        return true
    }}


    @objc class func customAttributes() -> [String: Any] {
        // this is called at the PGLSourceFilter instance creation.
        let customDict:[String: Any] = [
            kCIAttributeFilterDisplayName : kPRandom,

            kCIAttributeFilterCategories :
                [ kCICategoryStillImage,

                kCICategoryTransition],

            kCIAttributeDescription : PGLRandomFilterMaker.localizedDescription(filterName: kPRandom)

        ]
        return customDict
    }


    override var outputImage: CIImage? {
        get {
            return inputImage }
    }

}
