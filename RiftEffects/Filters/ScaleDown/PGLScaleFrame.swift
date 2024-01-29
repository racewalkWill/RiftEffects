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
/// position scaledDown image in composite blackBackgroud
///  holds a Lanzcos filter to downsize
///   answers composite black in view size with image downsized and positioned
class PGLScaleDownFrame: PGLSourceFilter {
    // return inputAttribute scaled down to the cropAttribute
    // Lanczos Scale Filter does this already.
    // use this frame for positioning at kCIInputCenterKey

    /// add to Filter framework
    ///
    let opaqueBackground: CIImage = CIImage.clear
    var centerPoint: CGPoint = CGPoint(x: TargetSize.width/2, y: TargetSize.height/2)
    var fullScreenRect: CGRect { get
    {   return CGRect(x: 0, y: 0, width: TargetSize.width, height: TargetSize.height)

        }
    }
/// add the centerPoint attribute to other Lanczos Scale attributes
    required init?(filter: String, position: PGLFilterCategoryIndex) {
        super.init(filter: filter, position: position)
        attributes.append(self.centerPointAttribute())
        hasAnimation = true }

    override class func localizedDescription(filterName: String) -> String {
        // custom subclasses should override
       return "Reduce to a smaller frame"
    }

    /// defines centerPoint for the LanczosScale rendering
    func centerPointAttribute() -> PGLFilterAttributeVector {
        let inputDict: [String:Any] = [
            "CIAttributeIdentity" : [200, 200],
            "CIAttributeDefault" : [200, 200],
            "CIAttributeType" : kCIAttributeTypePosition,
            "CIAttributeDisplayName" : "Center" ,
            "kCIAttributeDescription": "Position of the frame",
            "CIAttributeClass":  "CIVector"
        ]
        let newVectorAttribute = PGLFilterAttributeVectorUI(pglFilter: self, attributeDict: inputDict, inputKey: kCIInputCenterKey)
        return newVectorAttribute!
    }
    override func outputImageBasic() -> CIImage? {
//        guard let scaledImage = localFilter.outputImage else { return CIImage.empty() }
        guard let scaledImage = super.outputImageBasic()
        else { return CIImage.empty() }
        return positionOutput(ciOutput: scaledImage, inFrame: fullScreenRect, newCenterPoint: centerPoint)
    }


    func positionOutput(ciOutput: CIImage, inFrame: CGRect, newCenterPoint: CGPoint ) -> CIImage {

        let iRect: CGRect = ciOutput.extent
        let imageCenter = CGPoint(x: iRect.midX, y: iRect.midY)
        let shiftX = newCenterPoint.x - imageCenter.x
        let shiftY =  newCenterPoint.y - imageCenter.y
        let ciOutputImage = ciOutput.transformed(by: CGAffineTransform(translationX: shiftX, y: shiftY))

            // Blend the image over an opaque background image.
            // This is needed if the image is smaller than the view, or if it has transparent pixels.
        return ciOutputImage.composited(over: self.opaqueBackground)
     }

    /// set center point
    ///  cifilter does not hold the center point
    override func setVectorValue(newValue: CIVector, keyName: String) {
//        logParm(#function, newValue.debugDescription, keyName)
        centerPoint = CGPoint(x: newValue.x, y: newValue.y)
        postImageChange()
    }

    override func valueFor( keyName: String) -> Any? {
        if keyName == kCIInputCenterKey {
            return centerPoint
        } else {
           return super.valueFor(keyName: keyName)
        }
    }

}
