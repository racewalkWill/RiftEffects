//
//  TiltShift.swift
//  Glance
//
//  Created by Will on 3/6/19.
//  Copyright © 2019 Will Loew-Blosser All rights reserved.
//

import UIKit
/*
 File: TiltShift.m
 Abstract:
 Version: 1.0
from APPLE

 */
// ported to Swift 4.0 WL-B 3/6/19



class PGLTiltShift: PGLFilterCIAbstract {
    // fixed linear gradient in the middle of the image
    // blurs out the upper and lower parts of the image
    // this is an early attempt at custom filter.
    // needs additional parms to control the area of the sharp image
    // while remaining area is blurred.


    override class func register() {
        //       let attr: [String: AnyObject] = [:]

        CIFilter.registerName(kPTiltShift, constructor: PGLFilterConstructor(), classAttributes: PGLTiltShift.customAttributes())
    }

    class override var supportsSecureCoding: Bool { get {
        // subclasses must  implement this
        // Core Data requires secureCoding to store the filter
        return true
    }}

    @objc override class func customAttributes() -> [String: Any] {

        let customDict:[String: Any] = [
            kCIAttributeFilterDisplayName : "Tilt Shift",

            kCIAttributeFilterCategories :
                [kCICategoryBlur],

            "inputRadius" :
                [
                    kCIAttributeMin       :  0.0,
                    kCIAttributeSliderMin :  0.0,
                    kCIAttributeSliderMax : 30.0,
                    kCIAttributeDefault   : 10.0,
                    kCIAttributeIdentity  :  0.0,
                    kCIAttributeType      : kCIAttributeTypeScalar
                ] as [String : Any]
        ]
        return customDict

    }

//    @objc  var inputImage:  CIImage?
    @objc  var  inputRadius: NSNumber = 10.0



   override func setDefaults()
    {
        self.inputRadius = 10.0
    }

    override var outputImage: CIImage? {
        guard let myInput = inputImage else { return nil }
      
        let blurFilter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": inputRadius,  kCIInputImageKey: myInput ])
        let blurredImage = blurFilter!.outputImage?.cropped(to: myInput.extent )

        let h = myInput.extent.size.height

        let opaqueGreen      = CIColor(red:0.0, green:1.0, blue:0.0, alpha:1.0)
        let transparentGreen = CIColor(red:0.0, green:1.0, blue:0.0, alpha:0.0)


        let gradient0Filter = CIFilter(name: "CILinearGradient", parameters: [
            "inputPoint0":CIVector(x:0.0, y:h*0.75),
            "inputPoint1": CIVector (x:0.0, y:h*0.50),
            "inputColor0": opaqueGreen,
            "inputColor1": transparentGreen ] )
        let gradient0 = gradient0Filter?.outputImage

        let gradient1Filter = CIFilter(name: "CILinearGradient", parameters: [
            "inputPoint0": CIVector(x:0.0, y:h*0.25),
            "inputPoint1": CIVector(x:0.0, y:h*0.50),
            "inputColor0": opaqueGreen,
            "inputColor1": transparentGreen ] )
        let gradient1 = gradient1Filter?.outputImage

        let maskImageFilter = CIFilter(name: "CIAdditionCompositing", parameters: [
            kCIInputImageKey: gradient0!,
            kCIInputBackgroundImageKey: gradient1!])
        let maskImage = maskImageFilter?.outputImage

        let blendFilter = CIFilter(name:"CIBlendWithMask", parameters: [
            kCIInputImageKey: blurredImage!,
            "inputMaskImage": maskImage!,
            "inputBackgroundImage": myInput ])

          return blendFilter?.outputImage
    }

}
