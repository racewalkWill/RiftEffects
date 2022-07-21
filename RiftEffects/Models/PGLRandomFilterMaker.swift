//
//  PGLRandomFilterMaker.swift
// 
//
//  Created by Will on 8/11/21.
//  Copyright © 2021 Will Loew-Blosser. All rights reserved.
//

import Foundation
import UIKit
import os

class PGLRandomFilterMaker: PGLTransitionFilter {
    // uses  PGLDemo & PGLRandomFilterAction to add random filters to the stack

    var demoCreator = PGLDemo()

    override class func localizedDescription(filterName: String) -> String {
        // custom subclasses should override
       return "Swipe 'Make' to add random filters. Select photos for random input on Parms 'Pick' command"
    }


    override func cellFilterAction(stackController: PGLStackController, indexPath: IndexPath) -> [UIContextualAction] {
        var normalSwipeActions = super.cellFilterAction(stackController: stackController, indexPath: indexPath)

        let makeRandomFiltersAction =  UIContextualAction(style: .normal, title: "Make") { [weak self] (_, _, completion) in
            guard let self = self
                else { return  }

            Logger(subsystem: LogSubsystem, category: LogCategory).info("PGLStackController trailingSwipeActionsConfigurationForRowAt runMakeRandom")

            self.demoCreator.runMakeRandom(stackController: stackController)
            completion(true)
        }
        normalSwipeActions.append(makeRandomFiltersAction)

        return normalSwipeActions

    }

    override func setImageValuesAndClone(inputList: PGLImageList, attributeName: String) {
        PGLDemo.RandomImageList = inputList
        super.setImageValuesAndClone(inputList: inputList, attributeName: attributeName)

    }



}
