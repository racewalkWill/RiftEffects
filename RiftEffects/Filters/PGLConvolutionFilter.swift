//
//  PGLConvolutionFilter.swift
//  RiftEffects
//
//  Created by Will on 12/26/22.
//  Copyright © 2022 Will Loew-Blosser. All rights reserved.
//

import CoreImage

struct Matrix {
    /* from p 277
        The Swift Programming Language (Swift 5.6)
        Apple Inc.
        https://books.apple.com/us/book/the-swift-programming-language-swift-5-7/id881256329
    */

    let rows: Int, columns: Int
    var grid: [CGFloat]

    static func FromVector(baseRows: Int, baseColumns: Int ,  vector: CIVector) -> Matrix {
        var vectorMatrix = Matrix(rows: baseRows, columns: baseColumns)
        for thisRow in 0..<baseRows {
            for thisColumn in 0..<baseColumns {
                let rowOffset = thisRow * baseRows
                vectorMatrix[thisRow , thisColumn ] = vector.value(at: rowOffset + thisColumn)
            }
        }
        return vectorMatrix
    }
    init(rows: Int, columns: Int) {
        self.rows = rows
        self.columns = columns
        grid = Array(repeating: 0.0, count: rows * columns)
    }
    func indexIsValid(row: Int, column: Int) -> Bool {
        return row >= 0 && row < rows && column >= 0 && column < columns
    }
    subscript(row: Int, column: Int) -> Double {
        get {
            assert(indexIsValid(row: row, column: column), "Index out of range")
            return grid[(row * columns) + column]
        }
        set {
            assert(indexIsValid(row: row, column: column), "Index out of range")
            grid[(row * columns) + column] = newValue
        }
    }
}



class PGLConvolutionFilter: PGLSourceFilter {
    // implement 3,5,7,9 matrix CIConvolution group of filters
    //  "CIConvolution3X3", or "CIConvolution9Horizontal"

    var matrixSize = 0
    var isSquareMatrix = true
    // set matrixSize from the filter name
    var filterMatrix = Matrix(rows: 0, columns: 0)
    var weightsParmDict: [String : Any ]!

    required init?(filter: String, position: PGLFilterCategoryIndex) {

            // assumes that the size char is in the name..
        if filter.firstIndex(of: "3") != nil {
            matrixSize = 3
        }
        else { if filter.firstIndex(of: "5") != nil {
            matrixSize = 5
            }
            else { if filter.firstIndex(of: "7") != nil {
                matrixSize = 7
                }
                else { if filter.firstIndex(of: "9") != nil {
                    // one of the CIConvolution9Horizontal or CIConvolution9Vertical
                    matrixSize = 9
                    isSquareMatrix = false
                    }
                }
            }
        }
        if isSquareMatrix {
            filterMatrix = Matrix(rows: matrixSize, columns: matrixSize)
        }
        else { filterMatrix = Matrix(rows: 1, columns: matrixSize)
                // 1x9  CIConvolution9Horizontal or CIConvolution9Vertical
        }

        super.init(filter: filter, position: position)




    }

    override func parmClass(parmDict: [String : Any ]) -> PGLFilterAttribute.Type  {
           // override in PGLSourceFilter subclasses..
           // most will do a lookup in the class method

        if  (parmDict[kCIAttributeClass] as! String == AttrClass.Vector.rawValue)
        {
            weightsParmDict = parmDict
           return PGLAttributeWeightsVector.self }
        else {
                // not a vector parm... return a normal lookup.. usually the imageParm
            return PGLFilterAttribute.parmClass(parmDict: parmDict) }
       }

    func weightsAttributeName() -> String {
        return "inputWeights"
    }

    func setWeights(weightMatrix: Matrix) {
        //
        let newVector = CIVector(values: weightMatrix.grid, count: weightMatrix.grid.count)
        setVectorValue(newValue: newVector, keyName: weightsAttributeName())
    }


}


