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


    func nextFilter()  -> PGLSourceFilter {
        var nextFilter = 0
        if (activeFilterIndex != (activeFilters.count - 1)) {
            // not on last.. move ahead
            nextFilter = activeFilterIndex + 1
        } // else back to zero for next
        NSLog("\( String(describing: self) + "-" + #function)" + " nextFilter = \(nextFilter)")
        return filterAt(tabIndex: nextFilter)
    }

    func setInputToStack()  {
        let myInputAttribute = parentAttribute as? PGLFilterAttributeImage
        let myImage =  myInputAttribute?.getCurrentImage()
       currentFilter().setInput(image: myImage, source: "parent")
       nextFilter().setInput(image: myImage, source: "parent")
    }

    func currentInputFilter() -> PGLSourceFilter {

        if isEvenFilter() {
            NSLog("\( String(describing: self) + "-" + #function)" + "isEVEN return  currentFilter")
            return currentFilter()
        } else
        {
            NSLog("\( String(describing: self) + "-" + #function)" + "isOdd return  nextFilter")
            return nextFilter()
        }
    }

    func currentTargetFilter() -> PGLSourceFilter {

        if isEvenFilter() {
            NSLog("\( String(describing: self) + "-" + #function)" + "isEVEN return  nextFilter")

            return nextFilter()
        } else
        {
            NSLog("\( String(describing: self) + "-" + #function)" + "isOdd return  currentFilter")
            return currentFilter()
        }
    }

    func increment() {
        NSLog("\( String(describing: self) + "-" + #function)" + " start activeFilterIndex = \(activeFilterIndex)")
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
        NSLog("\( String(describing: self) + "-" + #function)" + " end activeFilterIndex = \(activeFilterIndex)")

    }

    func isEvenFilter() -> Bool {
        // answer true if the activeFilterIndex is even
        // zero is considered even
        return activeFilterIndex.isEven()
    }

    func isOddFilter() -> Bool {
        return !isEvenFilter()
    }

}
