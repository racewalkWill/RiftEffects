//
//  PGLPhotoLists.swift
//  Glance
//
//  Created by Will on 8/5/19.
//  Copyright © 2019 Will Loew-Blosser. All rights reserved.
//

import Foundation
import Photos

//class PGLCollectionList {
//    // wrapper class for the three types of photo collections
//    // PHCollection, PHCollectionList, PHAssetCollection
//    // hide generic issues with use of the three inside this class
//    // PGLImageCollectionMasterController  use this wrapper
//
//    var listClass = PHCollection.self
//    // let localIdentifier: String? each type has the localIdentifier var
//    var collectionCount: Int = 0
//    var myFetchResult: PHFetchResult
//
////    var assetCollection: PHAssetCollection? // images, videos and Live Photos
////    var userCollection: PHCollection?       // Albums or Moments But this is abstract superclass??
////    var listCollection: PHCollectionList?  // albumFolders or MomentClusters
//        // class func fetchCollectionLists(with
////                            collectionListType: PHCollectionListType,
////                            subtype: PHCollectionListSubtype,
////                            options: PHFetchOptions?) -> PHFetchResult<PHCollectionList>
//        // FetchResult implements count
//         //   PHCollectionListType
//        //    case momentList
//        //    A group of asset collections of type PHAssetCollectionType.moment.
//        //    case folder
//        //    A folder containing asset collections of type PHAssetCollectionType.album or PHAssetCollectionType.smartAlbum.
//        //    case smartFolder
//        //    A smart folder synced to the device from .
//
//        //PHCollectionListSubtype
//        //    case momentListCluster
//        //    The collection list is a moment cluster, grouping several related moments.
//        //    case momentListYear
//        //    The collection list is a moment year, grouping all moments from one or more calendar years.
//        //    case regularFolder
//        //    The collection list is a folder containing albums or other folders.
//        //    case smartFolderEvents
//        //    The collection list is a smart folder containing one or more Events synced from iPhoto.
//        //    case smartFolderFaces
//        //    The collection list is a smart folder containing one or more Faces synced from iPhoto.
//        //    case any
//        //    Use this value to fetch collection lists of all possible subtypes.
//        //
//
//    // public
//    func countContentRows() -> Int {
//        // count
//         return  myFetchResult.count
//    }
//
//    func object(at: Int) -> AnyClass? {
//
//        }
//
//
//
////
////    func setList(onClass<PHCollection>: PHClass, list: PHFetchResult) {
////        switch onClass {
////        case is PHAssetCollection:
////            assetCollection = list as! PHAssetCollection
////            userCollection = nil
////            listCollection = nil
////        case is PHCollection:
////            assetCollection = nil
////            userCollection = list as! PHCollection
////            listCollection = nil
////        case is PHCollectionList:
////            assetCollection = nil
////            userCollection = nil
////            listCollection = list as! PHCollectionList
////        default:
////            fatalError("PGLPhotoList set to unknown collection type")
////        }
////    }
//    }
//
//}

// extensions of PHFetchResult
    // StackOverflow has discussion on the non array behavior of photoKit
//    https://stackoverflow.com/questions/49522436/phfetchresult-extension-that-uses-its-generic-objecttype

extension PHFetchResult where ObjectType == PHAsset {
    var objects: [ObjectType] {
        var _objects: [ObjectType] = []
        enumerateObjects { (object, _, _) in
            _objects.append(object)
        }
        return _objects
    }
}
extension PHFetchResult where ObjectType == PHCollection {
    var objects: [ObjectType] {
        var _objects: [ObjectType] = []
        enumerateObjects { (object, _, _) in
            _objects.append(object)
        }
        return _objects
    }
}
extension PHFetchResult where ObjectType == PHAssetCollection {
    var objects: [ObjectType] {
        var _objects: [ObjectType] = []
        enumerateObjects { (object, _, _) in
            _objects.append(object)
        }
        return _objects
    }
}



