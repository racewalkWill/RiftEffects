//
//  PGLScalingFilter.swift
//  Surreality
//
//  Created by Will on 5/10/21.
//  Copyright © 2021 Will Loew-Blosser. All rights reserved.
//

import Foundation

import CoreImage
//import simd
//import UIKit
//import Photos

class PGLScalingFilter: PGLSourceFilter {

    override func scaleOutput(ciOutput: CIImage, stackCropRect: CGRect) -> CIImage {
         // CIGaussianGradient RectangleFilter needs to crop then scale to full size
        // could have also used CIEdgePreserveUpsample??

         // Most filters do not need this. Parnent PGLSourceFilter has empty implementation
           //ciOutputImage.extent    CGRect    (origin = (x = 592, y = 491), size = (width = 729, height = 742))
         // currentStack.cropRect    CGRect    (origin = (x = 0, y = 0), size = (width = 1583, height = 1668))
         let widthScale = stackCropRect.width / ciOutput.extent.width
         let heightScale = stackCropRect.height / ciOutput.extent.height

         let scaleTransform = CGAffineTransform(scaleX: widthScale, y: heightScale)
         let translate = scaleTransform.translatedBy(x: -ciOutput.extent.minX, y: -ciOutput.extent.minY)

         return ciOutput.transformed(by: translate)
     }

}
