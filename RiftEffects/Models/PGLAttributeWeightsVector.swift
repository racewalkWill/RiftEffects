//
//  PGLAttributeWeightsVector.swift
//  RiftEffects
//
//  Created by Will on 12/29/22.
//  Copyright © 2022 Will Loew-Blosser. All rights reserved.
//

import Foundation

import UIKit

class PGLAttributeWeightsVector: PGLFilterAttributeVector {
    // convolution filters use a vector of weighted numerics
    // 3x3, 5x5, 7x7.. or 1x9

    // this is the parent attribute that displays an individual
    // cell slider for each element of the vector matrix.
    // Used by PGLConvolutionFilter and PGLNumericSliderUI

    override func set(_ value: Any) {
        guard let newValue = (value as? CIVector)
        else { return }
        // from the parent ConvlustionFilter get the
        // matrix
    }

    override func getValue() -> Any? {
        guard let convolutionFilter = aSourceFilter as? PGLConvolutionFilter
        else { return nil }
       guard  let myVector = getVectorValue()
        else { return nil }
        var vectorMatrix: Matrix
        var baseSize = 0

        switch myVector.count {
            case 9 :
                // 3x3 or 9x1
                if convolutionFilter.isOneRow {
                    vectorMatrix = Matrix(rows: 1, columns: 9) }
                else {
                    baseSize = 3
                }
            case 25 :
                // 5x5
                 baseSize = 5
            case 49 :
                // 7x7
                baseSize = 7

            default :
                baseSize = 0
        }
        vectorMatrix = Matrix.FromVector(baseSize: baseSize, vector: myVector)
        return vectorMatrix
    }

    override func valueInterface() -> [PGLFilterAttribute] {
        guard let convolution = aSourceFilter as? PGLConvolutionFilter
        else { return [PGLFilterAttribute]() }
        var sliderUI = [PGLNumericSliderUI] ()
        switch convolution.isOneRow {
            case false :
                for row in 0..<convolution.matrixSize {
                    for column in 0..<convolution.matrixSize {
                        if let newUIRow = PGLNumericSliderUI.init(convolution: convolution, matrixRow: row, matrixColumn: column)
                        {
                            sliderUI.append(newUIRow) }

                    }
                }
            case true :
                // 1x9 convolution
                for column in 0..<convolution.matrixSize {
                    if let newUIRow = PGLNumericSliderUI.init(convolution: convolution, matrixRow: 0 , matrixColumn: column)
                    { sliderUI.append(newUIRow) }

                }
        }
        return sliderUI
    }



}

