//
//  PGLSequencedFilters.swift
//  RiftEffects
//
//  Created by Will on 10/1/22.
//  Copyright © 2022 Will Loew-Blosser. All rights reserved.
//

import Foundation
import CoreImage
import simd
import UIKit
import os

class PGLSequencedFilters: PGLSourceFilter {

    private var dissolve: PGLSequenceDissolve!

    fileprivate func setDissolveWrapper() {
        // install a detector input to the tappedAttribute.
        // needs input image of this filter and a detector
        // detector holds the parm to set point values
        // this filter should also keep the detectors for forwarding of increment and dt time changes
        //                let detector = PGLDetector(ciFilter: PGLFaceCIFilter())
        // create the wrapper filter
//        "PGLSelectParmController #setDissolveWrapper start"
       
        let wrapperDesc = PGLFilterDescriptor("CIDissolveTransition", PGLSequenceDissolve.self)!
        let wrapperFilter = wrapperDesc.pglSourceFilter() as! PGLSequenceDissolve

        wrapperFilter.sequenceFilter = self
        wrapperFilter.sequenceStack = filterSequence()
        dissolve = wrapperFilter
        
        self.hasAnimation = false  //  current filter is NOT animating. The wrapper is

    }

    override func addChildSequenceStack(appStack: PGLAppStack) {
        // actually do the add
        if let myImageParm = getInputImageAttribute() {
            appStack.addChildSequenceStackTo(parm: myImageParm)
        }
        setDissolveWrapper()
    }

    override  func outputImageBasic() -> CIImage? {
        // assign input to the child sequence stack
        // return the outpput of the child sequence stack

        // instead of returning empty on errors.. return the output same as
        // images??
        addFilterStepTime()
       let dissolvedImage =  dissolve.dissolveOutput()
        return dissolvedImage

    }

    func filterSequence() -> PGLSequenceStack? {
        return getInputImageAttribute()?.inputStack as? PGLSequenceStack
    }

    override func addFilterStepTime() {
        // in this overridden method
        // just advance the StackSequence current index
        // no need to get attributes
        var doIncrement = false

        if (stepTime > 1.0)   {
            stepTime = 1.0 // bring it back in range
            doIncrement = true
            dt = dt * -1 // past end so toggle

        }
        else if (stepTime < 0.0) {
            stepTime = 0.0 // bring it back in range
            doIncrement = true
            dt = dt * -1 // past end so toggle

        }
        if doIncrement {
            filterSequence()?.increment()
                // advances to the next image in the input imageList
        }

        // go back and forth between 0 and 1.0
        // toggle dt either neg or positive
        stepTime += dt
        let inputTime = simd_smoothstep(0, 1, stepTime)
        dissolve.setDissolveTime(inputTime: inputTime)
        

    }

    override func setTimerDt(lengthSeconds: Float) {
            // Super class does not use this
            // timer is 0..1 range
            // dt should be the amount of change to add to the input time
            // to make the dissolve in lenghtSeconds total. This is also the incrment time
            // from one image to another.

            // set the dt (deltaTime) for use by addStepTime() on each frame

        let framesPerSec: Float = 60.0 // later read actual framerate from UI
        let varyTotalFrames = framesPerSec * lengthSeconds

        let attributeValueRange = 1.0 // transition range is 0..1
        if varyTotalFrames > 0.0 {
                // division by zero is nan
            dt = attributeValueRange / Double(varyTotalFrames)
        }
    }
}

extension PGLFilterAttributeImage {
    func getCurrentImage() -> CIImage? {
        // current image from the inputCollection
        // or empty ciImage
        if inputCollection == nil {
           // get the input held by the filter
            // it is being set from the stack on each render loop
            return aSourceFilter.inputImage()
        }
        return inputCollection!.getCurrentImage()
    }
}
