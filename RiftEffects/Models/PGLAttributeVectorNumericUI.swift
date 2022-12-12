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
   private var vectorOffset = 0
    private var parentVector: CIVector?

    var parentVectorAttribute: PGLAttributeVectorNumeric? {
        didSet {
            parentVector = parentVectorAttribute?.getVectorValue()
            for i in 0...3 {
                if parentVector?.value(at: i) == 1 {
                    vectorOffset = i

                    break
                }
            }
            attributeDisplayName = parentVectorAttribute?.attributeDisplayName
            attributeName = (parentVectorAttribute?.attributeName ?? "") + "UI"
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
        guard let theParentVector = parentVector
        else { return }

        var newVector: CIVector!
        switch vectorOffset {
            case 0:
                newVector = CIVector(x: newValue, y: 0, z: 0, w: theParentVector.w)
            case 1 :
                newVector = CIVector(x: 0, y: newValue, z: 0, w: theParentVector.w)
            case 2:
                newVector = CIVector(x: 0, y: 0, z: newValue, w: theParentVector.w)
            case 3:
                newVector = CIVector(x: newValue, y: 0, z: 0, w: newValue)
            default:
                newVector = parentVector // preservve old values as default
        }
        parentVector = newVector
        parentVectorAttribute?.set(parentVector!)

    }

    override func getValue() -> Any? {
        // assumes parentVectorAttribute is set with
        // and then private vectorOffset is established
        if parentVector == nil {
            return nil
        }
        switch vectorOffset {
            case 0:
                return parentVector!.x
            case 1:
                return parentVector!.y
            case 2:
                return parentVector!.z
            case 3:
                return parentVector!.w
            default: return nil
        }

    }


}
