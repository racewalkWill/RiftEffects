//
//  PGLImageSourcePath.swift
//  Glance
//
//  Created by Will on 2/20/20.
//  Copyright © 2020 Will Loew-Blosser. All rights reserved.
//

import Foundation
import Photos



class PGLAsset: Hashable, Equatable  {
    // a wrapper object around PHAsset
       // holds the sourceInfo so it can be displayed
       // does this cause any caching memory problems??
       // because the assetCollection is held??
       // other option is to capture localIdentifier & title only
    var asset: PHAsset
    lazy var sourceInfo: PHAssetCollection? =
        { let fetchResult = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [albumId], options: nil)
            return fetchResult.object(at: 0)
        }()
           // remove this after albumId & album title are implemented

       var albumId: String  // must have an albumId
       var collectionTitle = String()
//       var hasDepthData = false  // set in PGLImageList #imageFrom(target)

    // MARK: Hash, Equatable
    static func == (lhs: PGLAsset, rhs: PGLAsset) -> Bool {
       return lhs.asset.localIdentifier == rhs.asset.localIdentifier
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(asset.localIdentifier)
    }


// MARK: init


    init(_ sourceAsset: PHAsset, collectionId: String?, collectionLocalTitle: String?) {
        guard collectionId != nil
            else {
                NSLog ("PGLAsset init sourceAsset... fatalError(no collectionId has been set")
                asset = PHAsset()
                albumId = ""
                
                return
            
        }
        asset = sourceAsset
        albumId = collectionId!
        if collectionLocalTitle == nil {
            collectionTitle = sourceInfo?.localizedTitle ?? "untitled"
        }
        else { collectionTitle = collectionLocalTitle!} // ?? "untitled"

    }

    convenience init(sourceAsset: PHAsset, sourceCollection: PHAssetCollection) {
        self.init(sourceAsset, collectionId: sourceCollection.localIdentifier, collectionLocalTitle: sourceCollection.localizedTitle)
        sourceInfo = sourceCollection
    }

    var localIdentifier: String { get {
        return asset.localIdentifier
        }
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
        let resultFetch = getAssetFetchResult()
        let newbie = PGLAlbumSource(sourceInfo!, resultFetch)
        newbie.filterParm = onAttribute
        return newbie
    }
}
