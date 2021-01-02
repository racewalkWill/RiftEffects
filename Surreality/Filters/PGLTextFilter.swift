//
//  PGLTextFilter.swift
//  Glance
//
//  Created by Will on 6/19/20.
//  Copyright © 2020 Will. All rights reserved.
//

import Foundation

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

    let defaultFontSize: NSNumber = 30 // init value of defaultValue= Optional(12.0) is too small to see
    let defaultScaleFactor: NSNumber = 2 // these init values too small
        //sliderMinValue= Optional(1.0) sliderMaxValue= Optional(4.0) defaultValue= Optional(1.0)

    required init?(filter: String, position: PGLFilterCategoryIndex) {
        super.init(filter: filter, position: position)
        setNumberValue(newValue: defaultFontSize, keyName: "inputFontSize")
        setNumberValue(newValue: defaultScaleFactor, keyName: "inputScaleFactor")
    }
}
