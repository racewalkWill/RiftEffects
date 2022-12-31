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

    lazy var localMatrix: Matrix = getMatrixValue()

    override func set(_ value: Any) {
        guard let newValue = (value as? CIVector)
        else { return }
            // from the parent ConvlustionFilter get the
            // matrix
        fatalError("call the filter set with the attribute name")
    }

     func getMatrixValue() -> Matrix {
        guard let convolutionFilter = aSourceFilter as? PGLConvolutionFilter
        else { return  Matrix(rows: 0, columns: 0) }
        guard  let myVector = convolutionFilter.valueFor(keyName: attributeName!) as? CIVector
        else { return  Matrix(rows: 0, columns: 0) }
        var vectorMatrix: Matrix
        var baseSize = 0

        switch myVector.count {
            case 9 :
                    // 3x3 or 9x1
                baseSize = 3
            case 25 :
                    // 5x5
                baseSize = 5
            case 49 :
                    // 7x7
                baseSize = 7

            default :
                baseSize = 0
        }
        
         if convolutionFilter.isSquareMatrix {
            vectorMatrix = Matrix.FromVector(baseRows: baseSize, baseColumns: baseSize, vector: myVector)
        }
        else {
            vectorMatrix = Matrix.FromVector(baseRows: 1, baseColumns: 9, vector: myVector)
        }

        return vectorMatrix
    }

    func getValue(row: Int, column: Int) -> Double {
        return localMatrix[row, column]
    }

    override func valueInterface() -> [PGLFilterAttribute] {
        guard let convolution = aSourceFilter as? PGLConvolutionFilter
        else { return [PGLFilterAttribute]() }
        var sliderUI = [PGLNumericSliderUI]()
        if convolution.isSquareMatrix {
            for row in 0..<convolution.matrixSize {
                for column in 0..<convolution.matrixSize {
                    if let newUIRow = PGLNumericSliderUI.init(convolution: self, matrixRow: row, matrixColumn: column)
                    {
                        sliderUI.append(newUIRow) }
                }
            }
        }
        else {
                // 1x9 convolution
            for column in 0..<convolution.matrixSize {
                if let newUIRow = PGLNumericSliderUI.init(convolution: self, matrixRow: 0 , matrixColumn: column)
                { sliderUI.append(newUIRow) }
            }
        }
        return sliderUI
    }

}
