//
//  PGLVisionProtocol.swift
//  Glance
//
//  Created by Will on 6/14/20.
//  Copyright © 2020 Will. All rights reserved.
//

import Photos
import UIKit
import CoreImage
import Vision

class DetectorFramework {
    static var Active  = PGLVisionDetector.self
    // or PGLVisionDetector.self for Vision Framework
    // PGLDetector.self for CIDetector
    // Both classes  implement the PGLDetecton protocol
        // PGLDetector uses the older CIDetector for faces

}

// change to new vision implementor here


protocol PGLDetection {
    // implementation framework for both the CIDetector and Vision VN classes
    // PGLVisionDetector or PGLDetector
    // MARK: PGLDetector methods
    // these all have external callers

    var features: [PGLFaceBounds] { get set }
    var inputTime: Double { get set }
    init (ciFilter: CIFilter?)
    func increment()
    func setInput(image: CIImage?, source: String?)
    func setOutputAttributes(wrapperFilter: PGLDissolveWrapperFilter)
    func featureImagePair() ->(inputFeature: CIImage, targetFeature: CIImage)
        // used for the first setup of the dissolve wrapper
        // answers the internal filter output with two images for a dissolve
    func nextImage() -> CIImage
     func outputFeatureImages() -> [CIImage]

    func setCIContext(detectorContext: CIContext?)
    func releaseContext()
    func releaseTargetAttributes()
    func setInputTime(time: Double)


}

class PGLFaceBounds {
    // wrapper for either VNFaceObservation or CIFaceFeature
    // common way to query for the boundingBox
    var sourceVNFace: VNFaceObservation?
    var sourceCIFace: CIFaceFeature?

    init(onVNFace: VNFaceObservation?, onCIFace: CIFaceFeature? ) {
        sourceVNFace = onVNFace
        sourceCIFace = onCIFace

    }
    func isVNFace() -> Bool? {
        if sourceVNFace != nil
            { return true }
        if sourceCIFace != nil
           { return false }

        return nil
    }

    func boundingBox() -> CGRect? {
        if isVNFace() ?? false {
            if let thisFaceBox = sourceVNFace?.boundingBox {
                // bounding box is normalized coordinates in range of 0..1
//                let affineTransform = CGAffineTransform(scaleX: thisFaceBox.size.width, y: thisFaceBox.size.height)
//                   let scaledBox = thisFaceBox.applying(affineTransform)

                return thisFaceBox
            } else { return CGRect.zero}
        } else {
            let theBounds =  sourceCIFace?.bounds
//            NSLog( "PGLFaceBounds #boundingBox answers theBounds = \(theBounds)")
            return theBounds
        }
    }

    func boundingBox(withinImageBounds bounds: CGRect) -> CGRect {
        // Vision Framework method
        // based on VisonBasics sample app
        // func boundingBox(forRegionOfInterest: CGRect, withinImageBounds bounds: CGRect) -> CGRect
        if !(isVNFace() ?? true) {

            let answerBounds =  sourceCIFace!.bounds
//            NSLog( "PGLFaceBounds #boundingBox  answerBounds = \(answerBounds)")
            return answerBounds
        }

        let imageWidth = bounds.width
        let imageHeight = bounds.height

        // Begin with input rect.
        var rect = sourceVNFace?.boundingBox ?? CGRect.zero

        // Reposition origin.
        rect.origin.x *= imageWidth
        rect.origin.x += bounds.origin.x
        rect.origin.y = (1 - rect.origin.y) * imageHeight + bounds.origin.y

        // Rescale normalized coordinates.
        rect.size.width *= imageWidth
        rect.size.height *= imageHeight

//        NSLog( "PGLFaceBounds #boundingBox answers rect = \(rect)")
        return rect
    }

    func hasTrackingFrameCount() -> Bool {
        if isVNFace() ?? false {
//            return sourceVNFace?.hasTrackingFrameCount ?? false
            return false // need to locate the tracking data..
        } else {
            return sourceCIFace?.hasTrackingFrameCount ?? false
        }
    }

        func trackingFrameCount() -> Int32 {
                if isVNFace() ?? false {
        //            return sourceVNFace?.hasTrackingFrameCount ?? false
                    return 0 // need to locate the tracking data..
                } else {
                    return sourceCIFace?.trackingFrameCount ?? 0
                }
            }
}


