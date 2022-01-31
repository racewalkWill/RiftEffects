//
//  PGLSaveDialogController.swift
//  Surreality
//
//  Created by Will on 2/21/21.
//  Copyright © 2021 Will Loew-Blosser. All rights reserved.
//

import Foundation
import UIKit
import Photos
import os
import StoreKit

let  PGLStackSaveNotification = NSNotification.Name(rawValue: "PGLStackSaveNotification")

struct PGLStackSaveData {
    // used to pass user entered values to the calling ViewController
    // in the PGLStackSaveNotification

    var stackName: String!
    var stackType: String!
    var albumName: String?
    var storeToPhoto = false
    var shouldSaveAs = false

}

class PGLSaveDialogController: UIViewController {
    // 2/22/2021  Change to stackView TableView controller
    // see examples in Filterpedia and UIStackView documentation
    // esp figure 7 with nestedStackViews for label and text input cells
    // capture new values for the stack and notify the parent view to saveStack

    // saveAs.. will nil out the CDvars of the stack. On save new ones are created

    // 2021/08/07 after user has saved 15 images then ask for an app review for this version

    var appStack: PGLAppStack!
    var userEnteredStackName: String?
    var userEnteredStackType: String?
    var userEnteredAlbumName: String?
    var shouldStoreToPhotos: Bool = false
    var doSaveAs: Bool = false


//    var parentImageController: PGLImageController!
    @IBOutlet weak var saveDialogLabel: UILabel!

    @IBOutlet weak var stackName: UITextField!

    @IBOutlet weak var stackType: UITextField!

    @IBOutlet weak var albumName: UITextField!

    @IBOutlet weak var toPhotos: UISwitch!
    
    @IBOutlet weak var albumLabel: UILabel!


    @IBAction func storeToLibEdit(_ sender: UISwitch) {
        shouldStoreToPhotos = sender.isOn
        albumName.isHidden = !shouldStoreToPhotos
        albumLabel.isHidden = !shouldStoreToPhotos
        albumName.isEnabled = shouldStoreToPhotos
        if (albumName.text!.isEmpty) {
            albumName.text = userEnteredStackType
            // default value

        }
        if shouldStoreToPhotos {
            userEnteredAlbumName = albumName.text
            // after UISwitch change
        }
        
    }

    @IBAction func stackNameEditChange(_ sender: UITextField) {
        userEnteredStackName = sender.text

    }

    @IBAction func stackTypeEditChange(_ sender: UITextField) {
        userEnteredStackType = sender.text
    }

    @IBAction func albumNameEditChange(_ sender: UITextField) {
        userEnteredAlbumName = sender.text
    }

    @IBAction func cancelBtnAction(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)

    }

    @IBAction func upperSaveBtn(_ sender: UIButton) {
        saveAction()

    }

    fileprivate func saveAction() {
        var saveData = PGLStackSaveData()
        saveData.stackName = userEnteredStackName
        saveData.stackType = userEnteredStackType
        saveData.albumName = userEnteredAlbumName
        saveData.storeToPhoto = shouldStoreToPhotos
        saveData.shouldSaveAs = doSaveAs
        incrementSaveCountForAppReview()

        dismiss(animated: true, completion: {
            let stackNotification = Notification(name: PGLStackSaveNotification, object: nil, userInfo: ["dialogData":saveData])
            NotificationCenter.default.post(stackNotification)} )
    }

   

// MARK: View Load TableView config
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let myAppDelegate =  UIApplication.shared.delegate as? AppDelegate
            else {
            Logger(subsystem: LogSubsystem, category: LogCategory).fault( "PGLSaveDialogController viewDidLoad fatalError(AppDelegate not loaded")
            return
        }

        appStack = myAppDelegate.appStack
         let targetStack =  appStack.outputFilterStack()
        stackName.text  = targetStack.stackName
        stackType.text  =  targetStack.stackType
        albumName.text  = targetStack.exportAlbumName
         userEnteredStackName = targetStack.stackName
        userEnteredStackType =  targetStack.stackType
        userEnteredAlbumName =  targetStack.exportAlbumName
        if doSaveAs {saveDialogLabel.text = "Save Stack As.."
            } else { saveDialogLabel.text = "Save Stack" }

        if isLimitedPhotoLibAccess() {
            // limited access does not allow album creation or save to album
            albumName.isHidden = true
            albumLabel.isHidden = true
            userEnteredAlbumName = nil
        } else {
            albumName.isHidden = !shouldStoreToPhotos  // inits to false
            albumLabel.isHidden = !shouldStoreToPhotos
            albumName.isEnabled = shouldStoreToPhotos
        }
    }

    func isLimitedPhotoLibAccess() -> Bool {
        let accessLevel: PHAccessLevel = .readWrite // or .addOnly
        let authorizationStatus = PHPhotoLibrary.authorizationStatus(for: accessLevel)

        switch authorizationStatus {
            case .limited :
            return true
        default:
            // all other authorizationStatus values
           return false
        }
    }

    //MARK: App Review save count
    func incrementSaveCountForAppReview() {
        // based on Apple sample StoreKitReviewRequest example code

        var saveCount = AppUserDefaults.integer(forKey: PGLUserDefaultKeys.processCompletedCountKey)
        saveCount += 1
        AppUserDefaults.set(saveCount, forKey: PGLUserDefaultKeys.processCompletedCountKey)

        // Get the current bundle version for the app
        let infoDictionaryKey = kCFBundleVersionKey as String
        guard let currentVersion = Bundle.main.object(forInfoDictionaryKey: infoDictionaryKey) as? String
            else { fatalError("Expected to find a bundle version in the info dictionary") }

        let lastVersionPromptedForReview = AppUserDefaults.string(forKey: PGLUserDefaultKeys.lastVersionPromptedForReviewKey)

        if saveCount >= 15 && currentVersion != lastVersionPromptedForReview {
            let twoSecondsFromNow = DispatchTime.now() + 2.0
            DispatchQueue.main.asyncAfter(deadline: twoSecondsFromNow) {

                SKStoreReviewController.requestReview()
                // requestReview is deprecated in iOS 14.0
                // assuming that change to WindowScene will take
                // a long time as there is a huge library of apps using the AppDelegate protocols

                AppUserDefaults.set(currentVersion, forKey: PGLUserDefaultKeys.lastVersionPromptedForReviewKey)

            }
        }
    }
}
