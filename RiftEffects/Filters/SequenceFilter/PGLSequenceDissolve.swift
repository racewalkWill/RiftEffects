//
//  PGLSequenceDissolve.swift
//  RiftEffects
//
//  Created by Will on 10/11/22.
//  Copyright © 2022 Will Loew-Blosser. All rights reserved.
//

import Foundation
import UIKit

import CoreImage
import simd
import os

/// internal dissolve of the PGLSequenceFilter
/// dissolves output of the sequence stack from current filter to next filter
/// provides currentFilter output after dissolve completes
/// filter output image not cached.. filter output may change on each render frame

class PGLSequenceDissolve: PGLTransitionFilter {


    unowned var sequenceFilter: PGLSequencedFilters!
    var sequenceStack: PGLSequenceStack!

    override class func displayName() -> String? {
        return "Sequence Dissolve"
    }

    required init?(filter: String, position: PGLFilterCategoryIndex) {
        super.init(filter: filter, position: position)
        hasAnimation = true
        postTransitionFilterAdd()


    }

    deinit {
//        Logger(subsystem: LogSubsystem, category: LogMemoryRelease).info("\( String(describing: self) + " - deinit" )")
        postTransitionFilterRemove()
        // as an internal filter the stack does not know about
        // this dissolve so this filter has to remove the needsRedraw flag for transition
    }

        /// the same image inputs are passed to both filters
    func dissolveOutput() -> CIImage? {
        // dissolve without a pause
        // get currentFilter and nextFilter outputs
        // time has been updated by the caller already

        if sequenceStack.isEmptyStack() {
            return CIImage.empty()
        }

        if let currentOutputImage = sequenceStack.inputFilter?.outputImage() {
            self.setImageValue(newValue: currentOutputImage, keyName: kCIInputImageKey)

        } else {
            self.setImageValue(newValue: CIImage.empty(), keyName: kCIInputImageKey)

        }

        
        if let  nextImage = sequenceStack.targetFilter?.outputImage() {
            self.setImageValue(newValue: nextImage, keyName: kCIInputTargetImageKey)

        }  else {
            self.setImageValue(newValue: CIImage.empty(), keyName: kCIInputTargetImageKey)

        }

        return localFilter.outputImage


    }

        ///   skip the dissolve - output just one filter
    func singleFilterOutput() -> CIImage? {
        // set the input to the first filter
        // assumes the sequenceStack.setSequenceFilterInputs has
        // set the image inputs to this singleFilter
        return sequenceStack.inputFilter?.outputImageBasic() ?? CIImage.empty()

    }

    func setDissolveTime(inputTime: Double) {
        localFilter.setValue(inputTime, forKey: kCIInputTimeKey)
    }

    func postTransitionFilterAdd() {
        let updateNotification = Notification(name:PGLTransitionFilterExists)
        NotificationCenter.default.post(name: updateNotification.name, object: nil, userInfo: ["transitionFilterAdd" : +1 ])
    }

    func postTransitionFilterRemove() {
        let updateNotification = Notification(name:PGLTransitionFilterExists)
        NotificationCenter.default.post(name: updateNotification.name, object: nil, userInfo: ["transitionFilterAdd" : -1 ])
    }



}
