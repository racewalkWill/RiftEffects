//
//  PGLScaleFrame.swift
//  RiftEffects
//
//  Created by Will on 11/27/23.
//  Copyright © 2023 Will Loew-Blosser. All rights reserved.
//

import Foundation
import CoreImage
import simd
import UIKit
import os


/// scale a stack output to a smaller rectangle
class PGLScaleDownFrame: PGLRectangleFilter {
    // return inputAttribute scaled down to the cropAttribute

    /// add to Filter framework
    required init?(filter: String, position: PGLFilterCategoryIndex) {
        super.init(filter: filter, position: position)
        hasAnimation = true }

    override class func localizedDescription(filterName: String) -> String {
        // custom subclasses should override
       return "Reduce to a smaller frame"
    }


    override func scaleOutput(ciOutput: CIImage, stackCropRect: CGRect) -> CIImage {

        let smallerImage =  super.scaleOutput(ciOutput: ciOutput, stackCropRect: attributeCropRect())
        return smallerImage
    }
}
