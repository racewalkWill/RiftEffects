//
//  PGLSequenceStack.swift
//  RiftEffects
//
//  Created by Will on 9/27/22.
//  Copyright © 2022 Will Loew-Blosser. All rights reserved.
//

import Foundation
import CoreImage
import UIKit
import Photos
import PhotosUI
import os

/// PGLFilterSequence stack shows only one filter at a time using stack input and outputs just the single current filter output
///  for SequencedFilters of any number of filters
///    always a child stack
///    Must always have at least one filter, defaults to image filter
///
let PGLStartSequenceDissolve = NSNotification.Name(rawValue: "PGLStartSequenceDissolve")

class PGLSequenceStack: PGLFilterStack {

        /// use the appstack to stop filter incrments if showFilterImage = true
    var appStack: PGLAppStack!
    var inputFilter: PGLSourceFilter?
    var targetFilter: PGLSourceFilter?
        // input is starting filter in the dissolve
        // so target filter is the hidden one
    var offScreenFilter = OffScreen.target

    /// imageParms passed to each filter in the sequence
    var imageAttribute: PGLFilterAttributeImage
    var backgroundAttribute: PGLFilterAttributeImage?
    var maskAttribute: PGLFilterAttributeImage?




    required init(imageAtt: PGLFilterAttributeImage, backgroundAtt: PGLFilterAttributeImage?, maskAtt: PGLFilterAttributeImage?) {

        imageAttribute = imageAtt
        backgroundAttribute = backgroundAtt
        maskAttribute = maskAtt

        guard let myAppDelegate =  UIApplication.shared.delegate as? AppDelegate
            else {
            Logger(subsystem: LogSubsystem, category: LogCategory).fault ("PGLStackController viewDidLoad fatalError(AppDelegate not loaded")
            super.init()
            return
        }
        appStack = myAppDelegate.appStack

        super.init()


     }

    //MARK: single output

//    func nextFilter()  -> PGLSourceFilter {
//        // assumes that activeFilterIndex is on the currentFilter
//        var nextFilter = 0
//        if (activeFilterIndex != (activeFilters.count - 1)) {
//            // not on last.. move ahead
//            nextFilter = activeFilterIndex + 1
//        } // else back to zero for next
////        NSLog("\( String(describing: self) + "-" + #function)" + " nextFilter = \(nextFilter)")
//        return filterAt(tabIndex: nextFilter)
//    }

    func setSequenceFilterInputs()  {

        // see also PGLSequenceFilter#addFilterStepTime() which alternates the increment of the image

        // fill in values from the parent background & mask attibutes

    
        if let inputImage = imageAttribute.getCurrentImage() {
            inputFilter?.setInput(image: inputImage, source: nil)
            targetFilter?.setInput(image: inputImage, source: nil)
        }
        if  let inputBackgroundImage = backgroundAttribute?.getCurrentImage() {
                inputFilter?.setBackgroundInput(image: inputBackgroundImage)
               targetFilter?.setBackgroundInput(image: inputBackgroundImage)
        }

        if  let inputMaskImage = maskAttribute?.getCurrentImage() {
                inputFilter?.setMaskInput(image: inputMaskImage)
                targetFilter?.setMaskInput(image: inputMaskImage)
        }

    }


        // only increment to the next filter while it is off screen
    func increment(hidden: OffScreen) {
        // where hidden is dissolve .input or .target parm
        // only change the hidden parm

//        NSLog("\( String(describing: self) + "-" + #function)" + " start activeFilterIndex = \(activeFilterIndex)")
        if appStack.showFilterImage {
            // don't increment.. just stay
            return
        }
        if isEmptyStack() || isSingleFilterStack() {
            return
        }
        if activeFilterIndex >= (activeFilters.count - 1) {
            // zero based array
            // back to the beginning
            activeFilterIndex = 0
        } else {
            moveActiveAhead() }
        Logger(subsystem: LogSubsystem, category: LogCategory).info( " increment(hidden: activeFilterIndex moved to \(self.activeFilterIndex)")
        // the activeFilterIndex is now the next filter to use
        // assign the currentFilter to the var input or target that is offscreen

        switch hidden {
            case .input:
                Logger(subsystem: LogSubsystem, category: LogCategory).info(" increment(hidden: input")
                inputFilter = currentFilter()
            case .target:
                Logger(subsystem: LogSubsystem, category: LogCategory).info(" increment(hidden: target")
                targetFilter = currentFilter()
        }
        offScreenFilter = hidden

    }
        ///  just puts it in the activeFilters. Does not adjust inputs
    override func appendFilter(_ newFilter: PGLSourceFilter) {

        append(newFilter)
            // only adds to the activeFilters collection
            // do not use the super.appendFilter - it tries to adjust inputs

        let filterCount = activeFilters.count
        var triggerFilterDissolve = false
        switch filterCount {
            case 1:
                inputFilter = newFilter
                targetFilter = newFilter
                // nothing to dissolve
                // triggerFilterDissolve stays false
            case 2:
                // set the offscreen var to new filter
                if offScreenFilter == .input {
                    inputFilter = newFilter
                } else {
                    targetFilter = newFilter
                }
                triggerFilterDissolve = true
            default:
                triggerFilterDissolve = true
        }
        if triggerFilterDissolve {
            let dissolveNotification = Notification(name:PGLStartSequenceDissolve, object: nil,
                userInfo: ["dissolveStack" : self ])
            NotificationCenter.default.post(dissolveNotification)
        }


    }

    override func replace(updatedFilter newFilter: PGLSourceFilter) {

        if isEmptyStack(){
            append(newFilter)
        }

        let oldFilter =  activeFilters[activeFilterIndex]
        activeFilters[activeFilterIndex] = newFilter

        // change input or target if needed
        if inputFilter === oldFilter {
            inputFilter = newFilter
        }
        if targetFilter === oldFilter {
            targetFilter = newFilter
        }

    }

   override func imageInputIsEmpty(atFilterIndex: Int) -> Bool {
        // empty implementation
        // the sequence stack filters get input from the
        // attributes of the sequenceFilter
        return false
    }


}
