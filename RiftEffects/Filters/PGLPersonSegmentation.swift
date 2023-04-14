//
//  PGLPersonSegmentation.swift
//  RiftEffects
//
//  Created by Will on 4/14/23.
//  Copyright © 2023 Will Loew-Blosser. All rights reserved.
//

import Foundation

import CoreImage

/// scales segmentationMatte to match input to the CISegmentation
class PGLPersonSegmentation: PGLSourceFilter {
    // modified for CIPersonSegmentation
    // see CIFilter class extension method #pglClassMap
    // CIPersonSegmentation states in description
    //   "The returned image may have a different size and aspect ratio from the input image"


    override func scaleOutput(ciOutput: CIImage, stackCropRect: CGRect) -> CIImage {

        let scaleX = stackCropRect.width / ciOutput.extent.width
        let scaleY = stackCropRect.height / ciOutput.extent.height
        let maskImage = ciOutput.transformed(by: .init(scaleX: scaleX, y: scaleY))

        return maskImage
    }



}
