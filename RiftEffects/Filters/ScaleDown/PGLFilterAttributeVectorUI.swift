//
//  PGLFilterAttributeVectorUI.swift
//  RiftEffects
//
//  Created by Will on 12/5/23.
//  Copyright © 2023 Will Loew-Blosser. All rights reserved.
//

import Foundation
import UIKit
import os


// get/set vector point in the PGLSourceFilter..
// value not held in the ciFilter attribute

class PGLFilterAttributeVectorUI: PGLFilterAttributeVector {

    override func getVectorValue() -> CIVector? {
        guard let myParent = self.aSourceFilter as? PGLScaleDownFrame
        else { return nil }
        return CIVector(cgPoint: myParent.centerPoint )

    }

    override func set(_ value: Any) {
        if attributeName != nil {
            if let newVectorValue = value as? CIVector {
                aSourceFilter.setVectorValue(newValue: newVectorValue, keyName: attributeName!) }
        }
    }
}
