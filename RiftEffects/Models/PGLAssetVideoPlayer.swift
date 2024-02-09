//
//  PGLAssetVideoPlayer.swift
//  RiftEffects
//
//  Created by Will on 2/9/24.
//  Copyright © 2024 Will Loew-Blosser. All rights reserved.
//

import Foundation   

import UIKit
import Photos
import CoreImage
import os

let PGLVideoAnimationToggle = NSNotification.Name(rawValue: "PGLVideoAnimationToggle")
let PGLVideoLoaded = NSNotification.Name(rawValue: "PGLVideoLoaded")
let PGLVideoReadyToPlay = NSNotification.Name(rawValue: "PGLVideoReadyToPlay")
let PGLPlayVideo =  NSNotification.Name(rawValue: "PGLPlayVideo")
let PGLVideoRunning = NSNotification.Name(rawValue: "PGLVideoRunning")
let PGLStopVideo = NSNotification.Name(rawValue: "PGLStopVideo")

enum VideoSourceState: Int {
    case None
    case Ready
    case Running
    case Pause

}


class PGLAssetVideoPlayer {

    var parentAsset: PGLAsset

    init(parentAsset: PGLAsset) {
        self.parentAsset = parentAsset
        
    }

    var videoLocalURL: URL?
    var videoPlayer: AVQueuePlayer? // subclass of AVPlayer
    var avPlayerItem: AVPlayerItem!

    var playerLooper: AVPlayerLooper?
        /// current video frame from the displayLinkCopyPixelBuffer
    var videoCIFrame: CIImage?
    var statusObserver: NSKeyValueObservation?

    var playVideoToken: NSObjectProtocol?
    var stopVideoToken: NSObjectProtocol?

    var imageOrientation = PGLDevicePosition()
    lazy var videoPropertyOrientation =  propertyOrientation()


// MARK: Create/Release

    func releaseVars() {

        if playVideoToken != nil {
            NotificationCenter.default.removeObserver(playVideoToken!)
        }
        if stopVideoToken != nil {
            NotificationCenter.default.removeObserver(stopVideoToken!)
        }
        if videoPlayer != nil {
            NSLog("PGLAssetVideoPlayer releaseVars video")

            videoPlayer!.pause()
            playerLooper?.disableLooping()
            playerLooper = nil
            videoPlayer!.removeAllItems() // should stop all playback
            videoPlayer = nil
            if statusObserver != nil {
                statusObserver?.invalidate()
                statusObserver = nil
            }
            avPlayerItem = nil
            videoCIFrame = nil
        }
        if videoLocalURL != nil {
            try? FileManager.default.removeItem(at: videoLocalURL!)
            videoLocalURL = nil
        }
    }

//MARK: Setup
    func createAVPlayerOptions() -> PHVideoRequestOptions? {
        let videoColorProperties = [
            AVVideoColorPrimariesKey: AVVideoColorPrimaries_P3_D65,
            AVVideoTransferFunctionKey: AVVideoTransferFunction_Linear,
            AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_2020
        ]
        let outPutSettings = [
            AVVideoAllowWideColorKey: true,
            AVVideoColorPropertiesKey: videoColorProperties,
            kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_64RGBAHalf)
        ] as? PHVideoRequestOptions
        outPutSettings?.isNetworkAccessAllowed = true

        return outPutSettings

    }

    fileprivate func createPlayerItemVideoOutput() -> AVPlayerItemVideoOutput{
        /*
         A dictionary providing information about the status of the request. See Image Result Info Keys for possible keys and values
         */

        let videoColorProperties = [
            AVVideoColorPrimariesKey: AVVideoColorPrimaries_P3_D65,
            AVVideoTransferFunctionKey: AVVideoTransferFunction_Linear,
            AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_2020
        ]
        let outPutSettings = [
            AVVideoAllowWideColorKey: true,
            AVVideoColorPropertiesKey: videoColorProperties,
            kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_64RGBAHalf),
            kCVPixelBufferWidthKey as String: NSNumber(value: parentAsset.asset.pixelWidth),
            kCVPixelBufferHeightKey as String: NSNumber(value: parentAsset.asset.pixelHeight)
        ] as [String : Any]

        return AVPlayerItemVideoOutput(outputSettings: outPutSettings)
    }

    fileprivate func closeWaitingIndicator() {
        DispatchQueue.main.async {
            let myAppDelegate =  UIApplication.shared.delegate as! AppDelegate
            myAppDelegate.closeWaitingIndicator()
        }
    }
    
    func setUpVideoPlayAssets(videoURL: URL){
            // Create a display link
            // automaticallyLoadedAssetKeys - array
            // An NSArray of NSStrings, each representing a property key defined by
            //   AVAsset. See AVAsset.h for property keys, e.g. duration
        let myAppDelegate =  UIApplication.shared.delegate as! AppDelegate
        myAppDelegate.showWaiting()

        videoLocalURL = videoURL
        avPlayerItem = AVPlayerItem(url: videoURL)
        self.videoPlayer = AVQueuePlayer.init(items: [avPlayerItem])
        self.playerLooper = AVPlayerLooper(player: self.videoPlayer! , templateItem: avPlayerItem)
        self.getVideoPreferredTransform(callBack: { myDevice in
            self.imageOrientation = myDevice})
        statusObserver =  avPlayerItem!.observe(\.status,
                  options: [.new, .old],
                  changeHandler: { myPlayerItem, change in

                if myPlayerItem.status == .readyToPlay {
//                        NSLog("PGLAssetVideoPlayer createDisplayLink changeHandler = .readyToPlay")
                    for aRepeatingItem in self.videoPlayer!.items() {
                        aRepeatingItem.add( self.createPlayerItemVideoOutput() )
                    }
                        // move displayLink
                    self.setUpReadyToPlay()
                    self.closeWaitingIndicator()
                  }
            else { if myPlayerItem.status == .failed {
                    self.closeWaitingIndicator()
                        }
                    }
                 })
//        NSLog("PGLAssetVideoPlayer createDisplayLink statusObserver created")
    }

    func displayLinkCopyPixelBuffers()
       {
//           NSLog("PGLAssetVideoPlayer #displayLinkCopyPixelBuffers start")
               // really need to get the current item in the videoPlayer
               // ask for it's videoOutput
           guard let currentVideoOutputs = videoPlayer?.currentItem?.outputs
           else { return }

           guard let theVideoOutput = currentVideoOutputs.first as? AVPlayerItemVideoOutput
           else { return }

           let currentTime = theVideoOutput.itemTime(forHostTime: CACurrentMediaTime())

           if theVideoOutput.hasNewPixelBuffer(forItemTime: currentTime)
            {

             if let buffer  = theVideoOutput.copyPixelBuffer(forItemTime: currentTime,
                                                     itemTimeForDisplay: nil)
                 {
//                  NSLog("PGLAssetVideoPlayer #displayLinkCopyPixelBuffers videoOutput new buffer ")
                     ///cache the video frame for the next Renderer image request
                let sourceFrame = CIImage(cvPixelBuffer: buffer)

                 let neededTransform = sourceFrame.orientationTransform(for: videoPropertyOrientation)
                 videoCIFrame = sourceFrame.transformed(by: neededTransform)
//                     NSLog("PGLAssetVideoPlayer #displayLinkCopyPixelBuffers videoCIFrame set")

                }
         }
       }

    func getVideoPreferredTransform(callBack: @escaping (PGLDevicePosition) -> Void ) {

        Task {
            let devicePosition = await avPlayerItem.asset.videoOrientation()
            callBack(devicePosition)
        }
    }


        /// convert the UIDeviceOrientation to a CGImagePropertyOrientation
    func propertyOrientation()-> CGImagePropertyOrientation {
        var result = CGImagePropertyOrientation.up
            // default
        switch (imageOrientation.orientation, imageOrientation.device) {
            case (.unknown,.unspecified) :
                result = CGImagePropertyOrientation.up

            case (.portrait, .front) :
                result = CGImagePropertyOrientation.right
            case (.portraitUpsideDown, .front):
                result = CGImagePropertyOrientation.right
            case (.landscapeLeft, .front) :
                result = CGImagePropertyOrientation.up
            case (.landscapeRight, .front) :
                result = CGImagePropertyOrientation.up

            case (.portrait, .back) :
                result = CGImagePropertyOrientation.right
            case (.portraitUpsideDown, .back):
                result = CGImagePropertyOrientation.left
            case (.landscapeLeft, .back) :
                result = CGImagePropertyOrientation.down
            case (.landscapeRight, .back) :
                result = CGImagePropertyOrientation.up

            default:
                return result // default .up
        }
        return result
    }

    //MARK: Output Video
    func imageFrom() -> CIImage? {
        if videoPlayer != nil {
             if videoPlayer?.status ==  .readyToPlay  {
                    /// set the videoCIFrame from the pixelBuffer
                    displayLinkCopyPixelBuffers()
                }
        }
        return videoCIFrame


    }

    //MARK: Notifications

    func setUpReadyToPlay() {

        let center = NotificationCenter.default
        let mainQueue = OperationQueue.main

        // now listen for the play command
        playVideoToken = center.addObserver(
            forName: PGLPlayVideo,
            object: nil,
            queue: mainQueue) { notification in
//                NSLog("PGLAssetVideoPlayer setUpReadyToPlay notification PGLPlayVideo handler triggered")
                self.videoPlayer?.isMuted = false
                self.videoPlayer?.play()

                    self.notifyVideoStarted()
//                    NSLog("PGLAssetVideoPlayer setUpReadyToPlay  videoPlayer?.play")
            }

        postVideoLoaded()
            // center.removeObserver(observer)
        setupStopVideoListener()
    }

    func setupStopVideoListener() {
        let center = NotificationCenter.default
        let mainQueue = OperationQueue.main

        stopVideoToken = center.addObserver(
            forName: PGLStopVideo,
            object: nil,
            queue: mainQueue) { notification in
                self.videoPlayer?.pause()
                self.videoPlayer?.isMuted = true


                 // stop the triggers  -
//                NSLog("PGLAssetVideoPlayer setupStopVideoListener notification PGLStopVideo triggered")

            }
    }

    func notifyVideoStarted() {

        let runningNotification = Notification(name:PGLVideoRunning)
        NotificationCenter.default.post(name: runningNotification.name, object: self, userInfo: [ : ])
        NSLog("PGLAssetVideoPlayer notify PGLVideoRunning sent")

    }
    
        ///  notify the imageController to show the play  button.
    func postVideoLoaded() {

        let updateNotification = Notification(name:PGLVideoAnimationToggle)
        NotificationCenter.default.post(name: updateNotification.name, object: self, userInfo: ["VideoImageSource" : +1 ])

        // imageController needs to show the play button
//        NSLog("PGLAssetVideoPlayer notify PGLVideoLoaded")
        let loadButtonNotification = Notification(name:PGLVideoLoaded)
        NotificationCenter.default.post(name: loadButtonNotification.name, object: self, userInfo: [ : ])

    }


}
