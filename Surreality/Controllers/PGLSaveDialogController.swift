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



    @IBAction func saveBtnClick(_ sender: UIBarButtonItem) {

        var saveData = PGLStackSaveData()
        saveData.stackName = userEnteredStackName
        saveData.stackType = userEnteredStackType
        saveData.albumName = userEnteredAlbumName
        saveData.storeToPhoto = shouldStoreToPhotos
        saveData.shouldSaveAs = doSaveAs
        let stackNotification = Notification(name: PGLStackSaveNotification, object: nil, userInfo: ["dialogData":saveData])

        NotificationCenter.default.post(stackNotification)
        dismiss(animated: true, completion: nil )
    }


// MARK: View Load TableView config
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let myAppDelegate =  UIApplication.shared.delegate as? AppDelegate
            else { fatalError("AppDelegate not loaded")}

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
}
