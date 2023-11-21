//
//  PGLVideo.swift
//  RiftEffects
//
//  Created by Will on 10/20/23.
//  Copyright © 2023 Will Loew-Blosser. All rights reserved.
//  Based on code from ReplayKitSample app from Apple

import ReplayKit
import UIKit
import Photos
import os


extension PGLImageController {

    @objc func recordButtonTapped(controllerRecordBtn: UIBarButtonItem) {
        if !RPScreenRecorder.shared().isAvailable {
            fatalError("RPScreenRecorder is NOT available")
        }
            // Check the internal recording state.
        if PGLImageController.isActive == false {
                // If a recording isn't currently underway, start it.
            startRecording()
            guard let recordImage = UIImage(systemName: "recordingtape.circle.fill")
                else { return  }
            controllerRecordBtn.setSymbolImage(recordImage, contentTransition: .automatic)
            controllerRecordBtn.tintColor = UIColor.red
        } else {
                // If a recording is active, the button stops it.
            stopRecording()
            guard let normalRecordImage = UIImage(systemName: "recordingtape")
                else { return  }
            controllerRecordBtn.setSymbolImage(normalRecordImage, contentTransition: .automatic)
            controllerRecordBtn.tintColor = nil  // returns to system default
        }

    }

    func startRecording() {

        RPScreenRecorder.shared().startRecording { error in
                // If there is an error, print it and set the button title and state.
            if error == nil {
                    // There isn't an error and recording starts successfully. Set the recording state.
                self.setRecordingState(active: true)

                NSLog("Success starting RPScreenRecorder")
                    // Set up the camera view.
//                self.setupCameraView()
            } else {
                    // Print the error.
                NSLog("Error starting RPScreenRecorder")

                    // Set the recording state.
                self.setRecordingState(active: false)
            }
        }
    }

    func stopRecording() {

        controlsWindow?.rootViewController?.dismiss(animated: false)
        controlsWindow = nil
        RPScreenRecorder.shared().stopRecording {
            preview, err in
            guard let preview = preview else { print("no preview window"); return }
                //update recording controls
            preview.previewControllerDelegate = self
            if UIDevice.current.userInterfaceIdiom == .phone {
                preview.modalPresentationStyle = .popover
                preview.preferredContentSize = CGSize(width: (self.view.frame.width * 0.75), height: 350.0)
              // specify anchor point?
              guard let popOverPresenter = preview.popoverPresentationController
              else { return }
              let sheet = popOverPresenter.adaptiveSheetPresentationController //adaptiveSheetPresentationController

              sheet.detents = [.medium(), .large()]
      //        sheet.prefersScrollingExpandsWhenScrolledToEdge = false
              sheet.prefersEdgeAttachedInCompactHeight = true
              sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true

              }
            if UIDevice.current.userInterfaceIdiom == .pad {
                preview.modalPresentationStyle = .popover
                preview.popoverPresentationController?.sourceItem = self.recordBtn
                // preview.popoverPresentationController?.sourceRect = .zero
                // preview.popoverPresentationController?.sourceView = self.view
            }
            else {
                preview.modalPresentationStyle = .automatic
            }
           // DispatchQueue.main.async {
                // tried using the dispatch for the self.present(preview) due to error
                //     "AX Lookup problem - errorCode:1,100 error:Permission denied portName:'com.apple.iphone.axserver'"
                //  stackOverflow discussion suggests it is a known bug that can be ignored

            self.present(preview, animated: true) {
                NSLog("Previw Controller is presented")
            }


        }
            //        self.saveToPhotos(tempURL: outputURL)
        self.setRecordingState(active: false)


    }

    func screenRecorder(
        _ screenRecorder: RPScreenRecorder,
        didStopRecordingWith previewViewController: RPPreviewViewController?,
        error: Error?
    ) {
        NSLog(" didStopRecordingWith ")
    }



    


    func setRecordingState(active: Bool) {
        DispatchQueue.main.async {
            if (PGLImageController.isActive) == true {
                    // Set the button title.
                NSLog("started recording")
                    //                self.recordButton.title = "Stop Recording"
            } else {
                    // Set the button title.
                NSLog("stopped recording")
                    //                self.recordButton.title = "Start Recording"
            }

                // Set the internal recording state.
            PGLImageController.isActive = active

                // Set the other buttons' isEnabled properties.
                //            self.captureButton.isEnabled = !active
                //            self.broadcastButton.isEnabled = !active
                //            self.clipButton.isEnabled = !active
        }
    }



// MARK: Camera
//    func setupCameraView() {
//        DispatchQueue.main.async {
//            // Validate that the camera preview view and camera are in an enabled state.
//
//
//            if (RPScreenRecorder.shared().cameraPreviewView != nil) && RPScreenRecorder.shared().isCameraEnabled {
//                // Set the camera view to the camera preview view of RPScreenRecorder.
//                guard let cameraView = RPScreenRecorder.shared().cameraPreviewView else {
//                    print("Unable to retrieve the cameraPreviewView from RPScreenRecorder. Returning.")
//                    return
//                }
//                // Set the frame and position to place the camera preview view.
//                cameraView.frame = CGRect(x: 0, y: self.view.frame.size.height - 100, width: 100, height: 100)
//                // Ensure that the view is layer-backed.
////                cameraView.wantsLayer = true
//                // Add the camera view as a subview to the main view.
//                self.view.addSubview(cameraView)
//
//                self.cameraView = cameraView
//            }
//        }
//    }

}




