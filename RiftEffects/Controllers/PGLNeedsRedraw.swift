//
//  PGLNeedsRedraw.swift
//  RiftEffects
//
//  Created by Will on 1/15/23.
//  Copyright © 2023 Will Loew-Blosser. All rights reserved.
//

import Foundation
let PGLRedrawParmControllerOpenNotification = NSNotification.Name(rawValue: "PGLRedrawParmControllerOpenNotification")
let PGLRedrawFilterChange = NSNotification.Name(rawValue: "PGLRedrawFilterChange")

class PGLRedraw {
    // answers true if mtkView should draw
    var parmControllerIsOpen = false
    var transitionFilterExists = false
    var varyTimerIsRunning = false
    var filterChanged = false

    private var transitionFilterCount = 0
    private var varyTimerCount = 0

    let myCenter =  NotificationCenter.default
    let queue = OperationQueue.main

    init(){
        // register for changes
        let parmControllerObservor = myCenter.addObserver(forName: PGLRedrawParmControllerOpenNotification , object: nil, queue: queue ) {
            [weak self]
            myUpdate in
            if let userDataDict = myUpdate.userInfo {
                if let parmOpenFlag = userDataDict["parmControllerIsOpen"]  as? Bool {
                    self?.parmController(isOpen: parmOpenFlag)
                }
            }
        }

        let redrawFilterObservor = myCenter.addObserver(forName: PGLRedrawFilterChange , object: nil, queue: queue ) {
            [weak self]
            myUpdate in
            if let userDataDict = myUpdate.userInfo {
                if let changeFlag = userDataDict["redrawFilterChange"]  as? Bool {
                    self?.filter(changed: changeFlag)
                }
            }
        }


    } // end init
    
    func redrawNow() -> Bool {
        // answer true if any condition is true
        return parmControllerIsOpen || transitionFilterExists || varyTimerIsRunning || filterChanged
    }

    func parmController(isOpen: Bool) {
        parmControllerIsOpen = isOpen
    }

    private func transitionFilter(exists: Bool) {
        transitionFilterExists = exists
    }

    private func varyTimer(isRunning: Bool) {
        varyTimerIsRunning = isRunning
    }

    func filter(changed: Bool) {
        filterChanged = changed
    }

    func changeTransitionFilter(count: Int) {
        // count parm is +1 or -1
        // pass neg -1 to decrement
        transitionFilterCount += count
        transitionFilter(exists: transitionFilterCount > 0 )
    }

    func changeVaryTimerCount(count: Int) {
            // count parm is +1 or -1
            // pass neg -1 to decrement
        varyTimerCount += count
        varyTimer(isRunning: varyTimerCount > 0)
    }


}
