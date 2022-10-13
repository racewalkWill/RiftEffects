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


    var sequenceFilter: PGLSequencedFilters!
    var sequenceStack: PGLSequenceStack!

    override class func displayName() -> String? {
        return "Sequence Dissolve"
    }

    required init?(filter: String, position: PGLFilterCategoryIndex) {
        super.init(filter: filter, position: position)
        hasAnimation = true



    }

    func dissolveOutput() -> CIImage? {
        // dissolve without a pause
        // get currentFilter and nextFilter outputs
        // set into the ciFilter
        // time has been updated by the caller already

        // the current input to the parent sequence filter is
        // passed to both current and nextFilter
        sequenceStack.setInputToStack()
        let currentImage = sequenceStack.currentFilter().outputImage()
        localFilter.setValue(currentImage, forKey: kCIInputImageKey)
        
        if let nextImage = sequenceStack.nextFilter()?.outputImage() {
            localFilter.setValue(nextImage, forKey: kCIInputTargetImageKey) }

        return localFilter.outputImage


    }

    func setDissolveTime(inputTime: Double) {
        localFilter.setValue(inputTime, forKey: kCIInputTimeKey)
    }





}
