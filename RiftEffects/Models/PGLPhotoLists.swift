//
//  PGLPhotoLists.swift
//  Glance
//
//  Created by Will on 8/5/19.
//  Copyright © 2019 Will Loew-Blosser. All rights reserved.
//

import Foundation
import Photos


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



