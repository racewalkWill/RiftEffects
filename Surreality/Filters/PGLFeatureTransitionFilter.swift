//
//  PGLFeatureTransitionFilter.swift
//  Glance
//
//  Created by Will on 1/27/19.
//  Copyright © 2019 Will Loew-Blosser. All rights reserved.
//

import Foundation
import UIKit

import CoreImage
import simd

class PGLFeatureTransitionFilter: PGLTransitionFilter {

//    var detectorFilter = ((PGLFilterDescriptor(kPFaceFilter,PGLDetector.self)?.pglSourceFilter() ) as! PGLDetector)
    var detectorFilter: PGLDetection?
        // note that superclass PGLSourceFilter has array of detectors.. this should be the first one???
        // var detectors = [PGLDetector]()
        // alternatively this detector is processing multiple images as they cycle .. so just one makes sense too


    override class func displayName() -> String? {
        return "Feature Dissolve"
    }

//    required init?(filter: String, position: PGLFilterCategoryIndex) {
//        super.init(filter: filter, position: position)
//        hasAnimation = true
//        detectorFilter = PGLDetector(ciFilter: PGLFaceCIFilter())
//
//    }
    override func setCIContext(detectorContext: CIContext?) {
        // pass on the context for the  detectorFilter.detector
       detectorFilter?.setCIContext(detectorContext: detectorContext)
    }
    
    override func setImageListClone(cycleStack: PGLImageList, sourceKey: String) {
        // calls requestImage for the asset
        // add images for each feature of an image in the cycleStack..
        // then clone with super to setImageListClone
        if cycleStack.nextType == NextElement.odd { return }
        // stop.. don't make a further clone. Even stack clones odd stack and stops
        
        var theImages = [CIImage]()
        var thisSet = [CIImage]()
        for index in 0..<(cycleStack.sizeCount() ) {
            if let theImage = cycleStack.image(atIndex: index) {
             // image(atIndex: int) calls requestImage for the asset
            detectorFilter?.setInput(image: theImage, source: "blank")
            thisSet = detectorFilter?.outputFeatureImages() ?? [theImage] // should always be at least one image
//          NSLog("PGLFeatureTransitionFilter #setImageListClone on image = \(theImage)")
//          NSLog("PGLFeatureTransitionFilter #setImageListClone has feature set count = \(thisSet.count)")

            theImages.append(contentsOf: thisSet)
            }

        }

        cycleStack.setImages(ciImageArray: theImages)
            // sets all of the images from the  getImage call

        super.setImageListClone(cycleStack: cycleStack, sourceKey: sourceKey)
            // now do the same for the clone of the odd numbered images

    }
}

class PGLBumpTransitionFilter: PGLFeatureTransitionFilter {

    override class func displayName() -> String? {
        return "Bump Dissolve"
    }

    required init?(filter: String, position: PGLFilterCategoryIndex) {
        super.init(filter: filter, position: position)

        detectorFilter = DetectorFramework.Active.init(ciFilter:  PGLBumpFaceCIFilter() )
        guard let myAppDelegate =  UIApplication.shared.delegate as? AppDelegate
                   else {
                NSLog("PGLBumpTransitionFilter init did not load AppDelegate")
                return
        }
               guard let appStack = myAppDelegate.appStack
                   else {return }
               detectorFilter?.setCIContext(detectorContext: appStack.getViewerStack().imageCIContext)
    }
    


}

class PGLFaceTransitionFilter: PGLFeatureTransitionFilter {

    override class func displayName() -> String? {
        return "Face Dissolve"
    }

    required init?(filter: String, position: PGLFilterCategoryIndex) {
        super.init(filter: filter, position: position)

        detectorFilter = DetectorFramework.Active.init(ciFilter:  PGLFaceCIFilter() )
        guard let myAppDelegate =  UIApplication.shared.delegate as? AppDelegate
            else {
            NSLog("PGLFaceTransitionFilter init did not load AppDelegate")
            return
        }
        guard let appStack = myAppDelegate.appStack
            else {return }
        detectorFilter?.setCIContext(detectorContext: appStack.getViewerStack().imageCIContext)

    }


}
class PGLBumpBlend: PGLSourceFilter {
    override class func displayName() -> String? {
           return "Bump Blend"
       }
    required init?(filter: String, position: PGLFilterCategoryIndex) {
         super.init(filter: filter, position: position)
    }
}
    
class PGLDissolveWrapperFilter: PGLFeatureTransitionFilter {
    // on a point parm double tap this is installed as a wrapper
    // a detector will find features (usually faces)
    // this wrapper will dissolve from feature 1 to feature2 as
    // inputs on the point parm.  for example the Center point on
    // a vignette effect will dissolve from face to face.
    override class func displayName() -> String? {
        return "Dissolve Wrapper"
    }

    required init?(filter: String, position: PGLFilterCategoryIndex) {
        super.init(filter: filter, position: position)
        hasAnimation = true
        
//        detectorFilter = PGLDetector(ciFilter:  PGLFaceCIFilter() )
        // wrapper will use the detector of the filter we are wrapping.
        // set in PGLSelectParmController #tapAction for a pointUI parm

    }




//    func setWrapper(detector: PGLDetector){
//        // 12/21/19... not entirely clear why
//        // there are two vars for detectors.
//        // set up both.
//        self.detectors.append(detector)
//        detectorFilter = detector
//    }

    func releaseWrapper() {
        // reverses setWrapper
        stopWrapperAnimation()
        detectorFilter?.releaseContext()
        detectors = [PGLDetection]()
        detectorFilter = nil
//        internalFilter = nil
    }

    func stopWrapperAnimation() {
           // runs on all animation attributes where self is a wrapper filter
           for anAttribute in animationAttributes {
//               anAttribute.attributeValueDelta  = nil
            anAttribute.setTimerDt(lengthSeconds: 0.0 )

           }
           animationAttributes = [PGLFilterAttribute]()
           hasAnimation = false
       }

    func increment() {
        
        // get the new input from the internal filter
        // pass to the detector
        // set up images for dissolve source and target
        NSLog("PGLDissolveWrapperFilter #increment")
        // needs work .. increment is an attribute message
        // goes to the imageList inputCollections..
        // currently these are being set on every draw..
        // detectors need a way to persist ... maybe
        // if the number and rect of the features match then
        // it must be the same input so just increment to the next feature image
        
        detectorFilter?.increment()

        
    }
    


    override func outputImageBasic() -> CIImage? {
//            NSLog("PGLDissolveWrapperFilter #outputImageBasic")
            // internal filter
            // assumes that inputImage set with prior stack filter outputs

            addStepTime()  // if animation then move time forward


            let thisOutput = localFilter.outputImage

            return thisOutput
    }

    func updateInputs(detector: PGLDetection) {
        let theFaceImages = detector.featureImagePair()
        self.setImageValue(newValue: theFaceImages.inputFeature, keyName: kCIInputImageKey)
        self.setImageValue(newValue: theFaceImages.targetFeature, keyName:kCIInputTargetImageKey)
    }

    func imageInputAttribute() -> PGLFilterAttributeImage?
    {
            return attribute(nameKey: kCIInputImageKey) as? PGLFilterAttributeImage
    }
    
    func imageTargetImageAttribute() -> PGLFilterAttributeImage?
    {
        return attribute(nameKey: kCIInputTargetImageKey) as? PGLFilterAttributeImage
    }
    


     override func addStepTime() {
            // PGLDissolveWrapper
        // the inputs are updated on every frame
        // No imageList to increment
        // just advance the dissolve time
            // stepTime for transition Filters range is 0 - 1.0
            // does not go below zero

    //       NSLog("PGLTransitionFilter #addStepTime ")

            if (stepTime > 1.0)   {
                stepTime = 1.0 // make it go down
                dt = dt * -1 // past end so toggle
                // this has animation
                // get the input collection
                // update the input.. now showing target
               if let newTargetInput = detectorFilter?.nextImage() {
                     self.setImageValue(newValue: newTargetInput, keyName: kCIInputImageKey)
                }
            }
            else if (stepTime < 0.0) {
                stepTime = 0.0 // make it go up
                dt = dt * -1 // past end so toggle
                // update the targetImage now showing the input
                if let newInput = detectorFilter?.nextImage() {
                     self.setImageValue(newValue: newInput, keyName: kCIInputTargetImageKey )
                }
            }
            // go back and forth between 0 and 1.0
            // toggle dt either neg or positive
            stepTime += dt
            let inputTime = simd_smoothstep(0, 1, stepTime)

            // dissolve specific localFilter
            localFilter.setValue(inputTime, forKey: kCIInputTimeKey)
            //        NSLog("PGLTransitionFilter stepTime now = \(inputTime)" )
        }

}

