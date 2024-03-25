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
import Combine

enum OffScreen {
    case input
    case target
}

let kCIinputSingleFilterDisplayTime = "inputSingleFilterDisplayTime"
let kCIinputDissolveTime = "inputDissolveTime"

class PGLSequencedFilters: PGLSourceFilter {

    private var dissolve: PGLSequenceDissolve!
    var sequenceStack: PGLSequenceStack!
    var dissolveDT: Double = (1/60) 
//    { didSet {
//            // should be 2 sec dissolve
//        Logger(subsystem: LogSubsystem, category: LogCategory).info("\( String(describing: self) + " dissolveDT set to \(dissolveDT)" )")
//    }}

    var frameCount = 0
    var pauseForFramesCount = 180 { didSet {
            // initial 3 secs * 60 fps
        Logger(subsystem: LogSubsystem, category: LogCategory).info("\( String(describing: self) + " pauseForFramesCount set to \(pauseForFramesCount)" )")
    }}
    var publishers = [Cancellable]()
    var cancellable: Cancellable?


    required init?(filter: String, position: PGLFilterCategoryIndex) {
        super.init(filter: filter, position: position)
        let myImageAttribute = getInputImageAttribute()!
        let myBackgroundAttribute = attribute(nameKey: kCIInputBackgroundImageKey) as? PGLFilterAttributeImage
        let myMaskAttribute = attribute(nameKey: kCIInputMaskImageKey ) as? PGLFilterAttributeImage
        sequenceStack = PGLSequenceStack(imageAtt: myImageAttribute, backgroundAtt: myBackgroundAttribute, maskAtt: myMaskAttribute)
        setDissolveWrapper(onStack: sequenceStack)

        let myCenter =  NotificationCenter.default

        cancellable = myCenter.publisher(for:  PGLStartSequenceDissolve)
            .sink() { [weak self]
            myUpdate in
            guard let self = self else { return } // a released object sometimes receives the notification
                          // the guard is based upon the apple sample app 'Conference-Diffable'

            Logger(subsystem: LogSubsystem, category: LogNavigation).info( "PGLSequencedFilters  notificationBlock PGLStartSequenceDissolve")
            if let userDataDict = myUpdate.userInfo {
                if let theDissolveStack = userDataDict["dissolveStack"] as? PGLSequenceStack {
                    if (theDissolveStack === sequenceStack) && ( frameCount < pauseForFramesCount ) {
                            // dissolve is not currently running
                        frameCount = pauseForFramesCount + 1
                            // triggers start to the next dissolve
                            // in the #addFilterStepTime()
                    }
                }
            }
        }
        publishers.append(cancellable!)
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

    //MARK: CoreData Read
    override func setUpStack(onParentImageParm: PGLFilterAttributeImage) -> PGLFilterStack {
        //MARK: needs review
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

        // restructure
        // when not dissolving then output only one filter
        // during the dissolve then output both..
        // inputs have been copied in the #setSequenceFilterInputs
        // do not need to reset them for each frame.

        if sequenceStack.isEmptyStack() {
            return CIImage.empty()
        }
        if sequenceStack.isSingleFilterStack() {
            sequenceStack.setSequenceFilterInputs()
            addFilterStepTime()
                // advances the target filter

            return dissolve.singleFilterOutput()
        }
        addFilterStepTime()
       let dissolvedImage =  dissolve.dissolveOutput()
        return dissolvedImage

    }

    func incrementImageLists() {
        // send increment to the image parm lists
        for anImageParm in imageParms() ?? [PGLFilterAttributeImage]() {
            _ = anImageParm.inputCollection?.increment()
        }
    }
    func filterSequence() -> PGLSequenceStack? {
        
        return sequenceStack
    }

    ///  adds stepTime for the vary..
    ///   does not use the transitionFilterStepTime var in the PGLTransitionFilter
    override func addFilterStepTime() {
        // in this overridden method
        // just advance the SequenceStack on the hidden dissolve parm
        // see also  PGLSequenceStack#setInputToStack() for alternation of target/input
        

        guard let theSequenceStack = filterSequence()
            else { return }
        if  theSequenceStack.isEmptyStack()
                // removed the (theSequenceStack.isSingleFilterStack() ||
                // the parms need to increment even for a single filter
            {
            return
        }
        frameCount += 1
            //incremented on every outputImage draw

//        if frameCount == pauseForFramesCount {
//            Logger(subsystem: LogSubsystem, category: LogCategory).info(" PGLSequencedFilters #addFilterStepTime STARTS dissolve " )
//        }

        if frameCount >= pauseForFramesCount {

            // dissolve is now running
            stepTime += dissolveDT
                //incremented on every outputImage draw
            let inputTime = simd_smoothstep(0, 1, stepTime)
            dissolve.setDissolveTime(inputTime: inputTime)

            if (stepTime >= 1.0)   {
                stepTime = 1.0 // bring it back in range

                    // when current filter is odd
                    // and dissolve = one then the currentTarget is nextFilter
                theSequenceStack.increment(hidden: .input )
                dissolveDT = dissolveDT * -1 // past end so toggle
                frameCount = 0
                    // stops the dissolve timer
//                    Logger(subsystem: LogSubsystem, category: LogCategory).info(" PGLSequencedFilters #addFilterStepTime STOPS dissolve")

            }
            else if (stepTime <= 0.0) {
                stepTime = 0.0 // bring it back in range
                theSequenceStack.increment(hidden: .target )
                dissolveDT = dissolveDT * -1 // past end so toggle
                frameCount = 0
                    // stops the dissolve timer
//                        Logger(subsystem: LogSubsystem, category: LogCategory).info(" PGLSequencedFilters #addFilterStepTime STOPS dissolve")

                // filters get their own increment during outputBasic

                // see also  PGLSequenceStack#setInputToStack()
            }
        }






    }

//MARK: set Fade Time, Display Time
    override func setTimerDt(lengthSeconds: Float) {

        // pass the timerDt to the real dissolve
        dissolveDT =  Double(lengthSeconds/60)
//        Logger(subsystem: LogSubsystem, category: LogCategory).info("PGLSequencedFilters setTimerDt \(self.dissolveDT) ")
        // dissolveDT is the time to add for each frame
        // bigger makes it go slower
        setNumberValue(newValue: lengthSeconds as NSNumber, keyName: kCIinputDissolveTime)


    }

    override func setNumberValue(newValue: NSNumber, keyName: String) {
        if keyName == kCIinputSingleFilterDisplayTime  {
            pauseForFramesCount = Int(truncating: newValue)
            Logger(subsystem: LogSubsystem, category: LogCategory).info("PGLSequencedFilters setNumberValue pauseForFramesCount = \(self.pauseForFramesCount) ")
            super.setNumberValue(newValue: newValue, keyName: keyName)
        }
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
