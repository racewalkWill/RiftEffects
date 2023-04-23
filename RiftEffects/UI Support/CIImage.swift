//
//  CIImage.swift
//  PictureGlance
//
//  Created by Will Loew-Blosser on 2/23/17.
//  Copyright © 2017 Will Loew-Blosser. All rights reserved.
//

import Foundation
import CoreImage
import UIKit

extension CIImage {

    func thumbnailUIImage(_ preferredHeight: CGFloat = 56.0) -> UIImage {
        var outputImage = self
        if outputImage.extent.isInfinite {
            outputImage = cropForInfiniteExtent()
        }

        let sourceSize = outputImage.extent

        let scaleBy =  preferredHeight / sourceSize.height

        let thumbNailImage = outputImage.applyingFilter("CILanczosScaleTransform", parameters: ["inputScale" : scaleBy])

//          let theContext =  Renderer.ciContext // global context
//            let cgThumbnail = theContext?.createCGImage(thumbNailImage, from: CGRect.init(origin: CGPoint.zero, size: smallSize))
//            // the cgThumbnail needs to be released

        return  UIImage(ciImage: thumbNailImage)

    }

    func cropForInfiniteExtent() -> CIImage {

        if !self.extent.isInfinite {
            return self}
        let targetRect = CGRect(origin: CGPoint.zero, size: TargetSize)
            // TargetSize is the ImageController view size

        let returnImage = self.cropped(to: targetRect)

        return returnImage
    }

        /// resize input to match the target size
    func scale(targetSize: CGSize) -> CIImage {
        // assumes ciImage is not infinite extent
        if self.extent.isInfinite {
            // do nothing if extent isInfinite
            return self}
        if self.extent.size == targetSize {
            return self }

        let scaleX = targetSize.width / self.extent.width
        let scaleY = targetSize.height / self.extent.height
        let scaledCIImage  = self.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        return scaledCIImage
    }

    func translateNegativeXY() -> CIImage {
        var offsetX: CGFloat = 0.0
        var offsetY: CGFloat = 0.0
        var doTranslate = false
        let myExtent = extent
        if myExtent.minX < 0 {
            offsetX = abs(myExtent.minX)
            doTranslate = true
        }
        if myExtent.minY < 0 {
            offsetY = abs(myExtent.minY)
            doTranslate = true
        }
        if doTranslate {
            return self.transformed(by: CGAffineTransform(translationX: offsetX, y: offsetY))
        } else {
            return self
        }

    }

}
