//
//  PGL5SidedGradientFilter.swift
//  RiftEffects
//
//  Created by Will on 3/23/24.
//  Copyright © 2024 Will Loew-Blosser. All rights reserved.
//

import Foundation
import CoreImage
import simd
import UIKit
import os

let kGradientBlendFilter = "CIDarkenBlendMode"
let kGradientFilterName = "CILinearGradient"

/// 5 sided gradient
class PGLTriangleGradientFilter: PGLSourceFilter {
    /// 12 storable values  3 linear gradients with 4 values - 2 vectors & 2 colors
    /// attribute namings is linear#value#  example linear1value2
    /// value1 and value2 are vectors
    ///  value3 and value4 are colors

        /// UI index for the current linear gradient
    var indexGradient = 0
    var sideCount = 3
    var linearGradients =  [CIFilter]()
    var blendFilters = [CIFilter]()
    var valueParms = [PGLFilterAttribute]()
    var centerPoint: CGPoint = CGPoint(x: TargetSize.width/2, y: TargetSize.height/2)
//    var gradientKeys: [String:]

    required init?(filter: String, position: PGLFilterCategoryIndex) {

        // on UI select of a linear attribute then four subcells of 4 values
        super.init(filter: filter, position: position)
        attributes.append(self.centerPointAttribute() )
        for _ in 1 ..< sideCount {
            blendFilters.append(CIFilter(name: kGradientBlendFilter)! )
        }
        for _ in 1 ... sideCount {
            linearGradients.append(CIFilter(name: kGradientFilterName)!)
        }

        for index in 0 ..< sideCount  {
            /// need inputDict that points to the attribute dict of the
            ///  component linearGradient filter
            ///   add sub cells below the parm row for the actual attributes
            ///    of the linearAttribute filter
            let inputDict: [String:Any] = [
                "CIAttributeType" : kCIAttributeTypeGradient,
                "CIAttributeClass":  "PGLGradientAttribute",
                "CIAttributeDisplayName" : "Gradient" ,
                "kCIAttributeDescription": "A side of the gradient shape"
            ]
            let thisAttributeKey = "linear" + String(index)
            if let newAttribute = PGLGradientAttribute(pglFilter: self , attributeDict: inputDict, inputKey: thisAttributeKey) {
                attributes.append(newAttribute) }
        }
        hasAnimation = true
    }

    override class func localizedDescription(filterName: String) -> String {
        // custom subclasses should override
       return "Gradient with 5 sides"
    }

    func centerPointAttribute() -> PGLFilterAttributeVector {
        let inputDict: [String:Any] = [
            "CIAttributeIdentity" : [200, 200],
            "CIAttributeDefault" : [200, 200],
            "CIAttributeType" : kCIAttributeTypePosition,
            "CIAttributeDisplayName" : "Center" ,
            "kCIAttributeDescription": "Position of the frame",
            "CIAttributeClass":  "CIVector"
        ]
        let newVectorAttribute = PGLFilterAttributeVectorUI(pglFilter: self, attributeDict: inputDict, inputKey: kCIInputCenterKey)
        return newVectorAttribute!
    }


    override func outputImageBasic() -> CIImage? {
        blendFilters[0].setValue(linearGradients[0].outputImage, forKey: kCIInputImageKey)
        blendFilters[0].setValue(linearGradients[1].outputImage, forKey: kCIInputBackgroundImageKey)

        for index in 1 ..< sideCount {
            blendFilters[index].setValue(blendFilters[index - 1 ].outputImage, forKey: kCIInputImageKey)
            blendFilters[index].setValue(linearGradients[index + 1].outputImage, forKey: kCIInputBackgroundImageKey)
        }

        return blendFilters[sideCount - 1 ].outputImage
    }

    override func setVectorValue(newValue: CIVector, keyName: String) {
//        logParm(#function, newValue.debugDescription, keyName)
//        centerPoint = CGPoint(x: newValue.x, y: newValue.y)

        postImageChange()
    }

    override func valueFor( keyName: String) -> Any? {
        if keyName == kCIInputCenterKey {
            return centerPoint
        } else {
           return super.valueFor(keyName: keyName)
        }
    }

}
