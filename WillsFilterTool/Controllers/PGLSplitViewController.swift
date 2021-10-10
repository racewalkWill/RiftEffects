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



class PGLSplitViewController: UISplitViewController, NSFetchedResultsControllerDelegate {

    override func viewDidLoad() {

        super.viewDidLoad()
 //       navigationItem.leftBarButtonItem = self.displayModeButtonItem
        if stackProviderHasRows() {
            preferredDisplayMode = UISplitViewController.DisplayMode.twoOverSecondary }
        else {
            preferredDisplayMode = UISplitViewController.DisplayMode.oneBesideSecondary }
        let deviceIdom = traitCollection.userInterfaceIdiom
        if deviceIdom == .phone
            { preferredSplitBehavior = UISplitViewController.SplitBehavior.displace }
//        else
//            { preferredSplitBehavior = UISplitViewController.SplitBehavior.automatic }

        presentsWithGesture = true
        showsSecondaryOnlyButton = true


        // Do any additional setup after loading the view.
        checkPhotoLibraryAccess()

    }

    @IBAction func goToSplitView(segue: UIStoryboardSegue) {
        Logger(subsystem: LogSubsystem, category: LogCategory).info("PGLParmsFilterTabsController goToSplitView segue")

    }
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

     navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
        // turns on the full screen toggle button on the left nav bar
        // Do not change the configuration of the returned button.
        // The split view controller updates the button’s configuration and appearance automatically based on the current display mode
        // and the information provided by the delegate object.
        // mode is controlled by targetDisplayModeForAction(in svc: UISplitViewController) -> UISplitViewController.DisplayMode

        let deviceIdom = traitCollection.userInterfaceIdiom
        if deviceIdom == .phone {
            navigationItem.leftItemsSupplementBackButton = false
            navigationItem.hidesBackButton = false
        }
        else {
            navigationItem.leftItemsSupplementBackButton = true
        }
    }

    func stackProviderHasRows() -> Bool {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let provider = PGLStackProvider(with: appDelegate!.dataWrapper.persistentContainer,
                                    fetchedResultsControllerDelegate: self)
        let stackRowCount = provider.filterStackCount()
        return stackRowCount > 0
    }

    // MARK: PhotoLib
    func checkPhotoLibraryAccess() {
        let requiredAccessLevel: PHAccessLevel = .readWrite // or .addOnly
        PHPhotoLibrary.requestAuthorization(for: requiredAccessLevel) { authorizationStatus in
            switch authorizationStatus {
                case .notDetermined , .denied:
                    Logger(subsystem: LogSubsystem, category: LogCategory).error("PhotoLibrary.requestAuthorization status notDetermined or denied)")
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "Photo Library access denied", message: "You may allow access to the Photo Library in Settings -> Privacy -> Photos -> Wills Filter Tool", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in

                        }))
                        guard let  myAppDelegate = UIApplication.shared.delegate as? AppDelegate
                        else {return
                                //can't do anything give up
                        }
                        myAppDelegate.displayUser(alert: alert)
                    }


                default:
                    // case of case .authorized, .restricted , .limited :
                    // user has made a setting.. the app can run
                    Logger(subsystem: LogSubsystem, category: LogCategory).debug("PhotoLibrary.requestAuthorization status is authorized or .restricted or .limited ")
            }
        }
    }


}
