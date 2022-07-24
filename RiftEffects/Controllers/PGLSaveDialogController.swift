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
    var stackType: String!  // 2/15/22 stackType will also store to albumName.. interface is labelled album
    var albumName: String?
    var storeToPhoto = false
    var shouldSaveAs = false
    var saveSessionUUID = UUID()

}

class PGLSaveDialogController: UIViewController, UITextFieldDelegate {
    // 2/22/2021  Change to stackView TableView controller
    // see examples in Filterpedia and UIStackView documentation
    // esp figure 7 with nestedStackViews for label and text input cells
    // capture new values for the stack and notify the parent view to saveStack

    // saveAs.. will nil out the CDvars of the stack. On save new ones are created

    // 2021/08/07 after user has saved 15 images then ask for an app review for this version

    var appStack: PGLAppStack!
    var userEnteredStackName: String?
    var userEnteredStackType: String?
//    var userEnteredAlbumName: String?
    var shouldStoreToPhotos: Bool = false
    var doSaveAs: Bool = false


//    var parentImageController: PGLImageController!

    @IBOutlet weak var saveFieldsStack: UIStackView!


    @IBOutlet weak var stackName: UITextField! {
        didSet {
            stackName.delegate = self
        }
    }
    @IBOutlet weak var scrollView: UIScrollView!

    @IBOutlet weak var stackType: UITextField! {
        didSet {
            stackType.delegate = self
        }
    }



    @IBOutlet weak var toPhotos: UISwitch!
    
    @IBOutlet weak var albumLabel: UILabel!


    @IBAction func storeToLibEdit(_ sender: UISwitch) {
        shouldStoreToPhotos = sender.isOn
//        albumName.text = userEnteredStackType

//        if shouldStoreToPhotos {
//            userEnteredAlbumName = albumName.text
//            // after UISwitch change
//        }
        
    }

    @IBAction func stackNameEditChange(_ sender: UITextField) {
        userEnteredStackName = sender.text

    }

    @IBAction func stackTypeEditChange(_ sender: UITextField) {
        userEnteredStackType = sender.text
    }

//    @IBAction func albumNameEditChange(_ sender: UITextField) {
//        userEnteredAlbumName = sender.text
//    }

    @IBAction func cancelBtnAction(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)

    }

    @IBAction func upperSaveBtn(_ sender: UIButton) {
        saveAction()

    }



    // MARK: UITextFieldDelegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {

        textField.resignFirstResponder()
        return true
    }

    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return true
    }


    @objc func handleKeyboardNotification(_ notification: Notification) {
        // from UIKitCatalog  TextViewController example
        guard let userInfo = notification.userInfo else { return }

        // Get the animation duration.
        var animationDuration: TimeInterval = 0
        if let value = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber {
           animationDuration = value.doubleValue
        }

        // Convert the keyboard frame from screen to view coordinates.
        var keyboardScreenBeginFrame = CGRect()
        if let value = (userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue) {
            keyboardScreenBeginFrame = value.cgRectValue
        }

        var keyboardScreenEndFrame = CGRect()
        if let value = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue) {
            keyboardScreenEndFrame = value.cgRectValue
        }

        let keyboardViewBeginFrame = view.convert(keyboardScreenBeginFrame, from: view.window)
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)

        let originDelta = keyboardViewEndFrame.origin.y - keyboardViewBeginFrame.origin.y

        // The text view should be adjusted, update the constant for this constraint.
//        bottomLayoutGuideConstraint.constant -= originDelta
//        topLayoutGuideConstraint.constant  += originDelta
        // Inform the view that its autolayout constraints have changed and the layout should be updated.
//        view.setNeedsUpdateConstraints()

        // Animate updating the view's layout by calling layoutIfNeeded inside a `UIViewPropertyAnimator` animation block.
//        let textViewAnimator = UIViewPropertyAnimator(duration: animationDuration, curve: .easeIn, animations: { [weak self] in
//            self?.view.layoutIfNeeded()
//        })
//        textViewAnimator.startAnimation()
//        scrollView.

    }



    // MARK: View Lifecycle
    fileprivate func saveAction() {
        var saveData = PGLStackSaveData()
        saveData.stackName = userEnteredStackName
        saveData.stackType = userEnteredStackType
        saveData.albumName = userEnteredStackType // 2/15/22 stack type now labelled album
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
        Logger(subsystem: LogSubsystem, category: LogNavigation).info("\( String(describing: self) + "-" + #function)")
        guard let myAppDelegate =  UIApplication.shared.delegate as? AppDelegate
            else {
            Logger(subsystem: LogSubsystem, category: LogCategory).fault( "PGLSaveDialogController viewDidLoad fatalError(AppDelegate not loaded")
            return
        }

        appStack = myAppDelegate.appStack
         let targetStack =  appStack.outputFilterStack()
        // a new save session reset the saveSessionUUID
        targetStack.saveSessionUUID = nil
        stackName.text  = targetStack.stackName
        stackType.text  =  targetStack.stackType
//        albumName.text  = targetStack.exportAlbumName
         userEnteredStackName = targetStack.stackName
        userEnteredStackType =  targetStack.stackType
//        userEnteredAlbumName =  targetStack.exportAlbumName
      

//        if isLimitedPhotoLibAccess() {
            // limited access does not allow album creation or save to album
//            albumName.isHidden = true
//            albumLabel.isHidden = true
//            userEnteredAlbumName = nil
//        } else {
//            albumName.isHidden = !shouldStoreToPhotos  // inits to false
//            albumLabel.isHidden = !shouldStoreToPhotos
//            albumName.isEnabled = shouldStoreToPhotos
//        }
        // adjust keyboard
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector: #selector(PGLSaveDialogController.handleKeyboardNotification(_:)),
                                       name: UIResponder.keyboardWillShowNotification,
                                       object: nil)

        notificationCenter.addObserver(self,
                                       selector: #selector(PGLSaveDialogController.handleKeyboardNotification(_:)),
                                       name: UIResponder.keyboardWillHideNotification,
                                       object: nil)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        notificationCenter.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
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

        if saveCount >= 5 && currentVersion != lastVersionPromptedForReview {
            let twoSecondsFromNow = DispatchTime.now() + 2.0
            DispatchQueue.main.asyncAfter(deadline: twoSecondsFromNow) {

                SKStoreReviewController.requestReview()
                // requestReview is deprecated in iOS 14.0
                // assuming that change to WindowScene will take
                // a long time as there is a huge library of apps using the AppDelegate protocols
                // should be requestReview(in windowScene: UIWindowScene)

                AppUserDefaults.set(currentVersion, forKey: PGLUserDefaultKeys.lastVersionPromptedForReviewKey)

            }
        }
    }
}
