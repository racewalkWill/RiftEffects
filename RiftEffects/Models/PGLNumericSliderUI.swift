//
//  PGLNumericSliderUI.swift
//  RiftEffects
//
//  Created by Will on 12/27/22.
//  Copyright © 2022 Will Loew-Blosser. All rights reserved.
//

import Foundation

import UIKit

class PGLNumericSliderUI: PGLFilterAttribute {
    // number slider in the parm list cell
    // used for Convolution numeric parms

    var row = 0
    var column = 0

    var convolutionParent: PGLConvolutionFilter!

    init?(convolution: PGLConvolutionFilter, matrixRow: Int, matrixColumn: Int) {

        convolutionParent = convolution
        row = matrixRow
        column = matrixColumn

        super.init(pglFilter: convolution, attributeDict: convolution.weightsParmDict(), inputKey: convolution.weightsAttributeName())


        attributeDisplayName = "Point"
        attributeName = attributeDisplayName! + " \(row)x\(column)"
            // attributeName is index for parm controls must be unique

        attributeType = AttrType.Scalar.rawValue
            // Interface Builder slider max attribute controls these setting
        sliderMaxValue = 1.0
        sliderMinValue = 0.0
        defaultValue = 0.0
        identityValue = 0.0
        indentLevel = 1

    }

    required init?(pglFilter: PGLSourceFilter, attributeDict: [String : Any], inputKey: String) {
        super.init(pglFilter: pglFilter, attributeDict: attributeDict, inputKey: inputKey)
    }




}
