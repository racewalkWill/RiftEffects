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
let kGradientAttributePrefix = "linear"

/// 5 sided gradient
class PGLTriangleGradientFilter: PGLSourceFilter {
    /// 12 storable values  3 linear gradients with 4 values - 2 vectors & 2 colors
    /// attribute namings is linear#value#  example linear1value2
    /// value1 and value2 are vectors
    ///  value3 and value4 are colors

        /// UI index for the current linear gradient
    var indexGradient = 0
    var sideCount = 3
    var linearGradients =  [PGLSourceFilter]()
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
//        for _ in 1 ... sideCount {
//            linearGradients.append(CIFilter(name: kGradientFilterName)!)
//        }

        for index in 0 ..< sideCount  {
            /// need inputDict that points to the attribute dict of the
            ///  component linearGradient filter
            ///   add sub cells below the parm row for the actual attributes
            ///    of the linearAttribute filter
//             inputDict: [String:Any] = [
//                "CIAttributeType" : kCIAttributeTypeGradient,
//                "CIAttributeClass":  "PGLGradientAttribute",
//                "CIAttributeDisplayName" : "Side " + String(index),
//                "kCIAttributeDescription": "A side of the gradient shape"
//            ]
            
            let thisAttributeKey = "Side" + String(index)
            //
            // for the attributes in the ciFilter parm
            if let  childLinearFilter = PGLGradientChildFilter(filter: "CILinearGradient", position: PGLFilterCategoryIndex()) {
                childLinearFilter.parentFilter = self
                childLinearFilter.sideKey = index

                linearGradients.append(childLinearFilter)
                let vectorAttributes = childLinearFilter.attributes.filter( {$0.isVector() })

                for aVector in vectorAttributes {
                    /// set to form linear1.inputPoint0 etc..
                    ///  decoded back in  PGLGradienChildFilter setVectorValue...
                    aVector.attributeName = kGradientAttributePrefix + String(index) + String(kPGradientKeyDelimitor) + aVector.attributeName!
                    aVector.attributeDisplayName = "Side " + String(index + 1 ) + " " + aVector.attributeDisplayName!
                    }
                attributes.append(contentsOf: vectorAttributes )
            }
        }
//        hasAnimation = true
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

        for index in 1 ..< sideCount - 2 {
            blendFilters[index].setValue(blendFilters[index - 1 ].outputImage, forKey: kCIInputImageKey)
            blendFilters[index].setValue(linearGradients[index + 1].outputImage, forKey: kCIInputBackgroundImageKey)
        }

        return blendFilters[sideCount - 2 ].outputImage
    }
    
        ///    format is gradient.keyName  ie linear1.inputPoint1
        ///    answer zero if not found
    func prefixGradientIndex(compoundKeyName: String) -> Int {
        if let delimitorIndex = compoundKeyName.firstIndex(of: kPGradientKeyDelimitor) {
            let prefix = compoundKeyName.prefix(upTo: delimitorIndex)
            let lastChar = prefix.last
            return lastChar?.wholeNumberValue ?? 0
        }
        return 0
    }

    /// attribute keyName is compound form of gradient.keyName  ie linear1.inputPoint1
    /// return the  gradient filter indicated by the prefix number
    func targetGradient(keyName: String) -> PGLSourceFilter? {
        let gradientIndex = prefixGradientIndex(compoundKeyName: keyName)
        if (linearGradients.isEmpty) || (linearGradients.count < gradientIndex - 1 ) {
            return nil
        }
        return linearGradients[gradientIndex]
    }
    override func setVectorValue(newValue: CIVector, keyName: String) {
        logParm(#function, newValue.debugDescription, keyName)

        if let targetGradient = targetGradient(keyName: keyName) {
            targetGradient.setVectorValue(newValue: newValue, keyName: keyName)
            postImageChange()
        }
    }

    override func valueFor( keyName: String) -> Any? {
        if let targetGradient = targetGradient(keyName: keyName) {
            return targetGradient.valueFor(keyName: keyName)
        }
        else {
           return super.valueFor(keyName: keyName)
        }
    }

}
