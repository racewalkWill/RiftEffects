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
class PGLSequenceStack: PGLFilterStack {

        /// use the appstack to stop filter incrments if showFilterImage = true
    var appStack: PGLAppStack!

    override init(){
        super.init()
        setStartupDefault()
       guard let myAppDelegate =  UIApplication.shared.delegate as? AppDelegate
           else {
           Logger(subsystem: LogSubsystem, category: LogCategory).fault ("PGLStackController viewDidLoad fatalError(AppDelegate not loaded")
           return
       }

       appStack = myAppDelegate.appStack
    }
    //MARK: single output
    override func stackOutputImage(_ showCurrentFilterImage: Bool) -> CIImage {

        // MARK: CHANGE
        // should get the input image..
        // See PGLAppStack #addChildStackTo(parm:...)
        // this stack has the var .parentAttribute set
        // the parentAttribute refers to this as parm.inputStack

        // in 'Single' filter display PGLSequenceStack is the viewer stack
        // therefore must get the input image from the parent
        // compared to the 'All' display where the SequencedFilters is creating the image
        // with the similar PGLSequencedFilters.#outputImageBasic()
         let myInputAttribute = parentAttribute as? PGLFilterAttributeImage
         let myImage =  myInputAttribute?.getCurrentImage()
            // may answer nil.. which is ok..

        return imageUpdate(myImage, showCurrentFilterImage)

    }

    override func outputImage() -> CIImage? {
        return currentFilter().outputImage()
    }

    func nextFilter()  -> PGLSourceFilter? {
        var nextFilter = 0
        if !lastFilterIsActive() {
            // not on last.. move ahead
            nextFilter = activeFilterIndex + 1
        }

        return filterAt(tabIndex: nextFilter)
    }

    func setInputToStack()  {
        let myInputAttribute = parentAttribute as? PGLFilterAttributeImage
        let myImage =  myInputAttribute?.getCurrentImage()
       currentFilter().setInput(image: myImage, source: "parent")
       nextFilter()?.setInput(image: myImage, source: "parent")
    }
    
    override   func imageUpdate(_ inputImage: CIImage?, _ showCurrentFilterImage: Bool) -> CIImage {
            // send the inputImage to the activeFilters


        var thisImage = inputImage
        var filter: PGLSourceFilter
        var imagePosition: Int
//       NSLog("PGLFilterStack #imageUpdate inputImage = \(String(describing: inputImage))")

        if isEmptyStack() { return CIImage.empty() }

        imagePosition = activeFilterIndex

        filter = activeFilters[imagePosition]

            if thisImage == nil {
                    // don't render from filter with no input.
                return CIImage.empty()
            }
            if thisImage != nil {
                if thisImage!.extent.isInfinite {
                        // issue CIColorDodgeBlendMode -> CIZoomBlur -> CIToneCurve
                        // -> CIColorInvert -> CIHexagonalPixellate -> CICircleSplashDistortion)
                        // clamp and crop if infinite extent
                        //                  NSLog("PGLFilterStack imageUpdate thisImage has input of infinite extent")

                    thisImage = thisImage!.cropForInfiniteExtent()
                        //                    if doPrintCropClamp {   NSLog("PGLFilterStack imageUpdate clamped and cropped to  \(String(describing: thisImage?.extent))") }
                }
                filter.setInput(image: thisImage, source: nil)
                if filter.imageInputIsEmpty() {
                    if let changedAttribute = filter.getInputImageAttribute() {
                        changedAttribute.setImageParmState(newState: ImageParm.inputPriorFilter)
                    }
                }
                if let newOutputImage = clampCropForNegativeX(input: filter.outputImage()) {

                    if newOutputImage.extent.isInfinite {
                            //                    NSLog("PGLFilterStack imageUpdate newOutputImage has input of infinite extent")
                    }
                    thisImage = filter.scaleOutput(ciOutput: newOutputImage, stackCropRect: cropRect)
                        // most filters do not implement scaleOutput
                        // crop in the PGLRectangleFilter scales the crop to fill the extent
                }
            }
        return thisImage ?? CIImage.empty()
    }

    func nextFilterImage(_ inputImage: CIImage?) -> CIImage {
            // get the input image, set input of the next filter in the sequence
        //  return the output of next filter
        var thisImage = inputImage
        var filter: PGLSourceFilter
        var imagePosition: Int
//       NSLog("PGLFilterStack #imageUpdate inputImage = \(String(describing: inputImage))")

        if isEmptyStack() { return CIImage.empty() }

        imagePosition = activeFilterIndex

        filter = activeFilters[imagePosition]

            if thisImage == nil {
                    // don't render from filter with no input.
                return CIImage.empty()
            }
            if thisImage != nil {
                if thisImage!.extent.isInfinite {
                        // issue CIColorDodgeBlendMode -> CIZoomBlur -> CIToneCurve
                        // -> CIColorInvert -> CIHexagonalPixellate -> CICircleSplashDistortion)
                        // clamp and crop if infinite extent
                        //                  NSLog("PGLFilterStack imageUpdate thisImage has input of infinite extent")

                    thisImage = thisImage!.cropForInfiniteExtent()
                        //                    if doPrintCropClamp {   NSLog("PGLFilterStack imageUpdate clamped and cropped to  \(String(describing: thisImage?.extent))") }
                }
                filter.setInput(image: thisImage, source: nil)
                if filter.imageInputIsEmpty() {
                    if let changedAttribute = filter.getInputImageAttribute() {
                        changedAttribute.setImageParmState(newState: ImageParm.inputPriorFilter)
                    }
                }
                if let newOutputImage = clampCropForNegativeX(input: filter.outputImage()) {

                    if newOutputImage.extent.isInfinite {
                            //                    NSLog("PGLFilterStack imageUpdate newOutputImage has input of infinite extent")
                    }
                    thisImage = filter.scaleOutput(ciOutput: newOutputImage, stackCropRect: cropRect)
                        // most filters do not implement scaleOutput
                        // crop in the PGLRectangleFilter scales the crop to fill the extent
                }
            }
        return thisImage ?? CIImage.empty()
    }
    func increment() {

        if appStack.showFilterImage {
            // don't increment.. just stay
            return
        }
        // always circle around .. back to first
        if activeFilterIndex >= (activeFilters.count - 1) {
            // zero based array
            // back to the beginning
            activeFilterIndex = 0
        } else {
            moveActiveAhead() }
    }

}
