//
//  PGLAttributeVectorNumericUI.swift
//  RiftEffects
//
//  Created by Will on 12/11/22.
//  Copyright © 2022 Will Loew-Blosser. All rights reserved.
//

import Foundation
import CoreImage

/// slider interface to color adjustment vector parms
class PGLAttributeVectorNumericUI: PGLFilterAttribute {

    ///  which element of the 4 part vector to update..
    ///   values 0..3
    enum ColorVector: Int {
        case inputRVector = 0
        case inputGVector = 1
        case inputBVector = 2
        case inputAVector = 3
        case inputBiasVector = 4
    }

   static let ColorDict = [
    "inputRVector" : ColorVector.inputRVector,
    "inputGVector" : ColorVector.inputGVector,
    "inputBVector" : ColorVector.inputBVector,
    "inputAVector" : ColorVector.inputAVector,
    "inputBiasVector" : ColorVector.inputBiasVector
    ]

    /// index of the attribute color in the 4 element vector RGBA
   private var vectorOffset = 0


    var parentVectorAttribute: PGLAttributeVectorNumeric? {
        didSet {
            // lookup the vector position by the attribute name
            guard let vectorColorPosition =  PGLAttributeVectorNumericUI.ColorDict[parentVectorAttribute?.attributeName ?? "missingAttributeName"]
            else {
                fatalError("PGLAttributeVectorNumericUI has unexpected attribute")
            }
            vectorOffset = vectorColorPosition.rawValue
            attributeDisplayName = parentVectorAttribute?.attributeDisplayName
            attributeName = parentVectorAttribute?.attributeName
            attributeType = AttrType.Scalar.rawValue
        }
    }


    required init?(pglFilter: PGLSourceFilter, attributeDict: [String : Any], inputKey: String) {

        super.init(pglFilter: pglFilter, attributeDict: attributeDict, inputKey: inputKey)

        // set types and max min values for the UISlider
        minValue = 0.0
        sliderMaxValue = 1.0
        sliderMinValue = 0.0



    }

    override func set(_ value: Any) {
        guard let newValue = (value as? NSNumber) as? CGFloat
        else { return }
            // put this into the parentVector at the vectorOffset
        guard let theParentVector = parentVectorAttribute?.getVectorValue()
        else { return }

        var newVector: CIVector!
        switch vectorOffset {
            case ColorVector.inputRVector.rawValue:
                newVector = CIVector(x: newValue, y: 0, z: 0, w: theParentVector.w)
            case ColorVector.inputGVector.rawValue :
                newVector = CIVector(x: 0, y: newValue, z: 0, w: theParentVector.w)
            case ColorVector.inputBVector.rawValue:
                newVector = CIVector(x: 0, y: 0, z: newValue, w: theParentVector.w)
            case ColorVector.inputAVector.rawValue:
                newVector = CIVector(x: 0, y: 0, z: 0, w: newValue)
            case ColorVector.inputBiasVector.rawValue:
                // bias is a vector that’s added to each color component
                // make all four components the same slider value
                newVector = CIVector(x: newValue, y: newValue, z: newValue, w: newValue)
            default:
                return // without setting a value
        }

        parentVectorAttribute?.set(newVector!)

    }

    override func getValue() -> Any? {
        // assumes parentVectorAttribute is set with
        // and then private vectorOffset is established
        guard let currentVector = parentVectorAttribute?.getVectorValue()
            else {
            return nil }
        switch vectorOffset {
            case ColorVector.inputRVector.rawValue:
                return currentVector.x
            case ColorVector.inputGVector.rawValue:
                return currentVector.y
            case ColorVector.inputBVector.rawValue:
                return currentVector.z
            case ColorVector.inputAVector.rawValue:
                return currentVector.w
            case ColorVector.inputBiasVector.rawValue:
                return currentVector.x // assumes that all four components have the same value
                // just return the first component in the bias

            default: return nil
        }

    }


}
