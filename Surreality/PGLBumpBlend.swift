//
//  PGLBumpDistort.swift
//  Glance
//
//  Created by Will on 3/28/19.
//  Copyright © 2019 Will Loew-Blosser. All rights reserved.
//
import UIKit


class PGLBumpBlendCI: PGLFilterCIAbstract {
// similar to PGLTiltShift but uses bump effect


    override class func register() {
        //       let attr: [String: AnyObject] = [:]

        CIFilter.registerName(kPBumpBlend, constructor: PGLFilterConstructor(), classAttributes: PGLBumpBlendCI.customAttributes())
    }



    @objc override class func customAttributes() -> [String: Any] {

        let customDict:[String: Any] = [
            kCIAttributeFilterDisplayName : "Bump Blend",

            kCIAttributeFilterCategories :
                [kCICategoryDistortionEffect],

            "inputRadius" :
                [
                    kCIAttributeMin       :  0.0,
                    kCIAttributeSliderMin :  0.0,
                    kCIAttributeSliderMax : 500.0,
                    kCIAttributeDefault   : 100.0,
                    kCIAttributeIdentity  :  0.0,
                    kCIAttributeType      : kCIAttributeTypeScalar
            ],
            "inputRadius1" :
                [
                    kCIAttributeMin       :  0.0,
                    kCIAttributeSliderMin :  0.0,
                    kCIAttributeSliderMax : 500.0,
                    kCIAttributeDefault   : 400.0,
                    kCIAttributeIdentity  :  0.0,
                    kCIAttributeType      : kCIAttributeTypeScalar
            ],
            "inputScale" : [

                kCIAttributeMin       : -1.0 ,
                kCIAttributeSliderMin : -1.0,
                kCIAttributeSliderMax : 1.0 ,
                kCIAttributeDefault   : 0.50 ,
                kCIAttributeIdentity  : 0,
                kCIAttributeType      : kCIAttributeTypeScalar

            ],

            "inputCenter" : [  //kCIInputCenterKey"
                kCIAttributeClass : "CIVector" ,
                kCIAttributeDefault : CIVector(x: 200, y: 200),
                kCIAttributeDescription :"The center of the effect as x and y coordinates",
                kCIAttributeDisplayName :"Center",
                kCIAttributeType : kCIAttributeTypePosition
],
        ]
        return customDict

    }

//    @objc  var inputImage:  CIImage?
    @objc  var  inputRadius: NSNumber = 100.0
    @objc  var  inputRadius1: NSNumber = 400.0
    @objc var inputCenter:CIVector = CIVector(x: 200, y: 200)
     @objc  var  inputScale: NSNumber = 0.50



    override func setDefaults()
    {
        self.inputRadius = 100.0
        self.inputRadius1 = 400.0
        self.inputCenter = CIVector(x: 200 , y: 200)
        self.inputScale = 0.50
    }

    override var outputImage: CIImage? {
        guard let myInput = inputImage else { return nil }

        let baseFilter = CIFilter(name: "CIBumpDistortion",
                                  parameters: [ kCIInputRadiusKey: inputRadius,
                                                kCIInputImageKey: myInput,
                                                kCIInputScaleKey: inputScale,
                                                kCIInputCenterKey: inputCenter

                          ])
        let bumpImage = baseFilter!.outputImage?.cropped(to: myInput.extent )



        let opaqueGreen      = CIColor(red:0.0, green:1.0, blue:0.0, alpha:1.0)
        let transparentGreen = CIColor(red:0.0, green:1.0, blue:0.0, alpha:0.0)

        let gradient0Filter = CIFilter(name: "CIRadialGradient", parameters: [
            "inputCenter": inputCenter,
            "inputRadius0": inputRadius,
            "inputRadius1": inputRadius1,
            "inputColor0": opaqueGreen,
            "inputColor1": transparentGreen ] )
        let gradient0 = gradient0Filter?.outputImage


        let blendFilter = CIFilter(name:"CIBlendWithMask", parameters: [
            kCIInputImageKey: bumpImage!,
            "inputMaskImage": gradient0!,
            "inputBackgroundImage": myInput ])

        return blendFilter?.outputImage
    }

}

