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
class PGLSequenceStack: PGLFilterStack {

        /// use the appstack to stop filter incrments if showFilterImage = true
    var appStack: PGLAppStack!
    lazy var inputFilter: PGLSourceFilter = currentFilter()
    lazy var targetFilter: PGLSourceFilter = nextFilter()
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


    func nextFilter()  -> PGLSourceFilter {
        var nextFilter = 0
        if (activeFilterIndex != (activeFilters.count - 1)) {
            // not on last.. move ahead
            nextFilter = activeFilterIndex + 1
        } // else back to zero for next
//        NSLog("\( String(describing: self) + "-" + #function)" + " nextFilter = \(nextFilter)")
        return filterAt(tabIndex: nextFilter)
    }

    func setSequenceFilterInputs()  {
        // only increment the target while off screen
        // see also PGLSequenceFilter#addFilterStepTime() which alternates the increment of the
        // image


        // check if background, mask attributes are used by inputfilter and targetFilter
        // fill in values from the parent background & mask attibutes

    
        if let inputImage = imageAttribute.getCurrentImage() {
            inputFilter.setInput(image: inputImage, source: nil)
            targetFilter.setInput(image: inputImage, source: nil)
        }
        if  let inputBackgroundImage = backgroundAttribute?.getCurrentImage() {
                inputFilter.setBackgroundInput(image: inputBackgroundImage)
               targetFilter.setBackgroundInput(image: inputBackgroundImage)
        }

        if  let inputMaskImage = maskAttribute?.getCurrentImage() {
                inputFilter.setMaskInput(image: inputMaskImage)
                targetFilter.setMaskInput(image: inputMaskImage)
        }


    }

    func currentInputFilter() -> PGLSourceFilter {

       return inputFilter
    }

    func currentTargetFilter() -> PGLSourceFilter {

        return targetFilter
    }

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

        switch hidden {
            case .input:
                inputFilter = currentFilter()
            case .target:
                targetFilter = currentFilter()
        }
    }

   override func imageInputIsEmpty(atFilterIndex: Int) -> Bool {
        // empty implementation
        // the sequence stack filters get input from the
        // attributes of the sequenceFilter
        return false
    }

    override  func imageUpdate(_ inputImage: CIImage?, _ showCurrentFilterImage: Bool) -> CIImage {
            // send the inputImage to the activeFilters
//        super.imageUpdate(inputImage, showCurrentFilterImage)
        // NOT CLEAR WHY this is needed..
        // in loading some saved sequenceFilter stacks there is an
        // error in the PGLSourceFilter #outputImageBasic of
        // NSInvalidArgumentException', reason: '*** -[__NSPlaceholderArray initWithObjects:count:]: attempt to insert nil object from objects[0]'
        // however other saved sequenceFilter stacks are fine..
        // error in testing on stack named 'sequence4' 1/19/2023 8:28 am
        // all the coredata rows & relations appear correct.

        return inputImage ?? CIImage.empty()
    }
}
