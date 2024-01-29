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
    var videoImageFrame: CIImage?

    // MARK: - View Controller Life Cycle

    required init?(filter: String, position: PGLFilterCategoryIndex) {
        super .init(filter: filter, position: position)
        cameraInterface = PGLCameraInterface(myCameraViewFilter: self)
        cameraInterface?.setUpInterface()
        postTransitionFilterAdd()
    }

    override func outputImage() -> CIImage? {
        let orientedTarget: CGImagePropertyOrientation
            /// orientation is set once. It does not change with device rotation..
            /// if needed?? see comment in statusBarOrientation
        switch cameraInterface?.statusBarOrientation {
                
            case .landscapeRight:
                orientedTarget = .downMirrored
            default:
                orientedTarget = .upMirrored
            // other cases but .up works for all these as
                // app is landscape right or left only..
//            case .landscapeLeft:
//            case .none:
//            case .some(.unknown):
//            case .some(.portrait):
//            case .some(.portraitUpsideDown):
//            case .some(_):
        }
        return videoImageFrame?.oriented(orientedTarget)
    }

    func postTransitionFilterAdd() {
        let updateNotification = Notification(name:PGLTransitionFilterExists)
        NotificationCenter.default.post(name: updateNotification.name, object: nil, userInfo: ["transitionFilterAdd" : +1 ])
    }

    func postTransitionFilterRemove() {
        let updateNotification = Notification(name:PGLTransitionFilterExists)
        NotificationCenter.default.post(name: updateNotification.name, object: nil, userInfo: ["transitionFilterAdd" : -1 ])
    }

func viewWillDisappear(_ animated: Bool) {
    // MARK: Release
    // should be used in release chain.
    cameraInterface?.releaseOnViewDisappear()
    }


   override func releaseVars() {
        cameraInterface?.releaseOnViewDisappear()
        cameraInterface = nil
        postTransitionFilterRemove()
        super.releaseVars()

    }

}

