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

    let options: PHImageRequestOptions?

    // video
    var assetVideo: PGLAssetVideoPlayer?

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
        assetVideo?.releaseVars()

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
            if assetVideo != nil {

                if let answerFrame = assetVideo?.imageFrom() {
                    return answerFrame
                } // else continue to read the PHImageManager still frame
            }

//            else {
//                assetVideo = PGLAssetVideoPlayer.init(parentAsset: self)
//                /// continues to get the normal image while videoPlayer is setup
//            }
        }

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
            /// see PHImageManager docs on callback behavior
          PHImageManager.default().requestImage(for: self.asset, targetSize: matchingSize, contentMode: .aspectFit, options: options, resultHandler: { image, info in
              if let error =  info?[PHImageErrorKey]
               { NSLog( "PGLImageList imageFrom error = \(error)")
              }
              else {
               guard let theImage = image else { return  }
               pickedCIImage = self.convert2CIImage(aUIImage: theImage)
//                  Logger(subsystem: LogSubsystem, category: LogCategory).debug("pickedCIImage \(pickedCIImage!.debugDescription)")
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
//                     NSLog("PGLAsset #convert2CIImage theOrientation = \(theOrientation)")
                     pickedCIImage = convertedImage.oriented(theOrientation) }
             }
            return pickedCIImage
        }


    //MARK: Video
    func isVideo() -> Bool {
        return asset.mediaType == .video
    }

    func requestVideo(videoURL: URL) {
        assetVideo = PGLAssetVideoPlayer(parentAsset: self)
        assetVideo?.setUpVideoPlayAssets(videoURL: videoURL)

    }

}
