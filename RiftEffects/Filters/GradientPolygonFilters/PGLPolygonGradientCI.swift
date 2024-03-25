//
//  PGLPolygonGradientCI.swift
//  RiftEffects
//
//  Created by Will on 3/22/24.
//  Copyright © 2024 Will Loew-Blosser. All rights reserved.
//

import Foundation
import CoreGraphics
import UIKit
import os

/// May delete as the PGLClass for the gradient handles all the below
// MARK: DELETE

/// 5 sided simple polygon gradient
/// uses 5 linear gradients to form the closed chain of endpoints
/// may intersect itself to form star like shape
/// each linear gradient has two points to define a blend area along the line
class PGLPolygonGradientCI: CIFilter {

//    @objc var inputPoint0: CIVector?
//    @objc var inputPoint1: CIVector?
//    @objc var inputColor0: CIColor?
//    @objc var inputColor1: CIColor?
//
//    let linear1 = CIFilter(name: "CILinearGradient")! // parameters: <#T##[String : Any]?#>)
//    let linear2 = CIFilter(name: "CILinearGradient")!
//    let linear3 = CIFilter(name: "CILinearGradient")!
//    let linear4 = CIFilter(name: "CILinearGradient")!
//    let linear5 = CIFilter(name: "CILinearGradient")!
//    var linearGradients: [CIFilter]

        /// index for the current linear gradient
//    var indexGradient = 0
//
//    let blend1 = CIFilter(name: kGradientBlendFilter)!
//    let blend2 = CIFilter(name: kGradientBlendFilter)!
//    let blend3 = CIFilter(name: kGradientBlendFilter)!
//    let blend4 = CIFilter(name: kGradientBlendFilter)!


 override init() {

//        linearGradients = [ linear1, linear2, linear3, linear4, linear5]
        super.init()
    }

    required init?(coder aDecoder: NSCoder)
    {
//        linearGradients = [ linear1, linear2, linear3, linear4, linear5]
//            // zero based array  0..4 is five elements
        super.init(coder: aDecoder)

    }


    class func register() {
        //       let attr: [String: AnyObject] = [:]
//        NSLog("PGLSequencedFilters #register()")
        CIFilter.registerName(kPolygonGradient, constructor: PGLFilterConstructor(), classAttributes: PGLPolygonGradientCI.customAttributes())
    }

    class override var supportsSecureCoding: Bool { get {
        // subclasses must  implement this
        // Core Data requires secureCoding to store the filter
        return true
    }}


    @objc class func customAttributes() -> [String: Any] {
        let customDict:[String: Any] = [
            kCIAttributeFilterDisplayName : kPolygonGradient,

            kCIAttributeFilterCategories :
                [kCICategoryGradient, kCICategoryStillImage],

//            "inputSequence" : [
//                kCIAttributeType : kPChildSequenceStack
//            ] as [String : Any] ,


//            kCIinputDissolveTime :  [
//                kCIAttributeDefault   : 10.0,
//                kCIAttributeIdentity  :  0.0,
//                kCIAttributeType      : kCIAttributeTypeTime,
//                kCIAttributeClass   : "NSNumber" ,
//                kCIAttributeMax     : 100.0,
//                kCIAttributeMin     : 0 ,
//                kCIAttributeSliderMax : 100 ,
//                kCIAttributeSliderMin :  0,
//                kCIAttributeDisplayName : "Fade Time"
//            ] as [String : Any],
//
//            kCIinputSingleFilterDisplayTime : [
//                // values are frame counts, usually 60 fps
//                // divide by 60 to estimate time in seconds
//                kCIAttributeDefault   : 60,
//                kCIAttributeIdentity  :  60,
////                kCIAttributeType      : ,
//                // if attributeType is empty then goes to PGLFilterAttributeNumber
//                kCIAttributeClass   : "NSNumber",
//                kCIAttributeMax     : 600,
//                kCIAttributeMin     : 1 ,
//                kCIAttributeSliderMax : 600,
//                kCIAttributeSliderMin :  1,
//                kCIAttributeDisplayName : "Display Time"
//            ] as [String : Any],

        ]
        return customDict
    }


}
