//
//  PGLVideo.swift
//  RiftEffects
//
//  Created by Will on 10/20/23.
//  Copyright © 2023 Will Loew-Blosser. All rights reserved.
//  Based on code from ReplayKitSample app from Apple

import ReplayKit
import Photos
import os


extension PGLImageController {

    func recordButtonTapped() {
        if !RPScreenRecorder.shared().isAvailable {
            fatalError("RPScreenRecorder is NOT available")
        }
            // Check the internal recording state.
            if isActive == false {
                // If a recording isn't currently underway, start it.
                startRecording()
            } else {
                // If a recording is active, the button stops it.
                stopRecording()
            }

    }

    func startRecording() {
        RPScreenRecorder.shared().startRecording { error in
            // If there is an error, print it and set the button title and state.
            if error == nil {
                // There isn't an error and recording starts successfully. Set the recording state.
                self.setRecordingState(active: true)

                // Set up the camera view.
//                self.setupCameraView()
            } else {
                // Print the error.
                print("Error starting recording")

                // Set the recording state.
                self.setRecordingState(active: false)
            }
        }
    }

    func stopRecording() {
        let outputURL = getDirectory()
        RPScreenRecorder.shared().stopRecording(withOutput: outputURL)
        self.saveToPhotos(tempURL: outputURL)
        self.setRecordingState(active: false)


    }


    func setRecordingState(active: Bool) {
        DispatchQueue.main.async {
            if active == true {
                // Set the button title.
                print("started recording")
//                self.recordButton.title = "Stop Recording"
            } else {
                // Set the button title.
                print("stopped recording")
//                self.recordButton.title = "Start Recording"
            }

            // Set the internal recording state.
            self.isActive = active

            // Set the other buttons' isEnabled properties.
//            self.captureButton.isEnabled = !active
//            self.broadcastButton.isEnabled = !active
//            self.clipButton.isEnabled = !active
        }
    }

    func getDirectory() -> URL {
        var tempPath = URL(fileURLWithPath: NSTemporaryDirectory())
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-hh-mm-ss"
        let stringDate = formatter.string(from: Date())
        print(stringDate)
        tempPath.appendPathComponent(String.localizedStringWithFormat("output-%@.mp4", stringDate))
        return tempPath
    }

    func saveToPhotos(tempURL: URL?) {
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: tempURL!)
        } completionHandler: { success, error in
            DispatchQueue.main.async {
                try? FileManager.default.removeItem(at: tempURL!)

                if success == true {
                    Logger(subsystem: LogSubsystem, category: LogCategory).info("saveToPhotos video recording completed")
                } else {
                    Logger(subsystem: LogSubsystem, category: LogCategory).error("saveToPhotos video recording failed")
                }
                // temp checking code.. more cleanup needed?
//                let directory = FileManager.default.temporaryDirectory
//                let contentList = FileManager.default.contents(atPath: directory.absoluteString)

            }

        }
    }

    func exportClip() {
        let clipURL = getDirectory()
        let interval = TimeInterval(5)

        print("Generating clip at URL: ", clipURL)
        RPScreenRecorder.shared().exportClip(to: clipURL, duration: interval) { error in
            if error != nil {
                print("Error attempting to start Clip Buffering")
            } else {
                // There isn't an error, so save the clip at the URL to Photos.
                self.saveToPhotos(tempURL: clipURL)
            }
        }
    }


}






