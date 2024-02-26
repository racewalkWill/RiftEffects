//
//  PGLImageListPicker.swift
//  RiftEffects
//
//  Created by Will on 1/15/24.
//  Copyright © 2024 Will Loew-Blosser. All rights reserved.
//

import UIKit
import PhotosUI
import os

    /// answers new PGLImageList containing picked items from thephotos library
    /// used by both PGLSplitViewController and PGLSelectParmController
class PGLImageListPicker:  PHPickerViewControllerDelegate {

    var pickingImageList: PGLImageList
    var controller: UIViewController
    var parmAttribute: PGLFilterAttributeImage?

    /// vars from PHPickerDemo
    /// WWDC21 session 10046: Improve access to Photos in your app.
    private var selection = [String: PHPickerResult]()
    private var selectedAssetIdentifiers = [String]()
    private var currentAssetIdentifier: String?

    init(targetList: PGLImageList?, controller: UIViewController) {

        self.pickingImageList =  targetList ?? PGLImageList()
        self.controller = controller
    }


    func set(targetAttribute: PGLFilterAttributeImage? ) -> PHPickerViewController? {

        // targetAttribute will be nil for the PGLSplitViewController case
        parmAttribute = targetAttribute
        var configuration = PHPickerConfiguration.init(photoLibrary: .shared())

        if (targetAttribute?.isTransitionFilter ??  false ) {
            configuration.selectionLimit = 0
        } else {
            configuration.selectionLimit = 1
        }
                // Set the selection behavior to respect the user’s selection order.

        // by default a configuration object displays all asset types: images, Live Photos, and videos.
        configuration.preferredAssetRepresentationMode = .automatic
        configuration.selection = .ordered

        configuration = loadExistingSelection(configuration: &configuration, sourceAttribute: targetAttribute)

        let myPickerView = PHPickerViewController(configuration: configuration)
        myPickerView.delegate = self
        return myPickerView
    }

        /// put current selection identifiiers into the pickerConfiguration
    func loadExistingSelection( configuration: inout PHPickerConfiguration, sourceAttribute: PGLFilterAttributeImage?) -> PHPickerConfiguration  {
            if let mySelection = sourceAttribute?.inputCollection?.assetIDs {
                configuration.preselectedAssetIdentifiers = mySelection
            }
            return configuration
    }


    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        


        picker.dismiss(animated: true)

        loadImageListFromPicker(results: results, theController: controller)
        if let parmController = controller as? PGLSelectParmController {
            parmController.pickerCompletion(pickerController:picker, pickedImageList: pickingImageList)
        }

    }

    func loadImageListFromPicker(results: [PHPickerResult], theController: UIViewController){
            //PHPickerResult has
            //var assetIdentifier: String? and var itemProvider: NSItemProvider

        // =========== new picker
        let existingSelection = self.selection
        var newSelection = [String: PHPickerResult]()
        for result in results {
            let identifier = result.assetIdentifier!
            newSelection[identifier] = existingSelection[identifier] ?? result
        }

        // Track the selection in case the user deselects it later.
        selection = newSelection // has full PHPickerResult in dict by assetIdentifier
        selectedAssetIdentifiers = results.map(\.assetIdentifier!)

        if selection.isEmpty {
            pickingImageList = PGLImageList()
            return
        }

        // =========== end new picker
        var identifiers:[String] = selection.keys.map(\.description)

        // start full access mode
        let fetchAssetResult = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
        // in limited access mode an identifier may not fetch the asset

        NSLog("didFinish identifiers = \(identifiers) in fetchResult \(fetchAssetResult)")

        var assets = [PGLAsset]()
        identifiers = [String]()
            // reset - not all identifiers are fetched in limited Photos mode

        for fetchAsset in fetchAssetResult.objects {
            let anNewPGLAsset = PGLAsset(sourceAsset: fetchAsset)
            assets.append(anNewPGLAsset)
            identifiers.append(fetchAsset.localIdentifier)
            // if video then cache into local file and assign localURL to asset
            if let thisResultProvider = selection[fetchAsset.localIdentifier] {
                if thisResultProvider.itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                    let myAppDelegate =  UIApplication.shared.delegate as! AppDelegate
                    myAppDelegate.showWaiting(onController: theController)

                    loadLocalVideoURL(thisAsset: anNewPGLAsset, pickerResult: selection[fetchAsset.localIdentifier]!)
                }
                }
            }

        let selectedImageList = PGLImageList(localPGLAssets: assets)
        // here assign the  identifiers into the imageList
        selectedImageList.assetIDs = identifiers
        // PGLImageList will load actual image in imageFrom()

        pickingImageList =  selectedImageList
        
        if let myTargetParm = parmAttribute {
            // when setting inputs to the parm controller
            // not used for the PGLSplitViewController case
            myTargetParm.inputCollection = pickingImageList
        } else {
            if let mySplitController = controller as? PGLSplitViewController {
                mySplitController.startupImageList = pickingImageList
            }
        }

    }

    func loadLocalVideoURL(thisAsset: PGLAsset, pickerResult: PHPickerResult ) {
//        let progress: Progress?
        var localURL: URL?
        pickerResult.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] url, error in
            do {
                guard let url = url, error == nil else {
                    throw error ?? NSError(domain: NSFileProviderErrorDomain, code: -1, userInfo: nil)
                }
                localURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
                if localURL == nil {
                    return
                }
                try? FileManager.default.removeItem(at: localURL!)
                try FileManager.default.copyItem(at: url, to: localURL!)

                DispatchQueue.main.async {
                    self?.handleVideoCompletion(asset: thisAsset, object: localURL!)
                }
            } catch let caughtError {
                DispatchQueue.main.async {
                    self?.handleVideoCompletion(asset: thisAsset, object: nil, error: caughtError)
                }
            }
    }

  }

    func handleVideoCompletion(asset: PGLAsset, object: Any?, error: Error? = nil) {
        //based on sample app PHPickerDemo same  method

//        if let livePhoto = object as? PHLivePhoto {
//            displayLivePhoto(livePhoto)
//        } else if let image = object as? UIImage {
//            displayImage(image)
//        } else

        if let url = object as? URL {
            asset.requestVideo(videoURL: url)
        } else if let error = error {
            NSLog("Couldn't display \(asset.localIdentifier) with error: \(error)")

//            displayErrorImage()
//        } else {
//            displayUnknownImage()
        }
    }

}
