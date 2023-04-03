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

enum OffScreen {
    case input
    case target
}

class PGLSequencedFilters: PGLSourceFilter {

    private var dissolve: PGLSequenceDissolve!
    var dissolveDT: Double = (1/120)  // should be 2 sec dissolve
    var pauseForFramesCount = 300 // initial 5 secs * 60 fps
    var frameCount = 0
    var sequenceStack: PGLSequenceStack!

    required init?(filter: String, position: PGLFilterCategoryIndex) {
        super.init(filter: filter, position: position)
        let myImageAttribute = getInputImageAttribute()!
        let myBackgroundAttribute = attribute(nameKey: kCIInputBackgroundImageKey) as? PGLFilterAttributeImage
        let myMaskAttribute = attribute(nameKey: kCIInputMaskImageKey ) as? PGLFilterAttributeImage
        sequenceStack = PGLSequenceStack(imageAtt: myImageAttribute, backgroundAtt: myBackgroundAttribute, maskAtt: myMaskAttribute)
        setDissolveWrapper(onStack: sequenceStack)
//        sequenceStack.setStartupDefault()
        }

    fileprivate func setDissolveWrapper(onStack: PGLSequenceStack) {

       
        let wrapperDesc = PGLFilterDescriptor("CIDissolveTransition", PGLSequenceDissolve.self)!
        let wrapperFilter = wrapperDesc.pglSourceFilter() as! PGLSequenceDissolve

        wrapperFilter.sequenceFilter = self
        wrapperFilter.sequenceStack = onStack
        dissolve = wrapperFilter
        
        self.hasAnimation = false  //  current filter is NOT animating. The wrapper is

    }

    override func addChildSequenceStack(appStack: PGLAppStack) {
        // not sure how the appStack needs to
        // handle this childStack..
        // needs to reimplement the childStack navigation
        // to actually point to the sequenceStack in the sequenceFilter.

        if let theChildParm = attribute(nameKey: "inputSequence") {
            _ =  appStack.addChildSequenceStackTo(aSequence: sequenceStack, parm: theChildParm)
        }
    }

    override func setUpStack(onParentImageParm: PGLFilterAttributeImage) -> PGLFilterStack {
        // super class answers the PGLFilterStack
        // sequencedFilters need a special stack PGLSequenceStack
        // connect the ciFilter into the sequenceStack
        // similar to PGLAppStack UI setup in addChildSequenceStackTo(parm: PGLFilterAttribute)
        
//       let newSequenceStack =  PGLSequenceStack()
//        if let ciFilterSequence = onParentImageParm.myFilter as? PGLCISequenced {
//            ciFilterSequence.myFilterSequence = newSequenceStack
//        }
//        newSequenceStack.stackType = "input"
//        newSequenceStack.parentAttribute = onParentImageParm
//
//        onParentImageParm.setImageParmState(newState: ImageParm.inputChildStack)
//        setDissolveWrapper(onStack: newSequenceStack)
//        return newSequenceStack
        /// var sequenceStack is setup in the init
        return sequenceStack
    }

    override func imageInputIsEmpty() -> Bool {
        // only one of the image inputs is required for sequencedFilters
        // do not test the optional background or mask image for inputs

        if let inputAttribute = attribute(nameKey: kCIInputImageKey )
        {
            if  inputAttribute.inputParmType() == ImageParm.missingInput
                    {
                return true }
        }

        return false
    }

    override  func outputImageBasic() -> CIImage? {
        // assign input to the child sequence stack
        // return the outpput of the child sequence stack

        // instead of returning empty on errors.. return the output same as
        // images??
//        addFilterStepTime()
       let dissolvedImage =  dissolve.dissolveOutput()
        return dissolvedImage

    }

    func incrementImageLists() {
        // send increment to the image parm lists
        for anImageParm in imageParms() ?? [PGLFilterAttributeImage]() {
            anImageParm.inputCollection?.increment()
        }
    }
    func filterSequence() -> PGLSequenceStack? {
        
        return sequenceStack
    }

    override func addFilterStepTime() {
        // in this overridden method
        // just advance the SequenceStack on the hidden dissolve parm
        // see also  PGLSequenceStack#setInputToStack() for alternation of target/input

        frameCount += 1
        if frameCount < pauseForFramesCount {
            return
        }
        guard let theSequenceStack = filterSequence()
            else { return }
        if (stepTime > 1.0)   {
            stepTime = 1.0 // bring it back in range

                // when current filter is odd
                // and dissolve = one then the currentTarget is nextFilter
            theSequenceStack.increment(hidden: .input )
            dissolveDT = dissolveDT * -1 // past end so toggle
            frameCount = 0
            incrementImageLists()

        }
        else if (stepTime < 0.0) {
            stepTime = 0.0 // bring it back in range
            theSequenceStack.increment(hidden: .target )
            dissolveDT = dissolveDT * -1 // past end so toggle
            frameCount = 0
//            incrementImageLists()
            // see also  PGLSequenceStack#setInputToStack()
        }

        // go back and forth between 0 and 1.0
        // toggle dt either neg or positive
        stepTime += dissolveDT
        let inputTime = simd_smoothstep(0, 1, stepTime)
        dissolve.setDissolveTime(inputTime: inputTime)



    }

    override func setTimerDt(lengthSeconds: Float) {
            // Super class does not use this
            // timer is 0..1 range
            // dt should be the amount of change to add to the input time
            // to make the dissolve in lenghtSeconds total. This is also the incrment time
            // from one image to another.

            // set the pauseForFramesCount (deltaTime)
            // min lengthSeconds = 0.001 or no pause just the dissolve
            // max lengthSeconds = 10 seconds
//        NSLog("PGLSequencedFilters #setTimerDt lengthSeconds = \(lengthSeconds)")
        let framesPerSec = 60 // later read actual framerate from UI
        pauseForFramesCount = framesPerSec * Int(lengthSeconds)

    }
}

extension PGLSourceFilter {
    func getBackgroundImage() -> CIImage? {
        if let backgroundAttribute = attributes.first(where: { $0.isBackgroundImageInput() }){
            return backgroundAttribute.getCurrentImage()
            }
        else {
            return nil
            }
        }

    func getMaskImage() -> CIImage? {
        if let maskAttribute = attributes.first(where: { $0.isMaskImageInput() }) {
            return maskAttribute.getCurrentImage()
            }
        else {
            return nil
            }
        }
}

extension PGLFilterAttribute{
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
