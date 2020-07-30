//
//  PGLQRCodeGenerator.swift
//  Glance
//
//  Created by Will on 6/19/20.
//  Copyright © 2020 Will. All rights reserved.
//

import Foundation

class PGLQRCodeGenerator: PGLSourceFilter {
    // the CIQRCodeGenerator does not have a defaults
    //  "CIQRCodeGenerator filter requires L, M, Q, or H for inputCorrectionLevel"

    static let inputCorrectionLevelSettings: [NSString] = ["L", "M", "Q", "H" ]

    required init?(filter: String, position: PGLFilterCategoryIndex) {
           super.init(filter: filter, position: position)
        let defaultCorrectionLevel = (PGLQRCodeGenerator.inputCorrectionLevelSettings.first)!
        setStringValue(newValue: defaultCorrectionLevel, keyName: "inputCorrectionLevel")
           hasAnimation = false }

}
