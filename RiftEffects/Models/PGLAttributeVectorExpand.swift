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

    var scaler = CGAffineTransform(scaleX: 1000.0, y: 1000.0) {
        didSet {
            invertScaler = scaler.inverted()
        }
    }
    var invertScaler = CGAffineTransform(scaleX: 1000.0, y: 1000.0).inverted()

    override func set(_ value: Any) {
        // divide by the scaler
        if attributeName != nil {
            if let newVectorValue = value as? CIVector {

                let newVectorPoint = newVectorValue.cgPointValue
                let scaledPoint = newVectorPoint.applying(invertScaler)
                let scaledVectorValue = CIVector.init(cgPoint: scaledPoint)

                aSourceFilter.setVectorValue(newValue: scaledVectorValue, keyName: attributeName!) }
        }
    }

    override func getVectorValue() -> CIVector? {
        // multiply by the scaler..
        // make the graphic point easier to drag with enlarged scale
       guard let filterValue = getValue() as? CIVector
        else { return CIVector.init(cgPoint: CGPoint.zero)}

        let newVectorPoint = filterValue.cgPointValue
        let scaledPoint = newVectorPoint.applying(scaler)
        let scaledVectorValue = CIVector.init(cgPoint: scaledPoint)
        return scaledVectorValue
    }


}
