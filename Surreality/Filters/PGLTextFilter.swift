//
//  PGLTextFilter.swift
//  Glance
//
//  Created by Will on 6/19/20.
//  Copyright © 2020 Will. All rights reserved.
//

import Foundation
import CoreGraphics
import UIKit

class PGLTextFilter: PGLSourceFilter {
    // super class for the text filters which have a
    // attribute answering isTextInputUI() true
        // CIAttributedTextImageGenerator inputText,
        // CIAztecCodeGenerator inputMessage
        // CICode128BarcodeGenerator  inputMessage
        // CIPDF417BarcodeGenerator  inputMessage
        // CIQRCodeGenerator  inputMessage inputCorrectionLevel
        // CITextImageGenerator inputText inputFontName

    // see the PGLSelectParmController methods for UITextFieldDelegate

}

class PGLQRCodeGenerator: PGLTextFilter {
    // the CIQRCodeGenerator does not have a defaults
    //  "CIQRCodeGenerator filter requires L, M, Q, or H for inputCorrectionLevel"

    static let inputCorrectionLevelSettings: [NSString] = ["L", "M", "Q", "H" ]

    required init?(filter: String, position: PGLFilterCategoryIndex) {
           super.init(filter: filter, position: position)
        let defaultCorrectionLevel = (PGLQRCodeGenerator.inputCorrectionLevelSettings.first)!
        setStringValue(newValue: defaultCorrectionLevel, keyName: "inputCorrectionLevel")
           hasAnimation = false }

}

class PGLTextImageGenerator: PGLTextFilter {
    // overide defaults for Font Size and Scale Factor
    // adds a rect parm for the text positioning
    // uses CITextImageGenerator and positions into inputTextPosition rectangle


        //sliderMinValue= Optional(1.0) sliderMaxValue= Optional(4.0) defaultValue= Optional(1.0)

//    var textImageGenerator =  CIFilter(name: "CITextImageGenerator", parameters: ["inputFontSize" : 30, "inputScaleFactor" : 2])
    class func internalCIFilter() -> CIFilter {
       return CIFilter(name: "CITextImageGenerator", parameters: ["inputFontSize" : 30, "inputScaleFactor" : 2])!
    }
    @objc dynamic var inputTextPositionRect: CGRect = CGRect(x: 50, y: 50 , width: 250, height: 40)



    @objc  class func customAttributes() -> [String: Any] {
        let customDict:[String: Any] = [
                        "inputTextPositionRect" : [
                            kCIAttributeClass      : "CIVector",
                            kCIAttributeDisplayName : "Text Area",
                            kCIAttributeType : kCIAttributeTypeRectangle,
                            kCIAttributeDescription: "Position Rectangle for the Text",
                            kCIAttributeDefault: [50, 50, 250, 40]

                        ]
        ]
//      return combineCustomAttributes(otherAttributes: customDict)
       return customDict
    }

     class func standardAttributes() -> [String:Any] {
        var textAttributes: [String:Any] = [
            kCIAttributeFilterDisplayName : "Image Text",

            kCIAttributeFilterCategories :
                [kCICategoryGenerator],
        ]
        if let aTextImageGenerator = CIFilter(name: "CITextImageGenerator") {

            for (key, value) in aTextImageGenerator.attributes {
                textAttributes.updateValue(value, forKey: key)

            }
            for (key, value) in customAttributes() {
                textAttributes.updateValue(value, forKey: key)
            }
        }
        return textAttributes

    }

//    class override var supportsSecureCoding: Bool { get {
//        // subclasses must  implement this
//        // Core Data requires secureCoding to store the filter
//        return true
//    }}

    class func register() {
 //       let attr: [String: AnyObject] = [:]
        NSLog("PGLTextImageGenerator #register()")
        CIFilter.registerName(kTextImageGenerator, constructor: PGLFilterConstructor(), classAttributes: PGLTextImageGenerator.standardAttributes())
    }

//    override var outputImage: CIImage? {
//        get {
//            return textImageGenerator?.outputImage
//        }
//    }

}

class CompositeTextImage: CIFilter {
    let backgroundComposite: CIFilter
    let textImageFilter: CIFilter

    @objc var inputImage : CIImage?
    @objc var inputScaleFactor: NSNumber = 2
    @objc var inputFontName: NSString = "HelveticaNeue"
    @objc var inputFontSize: NSNumber = 24
    @objc var inputText: NSString = "Text"
    @objc var inputTextPositionRect: CIVector = CIVector(x: 50.0, y: 50.0, z: 250.0, w: 40.0)

    override init() {
        backgroundComposite = CompositeOverBlackFilter()
        textImageFilter = CIFilter(name: "CITextImageGenerator", parameters: ["inputFontSize" : 30, "inputScaleFactor" : 2])!
        super.init()
    }

    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }

    override var outputImage: CIImage!
    {
//        guard let inputImage = inputImage else
//        {
//            return nil
//        }
        textImageFilter.setValuesForKeys(
            ["inputScaleFactor":  inputScaleFactor,
             "inputFontName" : inputFontName,
             "inputFontSize" : inputFontSize,
             "inputText" : inputText

            ]
        )  //
        let textOutput = textImageFilter.outputImage
        backgroundComposite.setValue(textOutput, forKey: kCIInputImageKey)

        return backgroundComposite.outputImage
    }

    override var attributes: [String : Any]
    {
        let textAttributes: [String:Any] = [
            kCIAttributeFilterCategories :
                                  [kCICategoryGenerator ,
                                   kCICategoryStillImage,
                                  kCICategoryVideo],

            kCIAttributeFilterDisplayName : "Image Text",

            // now list the full set..
            "inputImage": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "CIImage",
                kCIAttributeDisplayName: "Image",
                kCIAttributeType: kCIAttributeTypeImage],

            "inputFontSize": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "NSNumber",
                kCIAttributeDefault: 24,
                kCIAttributeDisplayName: "Font Size",
                kCIAttributeMin: 9,
                kCIAttributeSliderMin: 9,
                kCIAttributeSliderMax: 128,
                kCIAttributeType: kCIAttributeTypeScalar],

            "inputScaleFactor": [kCIAttributeIdentity: 1,
                kCIAttributeClass: "NSNumber",
                kCIAttributeDefault: 24,
                kCIAttributeDisplayName: "Scale Factor",
                kCIAttributeMin: 0,
                kCIAttributeSliderMin: 1,
                kCIAttributeSliderMax: 4,
                kCIAttributeType: kCIAttributeTypeScalar],

            "inputFontName": [kCIAttributeDefault: "HelveticaNeue",
                              kCIAttributeDisplayName: "Font Name",
                              kCIAttributeClass: "NSString" ],

            "inputText" : [kCIAttributeDisplayName: "Text",
                           kCIAttributeClass: "NSString"

            ],

            "inputTextPositionRect" : [ kCIAttributeClass: "CIVector",
                                        kCIAttributeType: "CIAttributeTypeRectangle",
                                        kCIAttributeDefault: CIVector(x: 50.0, y: 50.0, z: 250.0, w: 40.0),
                                        kCIAttributeDisplayName: "Text Area",
                                        kCIAttributeDescription: "Position Rectangle for the Text"
                                        ]
            ]

        return textAttributes
    }




    class func register()   {
 //       let attr: [String: AnyObject] = [:]
        NSLog("CompositeTextImage #register()")
        CIFilter.registerName("CompositeTextImage", constructor: PGLFilterConstructor(), classAttributes: [ kCIAttributeFilterCategories :
                              [kCICategoryGenerator ,
                               kCICategoryStillImage]
                              ])
    }

}
