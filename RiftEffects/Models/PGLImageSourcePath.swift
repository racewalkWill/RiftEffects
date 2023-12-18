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
    var videoPlayer: AVPlayer?
    var avPlayerItem: AVPlayerItem?
    var playerItemVideoOutput: AVPlayerItemVideoOutput?
    /// current video frame from the displayLinkCopyPixelBuffer
    var videoCIFrame: CIImage?
    var statusObserver: NSKeyValueObservation?
    lazy var displayLink: CADisplayLink
                = CADisplayLink(target: self,
                    selector: #selector(displayLinkCopyPixelBuffers(link:)))

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
       
//        if collectionLocalTitle == nil {
//            collectionTitle = sourceInfo?.localizedTitle ?? "untitled"
//        }
//        else { collectionTitle = collectionLocalTitle!} // ?? "untitled"

        // image mode
        options = PHImageRequestOptions()
        options?.deliveryMode = .highQualityFormat
        options?.isNetworkAccessAllowed = true
        options?.isSynchronous = true
        options?.version = .current



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

    func setup() {

        if self.isVideo() {
                /// set the playerItem
            requestVideo()


            }
    }

    // MARK: Image
    /// return the CIImage
    /// moved from the PGLImageList
    func imageFrom() -> CIImage? {
        if isVideo() {
            if (videoPlayer == nil) {
                setup()
                // videoCIFrame will not immediately be available
                // some early nil returns to be expected.
            }
            return videoCIFrame
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
        options?.resizeMode = PHImageRequestOptionsResizeMode.fast
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

        return outPutSettings
//        // Create a player item video output
//        let videoPlayerItemOutput = AVPlayerItemVideoOutput(outputSettings: outputVideoSettings)
//        return videoPlayerItemOutput
    }

    func requestVideo() {
        /* resultHandler
         A block Photos calls after loading the asset’s data and preparing the player item.
         The block takes the following parameters:
         playerItem
         An AVPlayerItem object that you can use for playing back the video asset.
         info
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
            kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_64RGBAHalf)
        ] as [String : Any]
        
        playerItemVideoOutput = AVPlayerItemVideoOutput(outputSettings: outPutSettings)

        PHImageManager.default().requestPlayerItem(forVideo: asset, 
                                                   options: createAVPlayerOptions(),
                                                   resultHandler:
                                                    { aPlayer, info in
            if let error = info?[PHImageErrorKey] {
                NSLog( "PGLImageList imageFrom error = \(error)")
            } else {
                // connect the playerItem and the playerItemVideoOutput
//                aPlayer?.add( self.playerItemVideoOutput! )
                self.avPlayerItem = aPlayer
                self.videoPlayer = AVPlayer(playerItem: aPlayer)
                self.createDisplayLink()
//                self.postTransitionFilterAdd()
                    // how to turn off the transition state?
            }
        }
        )
    }

    func createDisplayLink(){
            // Create a display link


            statusObserver = avPlayerItem!.observe(\.status,
                  options: [.new, .old],
                  changeHandler: { playerItem, change in
                    if playerItem.status == .readyToPlay {
                        playerItem.add(self.playerItemVideoOutput!)
                        self.displayLink.add(to: .main, forMode: .common)
                        self.videoPlayer?.play()
                    }
                 })

    }

    @objc func displayLinkCopyPixelBuffers(link: CADisplayLink)
       {
           guard let currentTime = playerItemVideoOutput?.itemTime(forHostTime: CACurrentMediaTime())
           else { return }
           guard let myPlayerItem = playerItemVideoOutput else { return }
           if myPlayerItem.hasNewPixelBuffer(forItemTime: currentTime)
         {
             if let buffer
                    = myPlayerItem.copyPixelBuffer(forItemTime: currentTime,
                                                     itemTimeForDisplay: nil)
             {
                 ///cache the video frame for the next Renderer image request
                 videoCIFrame = CIImage(cvPixelBuffer: buffer)

            }
         }
       }

    func notifyVideoStart() {
        let notification = Notification(name: PGLVideoAnimationToggle)
    }

}
