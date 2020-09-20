//
//  PGLImageViewContainer.swift
//  Glance
//
//  Created by Will on 2/28/20.
//  Copyright © 2020 Will. All rights reserved.
//

import UIKit
import Photos
import PhotosUI

let PGLImageAccepted = NSNotification.Name(rawValue: "PGLImageAccepted")
let PGLSelectImageBack = NSNotification.Name(rawValue: "PGLSelectImageBack")
let PGLReplaceFilterEvent =  NSNotification.Name(rawValue: "PGLReplaceFilterEvent")

class PGLImagesSelectContainer: UIViewController {

//    var myTargetFilterAttribute: PGLFilterAttribute?  // model object
//    var fetchResult: PHFetchResult<PHAsset>!
//    var assetCollection: PHAssetCollection!

    var userAssetSelection: PGLUserAssetSelection! {
        didSet{
            NSLog("PGLImagesSelectContainer set var userAssetSelection= \(userAssetSelection)")
        }
    }
    var appStack: PGLAppStack!

    var notifications = [Any]() // an opaque type is returned from addObservor

    fileprivate func setActionButtons() {
        if userAssetSelection.isEmpty() {
            // nothing to show - turn off action buttons

            collectionAcceptBtn.isEnabled = false

        } else {

            collectionAcceptBtn.isEnabled = true

        }

        if userAssetSelection.sections.isEmpty {
            allBtn.isEnabled = false
            clearBtn.isEnabled = false
        } else {
            allBtn.isEnabled = true
            clearBtn.isEnabled = true
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // pass vars to childerntr
        guard let myAppDelegate =  UIApplication.shared.delegate as? AppDelegate
                                 else { fatalError("AppDelegate not loaded")}
                             appStack = myAppDelegate.appStack
                      appStack.isImageControllerOpen = false

    }



    override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
        for anObserver in  notifications {
            NotificationCenter.default.removeObserver(anObserver)
        }
        notifications = [Any]() // reset
        NSLog("PGLImagesSelectContainer #viewDidDisappear ...")

       }



    override func viewWillAppear(_ animated: Bool) {
        super .viewWillAppear(animated)
        let myCenter =  NotificationCenter.default
        let queue = OperationQueue.main




        var aNotification = myCenter.addObserver(forName: PGLImageNavigationBack , object: nil , queue: queue) { [weak self ]
                   myUpdate in
            guard let self = self else { return } // a released object sometimes receives the notification
                          // the guard is based upon the apple sample app 'Conference-Diffable'
            // PGLImageCollectionMasterController in the master section is navigating back.
            // navigate back here too
            self.navigationController?.popViewController(animated: true)
                          }
        notifications.append(aNotification)

        aNotification =  myCenter.addObserver(forName: PGLImageSelectUpdate , object: nil , queue: queue) { [weak self ]
            myUpdate in
            guard let self = self else { return } // a released object sometimes receives the notification
                          // the guard is based upon the apple sample app 'Conference-Diffable'
            self.collectionAcceptBtn.isEnabled = !(self.userAssetSelection.isEmpty() )

            }
        notifications.append(aNotification)

        aNotification = myCenter.addObserver(forName: PGLImageCollectionOpen , object: nil , queue: queue) { [weak self ]
            myUpdate in
            guard let self = self else { return } // a released object sometimes receives the notification
                          // the guard is based upon the apple sample app 'Conference-Diffable'
            NSLog("PGLImagesSelectContainer PGLImageCollectionOpen call setActionButtons ")
            self.setActionButtons()
                   }
         notifications.append(aNotification)

       aNotification =  myCenter.addObserver(forName: PGLReplaceFilterEvent, object: self , queue: queue) { [weak self]
                   myUpdate in
                   guard let self = self else { return } // a released object sometimes receives the notification
                                 // the guard is based upon the apple sample app 'Conference-Diffable'
                   NSLog("PGLImagesSelectContainer  notificationBlock PGLReplaceFilterEvent")
                   // pull out the changed filterAttribute and assign to the userAssetSelection object

                let currentFilter = self.appStack.outputStack.currentFilter()
                self.userAssetSelection.changeTarget(filter: currentFilter)

               }
         notifications.append(aNotification)

        aNotification = myCenter.addObserver(forName: PGLImageCollectionChange , object: nil , queue: queue) { [weak self]
        myUpdate in
        guard let self = self else { return } // a released object sometimes receives the notification
                      // the guard is based upon the apple sample app 'Conference-Diffable'
        if let assetInfo = ( myUpdate.userInfo?["assetInfo"]) as? PGLAlbumSource {
            let userSelectionInfo = PGLUserAssetSelection(assetSources: assetInfo)
            if let newSource = self.userAssetSelection.merge(newAssetSource: userSelectionInfo)
                {
                    NSLog("PGLImagesSelectContainter observer for PGLImageCollectionChange is triggering PGLImageAlbumAdded")
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



    @IBAction func clearBtnClick(_ sender: UIBarButtonItem) {
        userAssetSelection.removeAll()
        collectionAcceptBtn.isEnabled = false
        postSelectionChange()
       
    }

    @IBAction func allBtnClick(_ sender: UIBarButtonItem) {

                userAssetSelection.addAll()
               collectionAcceptBtn.isEnabled = true
                postSelectionChange()

    }

    @IBAction func backBtn(_ sender: UIBarButtonItem) {
//        post navigation to the PGLImagesSelectContainer too
                 // this makes both the master and the detail navigate back

        navigationController?.popViewController(animated: true)
       let imageBackNotification = Notification(name: PGLSelectImageBack )
       NotificationCenter.default.post(imageBackNotification)
    }

    @IBOutlet weak var collectionAcceptBtn: UIBarButtonItem!

    @IBAction func collectionAcceptAction(_ sender: UIBarButtonItem) {
        userAssetSelection.setUserPick()

        // and pop back to the parmController
        let actionAccepted = Notification(name: PGLImageAccepted )
        NotificationCenter.default.post(actionAccepted)

        // post navigation to the PGLImagesSelectContainer too
          // this makes both the master and the detail navigate back

        // commented out afte the switch of the parm/select actions
//        let imageBackNotification = Notification(name: PGLSelectImageBack )
//        NotificationCenter.default.post(imageBackNotification)


        NSLog ("PGLImagesSelectContainer #collectionAcceptAction PGLImageAccepted notification")
        navigationController?.popViewController(animated: true)


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
                                   else { fatalError("unexpected view controller for segue")  }
                               destination.userAssetSelection = self.userAssetSelection
                    NSLog("PGLImagesSelectContainer #prepare.. segue to PGLAssetController")

            default: return
        }
    }
}



