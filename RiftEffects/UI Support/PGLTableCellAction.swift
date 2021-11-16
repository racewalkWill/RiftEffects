//
//  PGLTableCellAction.swift
//  Glance
//
//  Created by Will on 4/20/19.
//  Copyright © 2019 Will Loew-Blosser. All rights reserved.
//

import Foundation
import UIKit

enum CellActionType {
    case segue
    case command
    case addCell
    case cancel
    case addANDcommand
    case unknown
}
class PGLTableCellAction {
    // holds the name of the action displayed in the swipe
    // and cell to add to the table as required (Vary adds a timer control cell)
    // and/or messages to the attribute that execute the command


    let swipeLabel: String
    let newSubUIAttribute: PGLFilterAttribute?
    let performAction: Bool
        // an attribute implements performCellAction
    let actionTargetAttribute: PGLFilterAttribute
    var performAction2 = false // some classes have two swipe cells to trigger different actions on same attribute
    var performDissolveWrapper = false  // adds a dissolve from face to face to a point parm

    init(action: String, newAttribute: PGLFilterAttribute?, canPerformAction: Bool, targetAttribute: PGLFilterAttribute) {
        swipeLabel = action
        newSubUIAttribute = newAttribute
        performAction = canPerformAction
        actionTargetAttribute = targetAttribute

    }

    func cellAction() -> CellActionType {
        if isCancelCell() && performAction2 { return .command}
            // PGLAttributeRectangle cancel is a command
        if isCancelCell() {return .cancel}
        if isSegue() {return .segue}
        if isCommand() && isAddCell() { return .addANDcommand}
        if isCommand() {return .command}
        if isAddCell() { return .addCell}


        return .unknown
    }
    func isSegue() -> Bool {
        return (newSubUIAttribute  == nil) && (!performAction)
    }

    func isCommand() -> Bool {
         // may both send message command AND add a new cell
        return performAction
    }

    func isAddCell() -> Bool {
        // has new attribute to  add
        if actionTargetAttribute.hasAnimation() {
            // don't add cells to animated parm
            return false
        }

        return newSubUIAttribute != nil
    }

    func isCancelCell() -> Bool {
        return swipeLabel == "Cancel"
    }


}

