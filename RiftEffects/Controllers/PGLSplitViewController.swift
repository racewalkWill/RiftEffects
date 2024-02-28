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

    var startupImageList: PGLImageList? {
        didSet {
            /// PGLImageListPicker sets the value in loadImageListFromPicker(results: )
            if startupImageList != nil {
                appStack.viewerStack.loadStartup(userStartupImageList: startupImageList!)
            }
        }
    }

    var appStack: PGLAppStack! {
        // now a computed property
        guard let myAppDelegate =  UIApplication.shared.delegate as? AppDelegate
            else { Logger(subsystem: LogSubsystem, category: LogCategory).fault("PGLSplitViewController viewDidLoad fatalError(AppDelegate not loaded")
            fatalError("PGLSplitViewController could not access the AppDelegate")
        }
       return  myAppDelegate.appStack
    }

    var imageListPicker: PGLImageListPicker?

    override func viewDidLoad() {
        Logger(subsystem: LogSubsystem, category: LogNavigation).info("\( String(describing: self) + "-" + #function)")
        super.viewDidLoad()
        delegate = self

        preferredDisplayMode = UISplitViewController.DisplayMode.oneBesideSecondary 
        // if the smaller iPhone is compact then should be the two column where the columns are controlled by buttons
        // used to have this.. check versions


        presentsWithGesture = true
        showsSecondaryOnlyButton = false
            // this button shows on the navigation of the secondary controller - the imageController
            // it goes to full screen secondaryOnly column
            // NOT needed now that doubletap to full screen is implemented

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
        requestStartupImage()

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
        navigationItem.leftItemsSupplementBackButton = true

        if deviceIdom == .phone {
            navigationItem.hidesBackButton = false
            showsSecondaryOnlyButton = false
                // showsSecondaryOnlyButton  not needed for full screen of the PGLImageController
                // now doubleTap on the PGLImageController opens full screen of the PGLMetalController
            }

    }

    func stackProviderHasRows() -> Bool {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let provider = PGLStackProvider(with: appDelegate!.dataWrapper.persistentContainer)
        provider.setFetchControllerForBackgroundContext()
        let stackRowCount = provider.filterStackCount()
        provider.reset()
        return stackRowCount > 0
    }

    // MARK: startup Pick

    func requestStartupImage() {
        if startupImageList == nil {
            let newList = PGLImageList()

            imageListPicker = PGLImageListPicker(targetList: newList, controller: self)
            if imageListPicker != nil {
                    /// with  a nil  target attribute just picks one image from the photoLibary
                guard let pickerViewController = imageListPicker!.set(targetAttribute: nil)
                    else { return }
                self.present(pickerViewController, animated: true)
            }
        }
    }





}
