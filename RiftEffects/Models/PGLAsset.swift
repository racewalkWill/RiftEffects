//
//  PGLImageSourcePath.swift
//  Glance
//
//  Created by Will on 2/20/20.
//  Copyright © 2020 Will Loew-Blosser. All rights reserved.
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

struct PGLDevicePosition {
    var orientation: UIInterfaceOrientation = .unknown
    var device: AVCaptureDevice.Position = .unspecified
}

class PGLAsset: Hashable, Equatable  {
    // a wrapper object around PHAsset
       // holds the sourceInfo so it can be displayed
       // does this cause any caching memory problems??
       // because the assetCollection is held??
       // other option is to capture localIdentifier & title only
    var asset: PHAsset
    lazy var sourceInfo: PHAssetCollection? =
        { let fetchResult = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [albumId], options: nil)
            return fetchResult.firstObject
                // may be nil
        }()
           // remove this after albumId & album title are implemented

    var albumId: String  // must have an albumId
    var collectionTitle = String()
//       var hasDepthData = false  // set in PGLImageList #imageFrom(target)

    // Video
    var videoLocalURL: URL?
    var videoPlayer: AVQueuePlayer? // AVPlayer?
    var avPlayerItem: AVPlayerItem!

    var playerLooper: AVPlayerLooper?
    /// current video frame from the displayLinkCopyPixelBuffer
    var videoCIFrame: CIImage?
    var statusObserver: NSKeyValueObservation?

    var playVideoToken: NSObjectProtocol?
    var stopVideoToken: NSObjectProtocol?

    var imageOrientation = PGLDevicePosition()
    lazy var videoPropertyOrientation =  propertyOrientation()

    let options: PHImageRequestOptions?

    // MARK: Hash, Equatable
    static func == (lhs: PGLAsset, rhs: PGLAsset) -> Bool {
       return lhs.asset.localIdentifier == rhs.asset.localIdentifier
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(asset.localIdentifier)
    }


// MARK: init


    init(_ sourceAsset: PHAsset, collectionId: String?, collectionLocalTitle: String?) {
        if collectionId == nil
          {  albumId = "" }
        else { albumId = collectionId! }
        asset = sourceAsset

        // image mode
        options = PHImageRequestOptions()
        options?.deliveryMode = .highQualityFormat
        options?.isNetworkAccessAllowed = true
        options?.isSynchronous = true
        options?.version = .current
        options?.resizeMode = PHImageRequestOptionsResizeMode.exact
            // was .exact
            // app is resizing in other code

    }

    convenience init(sourceAsset: PHAsset, sourceCollection: PHAssetCollection) {
        self.init(sourceAsset, collectionId: sourceCollection.localIdentifier, collectionLocalTitle: sourceCollection.localizedTitle)
        sourceInfo = sourceCollection
    }

    convenience init(sourceAsset: PHAsset) {
        self.init(sourceAsset, collectionId: nil, collectionLocalTitle: nil)
    }

    func releaseVars() {

        sourceInfo = nil
        if playVideoToken != nil {
            NotificationCenter.default.removeObserver(playVideoToken!)
        }
        if stopVideoToken != nil {
            NotificationCenter.default.removeObserver(stopVideoToken!)
        }
        if videoPlayer != nil {
            NSLog("PGLAsset releaseVars video")

            videoPlayer!.pause()
            playerLooper?.disableLooping()
            playerLooper = nil 
            videoPlayer!.removeAllItems()
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
//            NSLog("PGLAsset releaseVars removedItem at \(String(describing: videoLocalURL))")
            videoLocalURL = nil
        }

    }

    var localIdentifier: String { get {
        return asset.localIdentifier
        }
    }

    func isNull() -> Bool {
        return  asset.localIdentifier.hasPrefix("(null)/")
            // "(null)/L0/001" is error string
    }

    func assetIdAlbumId() -> (assetId: String, albumId: String) {
        return (assetId: localIdentifier, albumId: albumId)
    }

    func getAssetFetchResult() -> PHFetchResult<PHAsset>? {
        if let theCollection = self.sourceInfo {
        let results = PHAsset.fetchAssets(in: theCollection, options: nil)
            // empty results if limited access
            return results }

        else { return nil }

    }

    func asPGLAlbumSource(onAttribute: PGLFilterAttribute) -> PGLAlbumSource {
        if let resultFetch = getAssetFetchResult()
        {
            if let mySourceInfo = sourceInfo {
                let newbie = PGLAlbumSource(targetAttribute: onAttribute, mySourceInfo, resultFetch)
                return newbie}
            else { // missing album source info
               let emptyAlbum = PGLAlbumSource(forAttribute: onAttribute)
                return emptyAlbum
            }
        } else { // missing resultFetch
            let emptyAlbum = PGLAlbumSource(forAttribute: onAttribute)
             return emptyAlbum
             }
    }

    // MARK: Image
    /// return the CIImage
    /// moved from the PGLImageList
    func imageFrom() -> CIImage? {
        if isVideo() {
            if videoPlayer != nil
                { if videoPlayer?.status ==  .readyToPlay  {
                    displayLinkCopyPixelBuffers()
                    return videoCIFrame
                    }
            } else {
                if videoCIFrame != nil {
                    return videoCIFrame
                }
            }
            /// continues to get the normal image while videoPlayer is setup
        }
          // READS the CIImage
       //            options = PHImageRequestOptions()
       //            options.deliveryMode = .highQualityFormat
       //            options.isNetworkAccessAllowed = true  download from the cloud
       //            options.isSynchronous = true

       //            For an asynchronous request, Photos may call your result handler block more than once.
       //            Photos first calls the block to provide a low-quality image suitable for displaying temporarily
       //             while it prepares a high-quality image. (If low-quality image data is immediately available, the first call may occur before the method returns.)
       //            When the high-quality image is ready, Photos calls your result handler again to provide it.
       //            If the image manager has already cached the requested image at full quality, Photos calls your result handler only once.
       //            The PHImageResultIsDegradedKey key in the result handler’s info parameter indicates when Photos is providing a temporary low-quality image.

          var pickedCIImage: CIImage?
//         let matchingSize = CGSize(width: selectedAsset.asset.pixelWidth, height: selectedAsset.asset.pixelHeight)
        // commented out pixelWidth is zero
           let matchingSize = TargetSize  //global

//         options.progressHandler = {  (progress, error, stop, info) in
//             NSLog("PGLImageList imageFrom: progressHandler  \(progress) info = \(String(describing: info))")
//            }

        if PrintDebugPhotoLocation {
            let thePHAsset = self.asset
            if let resource = PHAssetResource.assetResources(for: thePHAsset).first
            {
                NSLog("\(resource.originalFilename)  \(String(describing: thePHAsset.location))")
            }
        }

          PHImageManager.default().requestImage(for: self.asset, targetSize: matchingSize, contentMode: .aspectFit, options: options, resultHandler: { image, info in
              if let error =  info?[PHImageErrorKey]
               { NSLog( "PGLImageList imageFrom error = \(error)")
              }
              else {
               guard let theImage = image else { return  }
               pickedCIImage = self.convert2CIImage(aUIImage: theImage)
                  Logger(subsystem: LogSubsystem, category: LogCategory).debug("pickedCIImage \(pickedCIImage!.debugDescription)")
              }
           }
          )
        if isVideo() {
            /// cache the still image until user clicks play
            videoCIFrame = pickedCIImage
        }
        return pickedCIImage
               // may be nil if not set in the result handler block
      }

        /// convert UIImage to CIImage and correct orientation to downMirrored
        func convert2CIImage(aUIImage: UIImage) -> CIImage? {
            var pickedCIImage: CIImage?

            if let convertedImage = CoreImage.CIImage(image: aUIImage ) {

             let theOrientation = CGImagePropertyOrientation(aUIImage.imageOrientation)
             if PGLImageList.isDeviceASimulator() {
                     pickedCIImage = convertedImage.oriented(CGImagePropertyOrientation.downMirrored)
                 } else {
//                     NSLog("PGLAsset #convert2CIImage theOrientation = \(theOrientation)")
                     pickedCIImage = convertedImage.oriented(theOrientation) }
             }
            return pickedCIImage
        }


    //MARK: Video
    func isVideo() -> Bool {
        return asset.mediaType == .video
    }

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
            kCVPixelBufferWidthKey as String: NSNumber(value: asset.pixelWidth),
            kCVPixelBufferHeightKey as String: NSNumber(value: asset.pixelHeight)
        ] as [String : Any]
        
        return AVPlayerItemVideoOutput(outputSettings: outPutSettings)
    }
    
    /// PickerController calls from completion
    ///  handleCompletion(asset: PGLAsset, object: Any?, error: Error? = nil)
    func requestVideo() {

//        NSLog("PGLAsset #requestVideo requestPlayerItem")
        if videoLocalURL != nil {
            let myAppDelegate =  UIApplication.shared.delegate as! AppDelegate
            myAppDelegate.showWaiting()
            createDisplayLink()
        }
    }

    func createDisplayLink(){
            // Create a display link
            // automaticallyLoadedAssetKeys - array
            // An NSArray of NSStrings, each representing a property key defined by
            //   AVAsset. See AVAsset.h for property keys, e.g. duration
        avPlayerItem = AVPlayerItem(url: videoLocalURL!)
        self.videoPlayer = AVQueuePlayer.init(items: [avPlayerItem])
        self.playerLooper = AVPlayerLooper(player: self.videoPlayer! , templateItem: avPlayerItem)
        self.getVideoPreferredTransform(callBack: { myDevice in
            self.imageOrientation = myDevice})
        statusObserver =  avPlayerItem!.observe(\.status,
                  options: [.new, .old],
                  changeHandler: { myPlayerItem, change in

                if myPlayerItem.status == .readyToPlay {
//                        NSLog("PGLAsset createDisplayLink changeHandler = .readyToPlay")
                    for aRepeatingItem in self.videoPlayer!.items() {
                        aRepeatingItem.add( self.createPlayerItemVideoOutput() )
                    }
                        // move displayLink
                    self.setUpReadyToPlay()
                    DispatchQueue.main.async {
                            let myAppDelegate =  UIApplication.shared.delegate as! AppDelegate
                            myAppDelegate.closeWaitingIndicator()
                        }
                  }
                 })
//        NSLog("PGLAsset createDisplayLink statusObserver created")
    }

    func setUpReadyToPlay() {

        let center = NotificationCenter.default
        let mainQueue = OperationQueue.main

        // now listen for the play command
        playVideoToken = center.addObserver(
            forName: PGLPlayVideo,
            object: nil,
            queue: mainQueue) { notification in
//                NSLog("PGLAsset setUpReadyToPlay notification PGLPlayVideo handler triggered")

                self.videoPlayer?.play()
                    self.notifyVideoStarted()
//                    NSLog("PGLAsset setUpReadyToPlay  videoPlayer?.play")
            }

        postVideoLoaded()
            // center.removeObserver(observer)
        setupStopVideoListener()
    }

    func getVideoPreferredTransform(callBack: @escaping (PGLDevicePosition) -> Void ) {

        Task {
            let devicePosition = await avPlayerItem.asset.videoOrientation()
            callBack(devicePosition)
        }
    }

    func setupStopVideoListener() {
        let center = NotificationCenter.default
        let mainQueue = OperationQueue.main

        stopVideoToken = center.addObserver(
            forName: PGLStopVideo,
            object: nil,
            queue: mainQueue) { notification in
                self.videoPlayer?.pause()

                 // stop the triggers  -
//                NSLog("PGLAsset setupStopVideoListener notification PGLStopVideo triggered")

            }
    }

//    @objc func displayLinkCopyPixelBuffers(link: CADisplayLink)
    func displayLinkCopyPixelBuffers()
       {
//           NSLog("PGLAsset #displayLinkCopyPixelBuffers start")
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
//                  NSLog("PGLAsset #displayLinkCopyPixelBuffers videoOutput new buffer ")
                     ///cache the video frame for the next Renderer image request
                let sourceFrame = CIImage(cvPixelBuffer: buffer)

                 let neededTransform = sourceFrame.orientationTransform(for: videoPropertyOrientation)
                 videoCIFrame = sourceFrame.transformed(by: neededTransform)
//                     NSLog("PGLAsset #displayLinkCopyPixelBuffers videoCIFrame set")

                }
         }
       }

        /// convert the UIDeviceOrientation to a CGImagePropertyOrientation
    func propertyOrientation()-> CGImagePropertyOrientation {
        var result = CGImagePropertyOrientation.up
            // default
        switch imageOrientation.orientation {
            case .unknown:
                result = CGImagePropertyOrientation.up
            case .portrait , .portraitUpsideDown:
                result = CGImagePropertyOrientation.right
            case .landscapeLeft, .landscapeRight:
                result = CGImagePropertyOrientation.up

          
            default:
                return result // default .up
        }
        return result
    }
    func notifyVideoStarted() {

        let runningNotification = Notification(name:PGLVideoRunning)
        NotificationCenter.default.post(name: runningNotification.name, object: self, userInfo: [ : ])
        NSLog("PGLAsset notify PGLVideoRunning sent")

    }
        ///  notify the imageController to show the play  button.
    func postVideoLoaded() {

        let updateNotification = Notification(name:PGLVideoAnimationToggle)
        NotificationCenter.default.post(name: updateNotification.name, object: self, userInfo: ["VideoImageSource" : +1 ])

        // imageController needs to show the play button
//        NSLog("PGLAsset notify PGLVideoLoaded")
        let loadButtonNotification = Notification(name:PGLVideoLoaded)
        NotificationCenter.default.post(name: loadButtonNotification.name, object: self, userInfo: [ : ])

    }

}
