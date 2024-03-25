//
//  PGLGradientAttribute.swift
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

class PGLGradientAttribute: PGLFilterAttribute {
    // holds vector points for the linear gradient

    // these are already attributes of the CILinearGradient

//    var point0: CIVector
//    var point1: CIVector
//    var inputColor0: CIColor
//    var inputColor1: CIColor

    required init?(pglFilter: PGLSourceFilter, attributeDict: [String:Any], inputKey: String ) {

        super.init(pglFilter: pglFilter, attributeDict: attributeDict, inputKey: inputKey)
     

    }
}
