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
        // CIQRCodeGenerator  inputMessage 
        // CITextImageGenerator inputText

    // see the PGLSelectParmController methods for UITextFieldDelegate

}

class PGLQRCodeGenerator: PGLTextFilter {
    // the CIQRCodeGenerator does not have a defaults
    //  "CIQRCodeGenerator filter requires L, M, Q, or H for inputCorrectionLevel"

    static let inputCorrectionLevelSettings: [NSString] = ["L", "M", "Q", "H" ]

    required init?(filter: String, position: PGLFilterCategoryIndex) {
           super.init(filter: filter, position: position)
        let defaultCorrectionLevel = (PGLQRCodeGenerator.inputCorrectionLevelSettings[2])
        // default is "Q" 25% additional encoding size for error correction
        setStringValue(newValue: defaultCorrectionLevel, keyName: "inputCorrectionLevel")
           hasAnimation = false

    }

    override func setStringValue(newValue: NSString, keyName: String) {
        // convert to matching inputCorrectionLevel
        if keyName == "inputCorrectionLevel" {
            if PGLQRCodeGenerator.inputCorrectionLevelSettings.contains(newValue) {
                super.setStringValue(newValue: newValue, keyName: keyName)
            }
        }
    }
}

class PGLCIAztecCodeGenerator: PGLTextFilter {
    // filter attributes to match CIAztecCodeGenerator requirements

    override func setNumberValue(newValue: NSNumber, keyName: String) {
        switch keyName {
//          case "inputCorrectionLevel":
//                default case
            case "inputLayers" :
                if (newValue.floatValue <= 32.00) {
                    super.setNumberValue(newValue: newValue, keyName: keyName)
                } else {
                    super.setNumberValue(newValue: 0.0, keyName: keyName)
                }
            case "inputCompactStyle" :
                if (newValue.boolValue) {
                    // true case
                    super.setNumberValue(newValue: 1.0, keyName: keyName)
                } else {
                    // false case
                    super.setNumberValue(newValue: 0.0, keyName: keyName)
                }
            default:
                super.setNumberValue(newValue: newValue, keyName: keyName)
        }
    }
}



class PGLTextImageGenerator: PGLTextFilter {
    // overide defaults for Font Size and Scale Factor
    // adds a position parm for text positioning
    // uses CompositeTextPositionFilter and positions origin of the text 

    override class func displayName() -> String? {
        return "Blend Text"
    }



}

class CompositeTextPositionFilter: CIFilter {
    let blendFilter: CIFilter
    let textImageFilter: CIFilter

    @objc var inputImage : CIImage?
    @objc var inputScaleFactor: NSNumber = 2
    @objc var inputFontName: NSString = "HelveticaNeue"
    @objc var inputFontSize: NSNumber = 24
    @objc var inputText: NSString = "Text"
    @objc var inputTextPosition: CIVector = CIVector(x: 100.0, y: 100.0)

    override init() {
        blendFilter = CIFilter(name: "CIDivideBlendMode")!
        textImageFilter = CIFilter(name: "CITextImageGenerator", parameters: ["inputFontSize" : 30, "inputScaleFactor" : 2])!
        super.init()
    }

    required init?(coder aDecoder: NSCoder)
    {
        blendFilter = CIFilter(name: "CIDivideBlendMode")!
        textImageFilter = CIFilter(name: "CITextImageGenerator", parameters: ["inputFontSize" : 30, "inputScaleFactor" : 2])!
        super.init(coder: aDecoder)
//        fatalError("init(coder:) has not been implemented")
    }

    func positionText(textCIImage: CIImage) -> CIImage {
        // similar to the filter method  PGLRectangleFilter.scaleOutput
        // this is internal to filter for chaining from textImageFilter to
        // the blendFilter

        let midPointY = textCIImage.extent.midY
        let translate = CGAffineTransform(translationX: inputTextPosition.x, y: (inputTextPosition.y - midPointY))

        return textCIImage.transformed(by: translate)
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
        guard let textOutput = textImageFilter.outputImage else {
            return inputImage
        }
        // scale & position textOutput to the inputTextPosition
        let scaledText = positionText(textCIImage: textOutput)
        blendFilter.setValue(scaledText, forKey: kCIInputBackgroundImageKey)
        blendFilter.setValue(inputImage, forKey: kCIInputImageKey)

        return blendFilter.outputImage
    }

    override var attributes: [String : Any]
    {
        let textAttributes: [String:Any] = [
            kCIAttributeFilterCategories :
                                  [kCICategoryGenerator ,
                                   kCICategoryCompositeOperation,
                                   kCICategoryStillImage,
                                  kCICategoryVideo],

            kCIAttributeFilterDisplayName : "Blend Text",

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

            "inputTextPosition" : [ kCIAttributeClass: "CIVector",
                                        kCIAttributeType: "CIAttributeTypePosition",
                                        kCIAttributeDefault: CIVector(x: 50.0, y: 50.0),
                                        kCIAttributeDisplayName: "Text Position",
                                        kCIAttributeDescription: "Position Text"
                                        ]
            ]

        return textAttributes
    }




    class func register()   {
 //       let attr: [String: AnyObject] = [:]
        NSLog("CompositeTextPositionFilter #register()")
        CIFilter.registerName(kCompositeTextPositionFilter, constructor: PGLFilterConstructor(), classAttributes: [
            kCIAttributeFilterCategories :    [kCICategoryGenerator ,
                                               kCICategoryStillImage,
                                               kCICategoryVideo],
            kCIAttributeFilterDisplayName : "Blend Text"
            ])
    }

}
