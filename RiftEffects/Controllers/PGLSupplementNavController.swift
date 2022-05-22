//
//  PGLSupplementNavController.swift
//  RiftEffects
//
//  Created by Will on 5/16/22.
//  Copyright © 2022 Will Loew-Blosser. All rights reserved.
//

import UIKit
import os

class PGLSupplementNavController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
//        setRoot()
        // Do any additional setup after loading the view.
        Logger(subsystem: LogSubsystem, category: LogNavigation).info("\( String(describing: self) + "-" + #function)")

        let myCenter =  NotificationCenter.default
        let queue = OperationQueue.main
        myCenter.addObserver(forName: PGLShowStackImageContainer, object: nil , queue: queue) { [weak self]
            myUpdate in
            guard let self = self else { return } // a released object sometimes receives the notification
                          // the guard is based upon the apple sample app 'Conference-Diffable'

            Logger(subsystem: LogSubsystem, category: LogNavigation).info( "PGLSupplementNavController  notificationBlock PGLSupplementNavController")

//            let pushedNewContainer = self.pushStackImageContainer()

        }

    }

    override func viewDidDisappear(_ animated: Bool) {
        super .viewDidDisappear(animated)
//        NSLog("PGLSelectFilterController #viewDidDisappear removing notification observor")

        NotificationCenter.default.removeObserver(self, name: PGLShowStackImageContainer, object: self)
    }

        /// push StackImageController in the iPhone compact mode
    func pushStackImageContainer() -> Bool {
        // now moved back to the PGLStackController viewDidLoad...
        // remove this implementation?
        
        let iPhoneCompact =   (traitCollection.userInterfaceIdiom) == .phone
                                && (traitCollection.horizontalSizeClass == .compact)

        if iPhoneCompact {
            // either loaded by the supplementary nav controller OR
            // loaded as a content area in the two content container for stack & image controller
//            let isInsideContainer = parent is PGLStackImageContainerController
            let hasLoadedStackController = topViewController is PGLStackController

            if hasLoadedStackController {
                Logger(subsystem: LogSubsystem, category: LogNavigation).info("\( String(describing: self) + "-" + #function)")

                if let  stackImageController = storyboard?.instantiateViewController(withIdentifier: "StackImageContainer") as? PGLStackImageContainerController {
                    navigationController?.pushViewController(stackImageController, animated: true)
                    return true
                }
            else {
                return false
                }
            }
        }
        return false
    }


/// remove old method setRoot()
    func setRoot() {
        //  root view will be Stack controller
        // OR the StackImageController in the iPhone compact mode
        let iPhoneCompact =   (traitCollection.userInterfaceIdiom) == .phone
                                && (traitCollection.horizontalSizeClass == .compact)

        if iPhoneCompact {
            if let  stackImageController = storyboard?.instantiateViewController(withIdentifier: "StackImageContainer") as? PGLStackImageContainerController {
                pushViewController(stackImageController, animated: true)
            } else
            {
                if let  stackController = storyboard?.instantiateViewController(withIdentifier: "StackController") as? PGLStackController {
                    pushViewController(stackController, animated: true)
                }
            }
        //else don't change root relation if iPad
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
