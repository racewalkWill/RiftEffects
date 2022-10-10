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

    override func addChildSequenceStack(appStack: PGLAppStack) {
        // actually do the add
        if let myImageParm = getInputImageAttribute() {
            appStack.addChildSequenceStackTo(parm: myImageParm)
        }
    }

    override  func outputImageBasic() -> CIImage? {
        // assign input to the child sequence stack
        // return the outpput of the child sequence stack

        // instead of returning empty on errors.. return the output same as
        // images??
        addFilterStepTime()
        guard let myInputAttribute = getInputImageAttribute()
            else { return CIImage.empty()}

        guard let myImage = myInputAttribute.getCurrentImage()
            else { return CIImage.empty()}

        guard let mySequenceStack = filterSequence()
            else { return  myImage}
        
       return mySequenceStack.imageUpdate(myImage, true)
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
