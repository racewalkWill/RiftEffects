//
//  PGLSplitViewController.swift
//  Glance
//
//  Created by Will on 10/13/17.
//  Copyright © 2017 Will. All rights reserved.
//

import UIKit
import os
import Photos
import CoreData



class PGLSplitViewController: UISplitViewController, UISplitViewControllerDelegate, NSFetchedResultsControllerDelegate {

    override func viewDidLoad() {
        Logger(subsystem: LogSubsystem, category: LogNavigation).info("\( String(describing: self) + "-" + #function)")
        super.viewDidLoad()
        delegate = self
//       navigationItem.leftBarButtonItem = self.displayModeButtonItem
        let stackProviderCanOpen = stackProviderHasRows()
            
        if stackProviderCanOpen {
            preferredDisplayMode = UISplitViewController.DisplayMode.twoDisplaceSecondary
            // was UISplitViewController.DisplayMode.twoOverSecondary
        }
        else {
            preferredDisplayMode = UISplitViewController.DisplayMode.oneBesideSecondary }
        // if the smaller iPhone is compact then should be the two column where the columns are controlled by buttons
        // used to have this.. check versions


        presentsWithGesture = true
        showsSecondaryOnlyButton = true
            // this button shows on the navigation of the secondary controller - the imageController
        let horizontalSize = traitCollection.horizontalSizeClass
        if horizontalSize == .compact {

//            preferredPrimaryColumnWidthFraction = 0.3
//            preferredSupplementaryColumnWidthFraction = 0.3

//            guard let stackImageController = self.storyboard?.instantiateViewController(withIdentifier: "StackImageContainer")
//            else { checkPhotoLibraryAccess()
//                    return
//            }
//            if let supplementaryNav = viewController(for: .supplementary) as? UINavigationController {
//                supplementaryNav.setViewControllers([stackImageController], animated: true)
//            }

        }

        // Do any additional setup after loading the view.


    }



    func splitViewControllerDidCollapse(_ svc: UISplitViewController) {
        Logger(subsystem: LogSubsystem, category: LogCategory).notice("\( String(describing: self) + "-" + #function)")
    }

    func splitViewController(_ svc: UISplitViewController, topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column) -> UISplitViewController.Column {
        //horizontally regular to a horizontally compact size class

//        let horizontalSize = traitCollection.horizontalSizeClass
//        if horizontalSize == .compact {
//
//             return .supplementary
        // .supplementary has a controller with nav bar/buttons on the iPhone
        
//            // supplementary shows the effects col - on small screens this is full size
//            // but navigation works and the pict icon navigation works to see the
//            // image controller view
//        }
//        else { return proposedTopColumn}

//        if proposedTopColumn == .compact {
//            // change the to a single ImageController and use popup detent to show the other controllers
//            let stackImageController = self.storyboard?.instantiateViewController(withIdentifier: "StackImageContainer")
//            svc.setViewController(stackImageController, for: .compact)
//
//            return .compact
//        } else {
//            return proposedTopColumn
//        }

        return proposedTopColumn

    }



//    func splitViewController(_ svc: UISplitViewController,
//                             displayModeForExpandingToProposedDisplayMode proposedDisplayMode: UISplitViewController.DisplayMode) -> UISplitViewController.DisplayMode  {
//        return proposedDisplayMode
//
//    }



    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
// MARK: iPhone Navigation
    override func viewWillLayoutSubviews() {

//     navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
        // 2021-11-01 comment out the assignment and the triple column navigation comes back.
        // still not showing the imageController

        // turns on the full screen toggle button on the left nav bar
        // Do not change the configuration of the returned button.
        // The split view controller updates the button’s configuration and appearance automatically based on the current display mode
        // and the information provided by the delegate object.
        // mode is controlled by targetDisplayModeForAction(in svc: UISplitViewController) -> UISplitViewController.DisplayMode

        let deviceIdom = traitCollection.userInterfaceIdiom
        if deviceIdom == .phone {
            navigationItem.leftItemsSupplementBackButton = true
            navigationItem.hidesBackButton = false
            showsSecondaryOnlyButton = true
            }
        else {
            navigationItem.leftItemsSupplementBackButton = true
        }
    }

    func stackProviderHasRows() -> Bool {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let provider = PGLStackProvider(with: appDelegate!.dataWrapper.persistentContainer)
        let stackRowCount = provider.filterStackCount()
        return stackRowCount > 0
    }


}
