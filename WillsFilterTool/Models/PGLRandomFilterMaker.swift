//
//  PGLRandomFilterMaker.swift
//  WillsFilterTool
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

    override func setUserPick(attribute: PGLFilterAttribute, imageList: PGLImageList) {
        super .setUserPick(attribute: attribute, imageList: imageList)

        PGLDemo.RandomImageList = imageList
            // class var means the this list will persist with each randomMaker..
            // if changed to instance var then source list needs to be picked each time..

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

}
