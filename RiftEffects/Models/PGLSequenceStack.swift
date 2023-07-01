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
        // copies imageCollection to hidden filter
        // fill in values from the parent background & mask attibutes
        // inputs of each filter should be copied from the parent
        // and incremented when off screen
        // ONLY copy if parms are missing inputs
        var updateFilter: PGLSourceFilter
        switch offScreenFilter {
            case .input:
                guard (inputFilter != nil)
                    else { return }
                updateFilter = inputFilter!
            case .target:
                guard (targetFilter != nil)
                    else { return }
                updateFilter = targetFilter!
        }

        shareImageInputs(newFilter: updateFilter)


    }

    override func releaseVars() {
        // aSequence Stack can start a circular chain of releaseVars
        // since every filter points back to this one on the var inputStack.
        // then normally a stack tells all it's filters to releaseVars
        for aFilterInSequence in activeFilters {
            for anImageKey in aFilterInSequence.imageInputAttributeKeys {
                if let thisAttribute = aFilterInSequence.attribute(nameKey: anImageKey) {
                    if thisAttribute.inputStack === self {
                        thisAttribute.inputStack = nil
                    }
                }

            }
        }
        // now not circular so
        super .releaseVars()

    }
        /// share image, background, mask inputs to the new filter
    func shareImageInputs(newFilter: PGLSourceFilter) {
        shareImageList(newFilter, sequenceAttribute: imageAttribute)
        if backgroundAttribute != nil {
            shareImageList(newFilter, sequenceAttribute: backgroundAttribute!) }
        if maskAttribute != nil {
            shareImageList(newFilter, sequenceAttribute: maskAttribute!) }
    }
    ///  share the sequencedFilters input image lists to each target filter
    ///   an imageList will referenced by every filter in the sequence
    fileprivate func shareImageList(_ updateFilter: PGLSourceFilter,
                                  sequenceAttribute: PGLFilterAttributeImage ) {
        guard let imageKeyName = sequenceAttribute.attributeName
        else { return }
        if let updateImageParm = updateFilter.attribute(nameKey: imageKeyName ) as? PGLFilterAttributeImage

        {
            if updateImageParm.inputParmType() == ImageParm.missingInput {
                // if user has assigned other inputs to this .. don't overwrite

                if let sourceImages = sequenceAttribute.inputCollection {
                    updateImageParm.inputCollection = sourceImages
                    updateImageParm.setImageParmState(newState: imageAttribute.imageParmState)
                        // put the first image into the filter
                    updateFilter.setImageValue(newValue: (sourceImages.first()!), keyName: imageKeyName)
                }
            }
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
        if isEmptyStack()  {
            // || isSingleFilterStack() removed parms need to incrment images
            return
        }
        Logger(subsystem: LogSubsystem, category: LogCategory).info("PGLSequenceStack filter before increment \(String(describing: self.currentFilter().filterName))")
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
            // currentFilter is now hidden after activeFilterIndex has moved forward

            case .input:
                Logger(subsystem: LogSubsystem, category: LogCategory).info(" increment(hidden: input")
                inputFilter = currentFilter()
            case .target:
                Logger(subsystem: LogSubsystem, category: LogCategory).info(" increment(hidden: target")
                targetFilter = currentFilter()
        }

        offScreenFilter = hidden
        setSequenceFilterInputs()
        for anImageParm in currentFilter().imageParms() ?? [PGLFilterAttributeImage]() {
            if let nextImage = anImageParm.inputCollection?.increment() {
                currentFilter().setImageValue(newValue: nextImage, keyName: anImageParm.attributeName!)
            }
            }

    }
        ///  just puts it in the activeFilters. Does not adjust inputs
    override func appendFilter(_ newFilter: PGLSourceFilter) {

        append(newFilter)
            // only adds to the activeFilters collection
            // do not use the super.appendFilter(_ newFilter: ) - it tries to adjust inputs
        shareImageInputs(newFilter: newFilter)
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

    //MARK: outputImage

        /// uses the appStack setting for showCurrentFilterImage
    override func stackOutputImage(_ showCurrentFilterImage: Bool) -> CIImage {
        // ignore the showCurrentFilterImage that is passed
        // normally a childStack receives a false parm
        // from the PGLFilterAttribute #updateFromInputStack()

        return super.stackOutputImage(appStack.showFilterImage)

    }

}
