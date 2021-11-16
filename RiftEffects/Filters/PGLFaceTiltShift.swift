//
//  PGLFaceTiltShift.swift
//  Glance
//
//  Created by Will on 8/23/18.
//  Copyright © 2018 Will Loew-Blosser. All rights reserved.
//  Based on Apple example 'Recipes for Custom Effects'
//  https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/CoreImaging/ci_filer_recipes/ci_filter_recipes.html#//apple_ref/doc/uid/TP30001185-CH4-SW1

import Foundation
import CoreImage


class PGLFaceTiltShift: CIFilter {
    // Remember that vars of CIFilter need an input prefix on the var name !!
    // subclasses of CIFilter need to be added to two filter creation methods
    //  PGLFilterConstructor filter(withName: String)
    // 

//    class func register() {
//         CIFilter.registerName("FaceTiltShift", constructor: PGLFilterConstructor() , classAttributes: customAttributes()  )
//    }
    class override var supportsSecureCoding: Bool { get {
        // subclasses must  implement this
        // Core Data requires secureCoding to store the filter
        return true
    }}
    
@objc dynamic   var inputImage: CIImage?
@objc dynamic   var inputRadius: NSNumber = 10.0

@objc dynamic   var inputTopStart: CIVector = CIVector(x: 0.0, y:  834 * 0.75)
@objc dynamic   var inputTopEnd: CIVector = CIVector(x: 0.0, y:  834 * 0.55)

@objc dynamic   var inputBottomStart: CIVector = CIVector(x: 0.0, y:  834 * 0.25)
@objc dynamic   var inputBottomEnd: CIVector = CIVector(x: 0.0, y:  834 * 0.45)


@objc    class func customAttributes() -> [String: Any] {
        let customDict:[String: Any] = [
            kCIAttributeFilterDisplayName : "Face Tilt Shift",

            kCIAttributeFilterCategories :
                [kCICategoryBlur, kCICategoryVideo, kCICategoryInterlaced, kCICategoryNonSquarePixels, kCICategoryStillImage] ,

            "inputRadius" :  [
                    kCIAttributeMin       :  0.0,
                    kCIAttributeSliderMin :  0.0,
                    kCIAttributeSliderMax : 30.0,
                    kCIAttributeDefault   : 10.0,
                    kCIAttributeIdentity  :  0.0,
                    kCIAttributeType      : kCIAttributeTypeScalar
                    ],

            "inputTopStart" :  [
                kCIAttributeName      :  "point0",
                kCIAttributeFilterDisplayName :  "point 0",
                kCIAttributeClass : "CIVector",
                kCIAttributeDescription   : "Starting Point of the 1st gradient",
                kCIAttributeType      : kCIAttributeTypePosition
            ],
            "inputTopEnd" :  [
                kCIAttributeName      :  "point1",
                kCIAttributeFilterDisplayName :  "point 1",
                kCIAttributeClass : "CIVector",
                kCIAttributeDescription   : "Ending Point of the 1st gradient",
                kCIAttributeType      : kCIAttributeTypePosition
            ],

            "inputBottomStart" :  [
                kCIAttributeName      :  "point2",
                kCIAttributeFilterDisplayName :  "point 2",
                kCIAttributeClass : "CIVector",
                kCIAttributeDescription   : "Starting Point of the 2nd gradient",
                kCIAttributeType      : kCIAttributeTypePosition
            ],
            "inputBottomEnd" :  [
                kCIAttributeName      :  "point3",
                kCIAttributeFilterDisplayName :  "point 3",
                kCIAttributeClass : "CIVector",
                kCIAttributeDescription   : "Ending Point of the 2nd gradient",
                kCIAttributeType      : kCIAttributeTypePosition
            ]

            ]
        return customDict
    }


    @objc dynamic  override var outputImage: CIImage? {
        get { return imageChain()  }
    }

    func imageChain() -> CIImage? {

        if ( (inputRadius.floatValue) < 0.16 )  {
            // if radius is too small to have any effect just return input image
            return inputImage }

        var blurredImage = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": inputRadius, kCIInputImageKey: inputImage as Any])?.outputImage
        blurredImage = blurredImage?.cropped(to: (inputImage?.extent)!)



//        lazy var h: CGFloat = inputImage.extent.size.height
        let opaqueGreen = CIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0 )
        let transparentGreen =  CIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 0.0 )


        let gradient0 = CIFilter(name: "CILinearGradient", parameters: [
            "inputPoint0":  inputTopStart,
            "inputPoint1": inputTopEnd,
            "inputColor0" : opaqueGreen,
            "inputColor1" : transparentGreen ])?.outputImage

        let gradient1 = CIFilter(name: "CILinearGradient", parameters: [
            "inputPoint0":  inputBottomStart,
            "inputPoint1": inputBottomEnd,
            "inputColor0" : opaqueGreen,
            "inputColor1" : transparentGreen ])?.outputImage



        let additionFilter = CIFilter(name: "CIAdditionCompositing")
        additionFilter?.setValue(gradient0, forKey: kCIInputImageKey)
        additionFilter?.setValue(gradient1, forKey: kCIInputBackgroundImageKey)

        let maskImage = additionFilter?.outputImage

         let blendMask = CIFilter(name: "CIBlendWithMask" )
            blendMask?.setValue(blurredImage, forKey: kCIInputImageKey)
            blendMask?.setValue(maskImage, forKey: kCIInputMaskImageKey)
            blendMask?.setValue(inputImage, forKey: kCIInputBackgroundImageKey)


        let returnImage = blendMask?.outputImage

         return returnImage

        }

//    override var name: String {
    // from GitHub example "Also, for anyone else attempting to access a custom filter via key paths for the purposes of animation, you need to override the name property as well:
    // Otherwise, the class name will be ModuleName.FilterName, which isn't accessible via key paths within Core Animation.
//        return "FaceTiltShift.self"
//    }


}


