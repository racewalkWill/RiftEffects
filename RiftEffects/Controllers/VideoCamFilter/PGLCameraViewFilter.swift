//
//  PGLCameraViewFilter.swift
//  RiftEffects
//
//  Created by Will on 12/7/23.
//  Copyright © 2023 Will Loew-Blosser. All rights reserved.
//  Based on the Apple sample App AVCamFilter
//      class CameraViewController.swift


import UIKit
import AVFoundation
import CoreVideo
import Photos
import MobileCoreServices

class PGLVideoCameraFilter: PGLSourceFilter {
     var cameraInterface: PGLCameraInterface?

    // MARK: - View Controller Life Cycle

    required init?(filter: String, position: PGLFilterCategoryIndex) {
        super .init(filter: filter, position: position)
        cameraInterface = PGLCameraInterface(myCameraViewFilter: self)
        cameraInterface?.setUpInterface()
    }


func viewWillDisappear(_ animated: Bool) {
    // MARK: Release
    // should be used in release chain.
    cameraInterface?.releaseOnViewDisappear()
    }

   override func releaseVars() {
        cameraInterface?.releaseOnViewDisappear()
        cameraInterface = nil
        super.releaseVars()

    }

}

