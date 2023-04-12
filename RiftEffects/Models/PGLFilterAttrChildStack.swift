//
//  PGLFilterAttrChildStack.swift
//  RiftEffects
//
//  Created by Will on 4/1/23.
//  Copyright © 2023 Will Loew-Blosser. All rights reserved.
//

import Foundation
/// parm to represent a child SequenceStack in the UI
class PGLFilterAttrSequenceStack: PGLFilterAttributeImage {

    var sequenceChild: PGLSequenceStack?

    required init?(pglFilter: PGLSourceFilter, attributeDict: [String : Any], inputKey: String) {
        super.init(pglFilter: pglFilter, attributeDict: attributeDict, inputKey: inputKey)

        /// change the inputSequence attribute to instance of PGLFilterAttrChildStack

    }
    /// only set a child sequence stack
    override func set(_ value: Any ) {
        if let newStack = value as? PGLSequenceStack {
            sequenceChild = newStack
            imageParmState = ImageParm.inputChildStack
        }
    }

    /// answer  TableCellAction Hard coded to SequencedFilter
    override func cellAction() -> [PGLTableCellAction ] {
            //  cell does not add subUI cells
            // just provides the contextAction
            // nil filterInputActionCell will trigger a segue
            var allActions = [PGLTableCellAction]()
        
            /// Always has childSequenceStack. Only Add to the sequence
            let newAction = PGLTableCellAction(action: "Add", newAttribute: filterInputActionCell(), canPerformAction: false, targetAttribute: self)
            // this will segue to filterBranch.. opens the filterController
            allActions.append(newAction)

            return allActions
    }



    override func setChildStackMode(inAppStack: PGLAppStack) {
        guard let localInputStack = inputStack
        else { return }
        if inputParmType() == ImageParm.inputChildStack {
            
            // set childMode to Add
            // the inputStack does not need to be  pushed
            // the caller handles that in
           //      SelectParmController #trailingSwipeActions
            //     #performSegue
            localInputStack.stackMode = FilterChangeMode.add
        }
    }
//    override func uiCellIdentifier() -> String {
//        return  "Filters"
//    }

    

}
