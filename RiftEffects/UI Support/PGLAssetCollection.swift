//
//  PGLUUIDAssetCollection.swift
//  Glance
//
//  Created by Will Loew-Blosser on 4/30/20.
//  Copyright © 2020 Will Loew-Blosser. All rights reserved.
//

import Photos

class PGLUUIDAssetCollection: Hashable {
    // allows for the same album to exist in multiple spots by
    // not using the localIdentifier.. rather a UUID for uniqueness
    var uuId = UUID()
    var assetCollection: PHAssetCollection?
    var collectionList: PHCollectionList?
    var childCollections = [PGLUUIDAssetCollection]()
    
    var indentLevel = 0
    var isExpanded = false
    var isSelected = false

    init?(_ phCollection: PHCollection?) {
        if phCollection == nil {return nil }

        // one of these typecasts must fail
        assetCollection = phCollection as? PHAssetCollection
        collectionList = phCollection as? PHCollectionList
        if (assetCollection == nil) && (collectionList == nil) {
            return nil //nothing worked hmm
        }
    }

    func setIsExpanded(newValue: Bool) {
        isExpanded = newValue

    }

    func clone() -> PGLUUIDAssetCollection {
        // newbie with different UUID but same values
        // not used after fix to expandQuery(fromCollectionListItem: PGLUUIDAssetCollection)
        var newbie: PGLUUIDAssetCollection
        if self.isCollectionList() {
            newbie = PGLUUIDAssetCollection(self.collectionList)!
            newbie.childCollections = self.childCollections
        } else {
            newbie = PGLUUIDAssetCollection(self.assetCollection)!
            // assetCollection does not have childern
        }

        newbie.indentLevel = self.indentLevel
        newbie.isExpanded = self.isExpanded
        // isHightlighted is NOT cloned.. inits to false
        return newbie // has new UUID
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(uuId)
    }

     static func == (lhs: PGLUUIDAssetCollection, rhs: PGLUUIDAssetCollection) -> Bool {
               return lhs.uuId == rhs.uuId
           }

    func getCollection() -> PHCollection {
        var answer: PHCollection
        if assetCollection != nil {
            answer = assetCollection!
        } else {
            answer = collectionList!
        }
        return answer
    }

    func isCollectionList() -> Bool {
        if  (collectionList == nil)
            { return false}
        else {
            if (assetCollection == nil) { // other var must be nil..
            return true   }
        }
        return false // both vars are nil -- how?

    }

    func albumIdentifier() -> String? {
        if isCollectionList() {
            return collectionList?.localIdentifier
        } else {
            return assetCollection?.localIdentifier
        }
    }
    
    func contains(_ filter: String?) -> Bool {
        guard let filterText = filter else { return true }
        if filterText.isEmpty { return true }
        let lowercasedFilter = filterText.lowercased()
        if let assetTitle = assetCollection?.localizedTitle ?? collectionList?.localizedTitle
            {
                return assetTitle.lowercased().contains(lowercasedFilter)
            }
            else { return true }
    }
}
