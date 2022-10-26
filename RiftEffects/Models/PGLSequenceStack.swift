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




    override init(){
        super.init()

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
//        NSLog("\( String(describing: self) + "-" + #function)" + " nextFilter = \(nextFilter)")
        return filterAt(tabIndex: nextFilter)
    }

    func setInputToStack()  {
        let myInputAttribute = parentAttribute as? PGLFilterAttributeImage
        let myImage =  myInputAttribute?.getCurrentImage()
        inputFilter.setInput(image: myImage, source: "parent")
        targetFilter.setInput(image: myImage, source: "parent")
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
        // parent SequencedFilters
        return false
    }

}
