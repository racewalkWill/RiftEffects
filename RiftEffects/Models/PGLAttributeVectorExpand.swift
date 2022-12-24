//
//  PGLAttributeVectorExpand.swift
//  RiftEffects
//
//  Created by Will on 12/14/22.
//  Copyright © 2022 Will Loew-Blosser. All rights reserved.
//

import Foundation

import UIKit
import Photos
import CoreImage

class PGLAttributeVectorExpand: PGLFilterAttributeVector {

    var scaler = CGAffineTransform(scaleX: 1000.0, y: 1000.0)

    override func set(_ value: Any) {
        // divide by the scaler
        if attributeName != nil {
            if let newVectorValue = value as? CIVector {

                let scaledVectorValue = scaleVector(inputVector: newVectorValue, scaleBy: scaler, divideScale: true)

                aSourceFilter.setVectorValue(newValue: scaledVectorValue, keyName: attributeName!) }
        }
    }

    override func getVectorValue() -> CIVector? {
        // multiply by the scaler..
        // make the graphic point easier to drag with enlarged scale
       guard let filterValue = getValue() as? CIVector
        else { return CIVector.init(cgPoint: CGPoint.zero)}

        let scaledVectorValue = scaleVector(inputVector: filterValue, scaleBy: scaler, divideScale: false)

        return scaledVectorValue
    }



}
