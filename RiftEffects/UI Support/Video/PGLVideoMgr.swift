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
//        {
//            didSet {
//                NSLog("PGLVideoMgr videoState old \(oldValue) now \(videoState)")
//            }
//        }

    func resetVars() {
        for anAsset in videoAssets {
            removeVideoAsset(oldVideo: anAsset)
        }
        videoAssets =  Set<PGLAssetVideoPlayer>()
        for (aPGLImageController, aButton) in startStopButtons {
            aPGLImageController.removeVideoControl(aVideoButton: aButton)
        }
        startStopButtons =  [PGLImageController : UIButton]()

        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.closeWaitingIndicator()
        }
    }

    func videoExists() -> Bool {
        return !videoAssets.isEmpty
    }

    func addVideoAsset(newVideo: PGLAssetVideoPlayer) {
        let (isNewSetMember, _ ) = videoAssets.insert(newVideo)
        if isNewSetMember {newVideo.videoMgr = self }

    }

    func stopForLoad() {
        // if videos are running stop until new video
        // adds the video btn and user clicks play
        // then all players will be in sync of same state
        // assumes new video is not yet in the
        // videoAssets
        // caller removed.. does not affect the common start stop for a 2nd video
        // see AppStack.setUpVideoPlayer caller
        for aVideoAsset  in videoAssets {
            if let thePlayer = aVideoAsset.videoPlayer {
                thePlayer.pause()
                thePlayer.isMuted = true
            }
        }
        setStartStop(newState: .Pause)

    }

    func removeVideoAsset(oldVideo: PGLAssetVideoPlayer) {
        videoAssets.remove(oldVideo)
        oldVideo.videoMgr = nil
        //startStopButtons not removed here.. controller
        // may have multiple videoAssets

        if videoAssets.isEmpty {
            // remove all startStopButtons
            for (aController, button) in startStopButtons {

                aController.removeVideoControl(aVideoButton: button)
                videoState = .None
                aController.view.setNeedsDisplay()
                
            }
            startStopButtons =  [PGLImageController : UIButton]()
            videoState = .None
        }
    }

    func addStartStopButton(imageController: PGLImageController) {
//        videoState = .Ready
        if startStopButtons[imageController] == nil {
            let newButton = imageController.addVideoControls()
            startStopButtons[imageController] = newButton
        }

        setVideoBtnIsHidden(hide: hideBtnState())
    }

    func setStartStop(newState: VideoSourceState) {
        videoState = newState
        setVideoBtnIsHidden(hide: hideBtnState())
    }

    func hideBtnState() -> Bool {
        var newHideState: Bool!
        switch videoState {
            case .None:
                newHideState = true
            case .Pause:
                newHideState = false
            case .Ready:
                newHideState = false
            case .Running:
                newHideState = true
//            default:
//                newHideState = false
        }
        return newHideState
    }
    func setVideoBtnIsHidden(hide: Bool){
        for (_, videoBtn ) in startStopButtons {
            videoBtn.isHidden = hide
            videoBtn.setNeedsDisplay()
//            imageController needs update event?
        }
    }
}
