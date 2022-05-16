//
//  PGLImageViewContainer.swift
//  Glance
//
//  Created by Will on 2/28/20.
//  Copyright © 2020 Will Loew-Blosser. All rights reserved.
//

import UIKit
import Photos
import PhotosUI
import os

let PGLImageAccepted = NSNotification.Name(rawValue: "PGLImageAccepted")
let PGLSelectImageBack = NSNotification.Name(rawValue: "PGLSelectImageBack")
let PGLReplaceFilterEvent =  NSNotification.Name(rawValue: "PGLReplaceFilterEvent")

class PGLImagesSelectContainer: UIViewController {

//    var myTargetFilterAttribute: PGLFilterAttribute?  // model object
//    var fetchResult: PHFetchResult<PHAsset>!
//    var assetCollection: PHAssetCollection!

    var userAssetSelection: PGLUserAssetSelection! {
        didSet{
            Logger(subsystem: LogSubsystem, category: LogCategory).debug("PGLImagesSelectContainer set var userAssetSelection= \(String(describing: self.userAssetSelection))")
        }
    }
    var appStack: PGLAppStack!

    var notifications = [Any]() // an opaque type is returned from addObservor

    fileprivate func setActionButtons() {

        if userAssetSelection.sections.isEmpty {
            allBtn.isEnabled = false
            clearBtn.isEnabled = false
        } else {
            allBtn.isEnabled = userAssetSelection.isTransitionFilter()
                // only allow allBtn if the filter can use multiple images i.e. transition

            clearBtn.isEnabled = true
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        Logger(subsystem: LogSubsystem, category: LogNavigation).info("\( String(describing: self) + "-" + #function)")
        // pass vars to childerntr
        guard let myAppDelegate =  UIApplication.shared.delegate as? AppDelegate
                                 else {
            Logger(subsystem: LogSubsystem, category: LogCategory).fault("PGLImagesSelectContainer viewDidLoad FatalError(AppDelegate not loaded")
                return

        }
                             appStack = myAppDelegate.appStack
                      appStack.isImageControllerOpen = false

    }



    override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
        saveUserPick()
        for anObserver in  notifications {
            NotificationCenter.default.removeObserver(anObserver)
        }
        notifications = [Any]() // reset
//        NSLog("PGLImagesSelectContainer #viewDidDisappear ...")

       }



    override func viewWillAppear(_ animated: Bool) {
        super .viewWillAppear(animated)
        let myCenter =  NotificationCenter.default
        let queue = OperationQueue.main




        var aNotification = myCenter.addObserver(forName: PGLImageNavigationBack , object: nil , queue: queue) { [weak self ]
                   myUpdate in
            guard let self = self else { return } // a released object sometimes receives the notification
                          // the guard is based upon the apple sample app 'Conference-Diffable'
            Logger(subsystem: LogSubsystem, category: LogNavigation).info("PGLImagesSelectContainer  notificationBlock PGLImageNavigationBack")
            // PGLImageCollectionMasterController in the master section is navigating back.
            // navigate back here too
            self.navigationController?.popViewController(animated: true)
                          }
        notifications.append(aNotification)



        aNotification = myCenter.addObserver(forName: PGLImageCollectionOpen , object: nil , queue: queue) { [weak self ]
            myUpdate in
            guard let self = self else { return } // a released object sometimes receives the notification
                          // the guard is based upon the apple sample app 'Conference-Diffable'
            Logger(subsystem: LogSubsystem, category: LogNavigation).info("PGLImagesSelectContainer  notificationBlock PGLImageCollectionOpen")
            self.setActionButtons()
                   }
         notifications.append(aNotification)

       aNotification =  myCenter.addObserver(forName: PGLReplaceFilterEvent, object: self , queue: queue) { [weak self]
                   myUpdate in
                   guard let self = self else { return } // a released object sometimes receives the notification
                                 // the guard is based upon the apple sample app 'Conference-Diffable'
        Logger(subsystem: LogSubsystem, category: LogNavigation).debug("PGLImagesSelectContainer  notificationBlock PGLReplaceFilterEvent")
                   // pull out the changed filterAttribute and assign to the userAssetSelection object

                let currentFilter = self.appStack.outputStack.currentFilter()
                self.userAssetSelection.changeTarget(filter: currentFilter)

               }
         notifications.append(aNotification)

        aNotification = myCenter.addObserver(forName: PGLImageCollectionChange , object: nil , queue: queue) { [weak self]
        myUpdate in
        guard let self = self else { return } // a released object sometimes receives the notification
                      // the guard is based upon the apple sample app 'Conference-Diffable'
        Logger(subsystem: LogSubsystem, category: LogNavigation).debug("PGLImagesSelectContainer  notificationBlock PGLImageCollectionChange")
        if let assetInfo = ( myUpdate.userInfo?["assetInfo"]) as? PGLAlbumSource {
            let userSelectionInfo = PGLUserAssetSelection(assetSources: assetInfo)
            if let newSource = self.userAssetSelection.merge(newAssetSource: userSelectionInfo)
                {
                Logger(subsystem: LogSubsystem, category: LogNavigation).debug("PGLImagesSelectContainter observer for PGLImageCollectionChange is triggering PGLImageAlbumAdded")
                    let changeAlbumNotification = Notification(name:PGLImageAlbumAdded)
                    NotificationCenter.default.post(name: changeAlbumNotification.name, object: nil, userInfo: ["newSource": newSource as Any])
                }
            }
        }
        notifications.append(aNotification)
       
    }


    func postSelectionChange(){
           let notification = Notification(name:PGLSequenceSelectUpdate)
           NotificationCenter.default.post(notification)
       }

    func saveUserPick() {
        userAssetSelection.setUserPick()

        // and pop back to the parmController
        let actionAccepted = Notification(name: PGLImageAccepted )
        NotificationCenter.default.post(actionAccepted)

        // post navigation to the PGLImagesSelectContainer too
          // this makes both the master and the detail navigate back

        // commented out afte the switch of the parm/select actions
//        let imageBackNotification = Notification(name: PGLSelectImageBack )
//        NotificationCenter.default.post(imageBackNotification)


//        NSLog ("PGLImagesSelectContainer #collectionAcceptAction PGLImageAccepted notification")
//        navigationController?.popViewController(animated: true)
    }

    @IBAction func clearBtnClick(_ sender: UIBarButtonItem) {
        userAssetSelection.removeAll()
        postSelectionChange()
       
    }

    @IBAction func allBtnClick(_ sender: UIBarButtonItem) {

                userAssetSelection.addAll()
                postSelectionChange()

    }

    @IBAction func backBtn(_ sender: UIBarButtonItem) {
//        post navigation to the PGLImagesSelectContainer too
                 // this makes both the master and the detail navigate back

        navigationController?.popViewController(animated: true)
       let imageBackNotification = Notification(name: PGLSelectImageBack )
       NotificationCenter.default.post(imageBackNotification)
    }



    @IBOutlet weak var allBtn: UIBarButtonItem!

   

    @IBOutlet weak var clearBtn: UIBarButtonItem!





    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        // embed segue is invoked to load childern
        // two embed segues..
        //  both share the same model object - userAssetSelection

        let segueId = segue.identifier
        Logger(subsystem: LogSubsystem, category: LogNavigation).info("\( String(describing: self) + "-" + #function) + \(String(describing: segueId))")
        
            switch segueId {
            case "lowerAssetGridSegue":
                        if let pictureGrid = segue.destination as? PGLAssetGridController {
                            pictureGrid.userAssetSelection = userAssetSelection
                                pictureGrid.title = title
                                }

            case  "upperSequenceController" :
                               if let pictureGrid = segue.destination as? PGLAssetSequenceController {
                                   pictureGrid.userAssetSelection = userAssetSelection
                                       pictureGrid.title = title
                           }
            case "showZoomDetail" :
                    guard let destination = segue.destination  as? PGLAssetController
                                   else {
                            NSLog(" PGLImagesSelectContainer prepare segue fatalError( unexpected view controller for segue")
                            return
                    }
                               destination.userAssetSelection = self.userAssetSelection
                    NSLog("PGLImagesSelectContainer #prepare.. segue to PGLAssetController")

            default: return
        }
    }
}



