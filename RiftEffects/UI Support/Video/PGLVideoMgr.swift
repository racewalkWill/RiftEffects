//
//  PGLVideoMgr.swift
//  RiftEffects
//
//  Created by Will on 2/22/24.
//  Copyright © 2024 Will Loew-Blosser. All rights reserved.
//

import Foundation
import UIKit

///  coordinate PGLAssetVideoPlayer and play control buttons in mulitple PGLImageControllers
///   a playButton starts/stopss all videos.
class PGLVideoMgr {
    var videoAssets =  Set<PGLAssetVideoPlayer>()
    var startStopButtons =  [PGLImageController : UIButton]()
    var videoState: VideoSourceState = .None
    
    func resetVars() {
        for anAsset in videoAssets {
            removeVideoAsset(oldVideo: anAsset)
        }
        videoAssets =  Set<PGLAssetVideoPlayer>()
        startStopButtons =  [PGLImageController : UIButton]()
    }

    func videoExists() -> Bool {
        return !videoAssets.isEmpty
    }

    func addVideoAsset(newVideo: PGLAssetVideoPlayer) {
        let (isNewSetMember, _ ) = videoAssets.insert(newVideo)
        if isNewSetMember {newVideo.videoMgr = self }

    }

    func removeVideoAsset(oldVideo: PGLAssetVideoPlayer) {
        videoAssets.remove(oldVideo)
        oldVideo.videoMgr = nil

        if videoAssets.isEmpty {
            // remove all startStopButtons
            for (aController, button) in startStopButtons {
                button.removeFromSuperview()
                videoState = .None
                // imageController
            }
            startStopButtons =  [PGLImageController : UIButton]()
        }
    }

    func addStartStopButton(imageController: PGLImageController) {
//        videoState = .Ready
        if startStopButtons[imageController] == nil {
            let newButton = imageController.addVideoControls()
            startStopButtons[imageController] = newButton
        }
    }

    func setVideoBtnIsHidden(hide: Bool){
        for (_, videoBtn ) in startStopButtons {
            videoBtn.isHidden = hide
//            imageController needs update event?
        }
    }
}
