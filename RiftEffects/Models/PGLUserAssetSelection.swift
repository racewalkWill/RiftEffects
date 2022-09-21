//
//  PGLUserAssetSelection.swift
//  Glance
//
//  Created by Will on 3/2/20.
//  Copyright © 2020 Will Loew-Blosser. All rights reserved.
//

import Foundation
import Photos
import os

let PGLAlbumErrorString = "Album Error"

class PGLAlbumSource: Hashable {
    var sectionSource: PHAssetCollection?
    var  assetFetch:  PHFetchResult<PHAsset>?
    var identifier: String
    var filterParm: PGLFilterAttribute?

    lazy var albumTitle = sectionSource?.localizedTitle

    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }

    static func == (lhs: PGLAlbumSource, rhs: PGLAlbumSource) -> Bool {
                 return lhs.identifier == rhs.identifier
             }

    convenience init(targetAttribute: PGLFilterAttribute, _ assetAlbum: PHAssetCollection, _ result: PHFetchResult<PHAsset>? ) {
        self.init(forAttribute: targetAttribute )
        sectionSource = assetAlbum
        assetFetch = result
        identifier = assetAlbum.localIdentifier
    }

    init(forAttribute: PGLFilterAttribute) {
        // empty nil vars are
        //  sectionSource & assetFetch
        filterParm = forAttribute
        identifier = PGLAlbumErrorString

    }

    func assets() -> [PGLAsset]? {
        if let mySectionSource = sectionSource {
            let convertedAssets = assetFetch?.objects.map( {
                PGLAsset(sourceAsset: $0, sourceCollection: mySectionSource)
            })
            return convertedAssets
        } else {
            assetFetch = nil // on error  clean up vars
            identifier = PGLAlbumErrorString
            sectionSource = nil
            return nil // explict nil return
        }

        }

    fileprivate func errorCleanup()  {
            // error do cleanup
            // caller answers nil
        assetFetch = nil // on error  clean up vars
        identifier = PGLAlbumErrorString
        sectionSource = nil

    }

    fileprivate func asset(position: Int) -> PGLAsset? {
         // why not return an array of PGLAsset for the PGLAssetController??
       if position < assetFetch?.count ?? 0 {
           // fix for rangeException in production version 2.1

           if let theAsset = assetFetch?.object(at: position) {
               let  newPGLAsset = PGLAsset(theAsset, collectionId: identifier, collectionLocalTitle: albumTitle)
               return newPGLAsset
           }
           else { errorCleanup()
                   return nil}
       }
        else { errorCleanup()
                return nil}
        }
    
    func fetchCount() -> Int {
        return assetFetch?.count ?? 0
    }

}

class PGLUserAssetSelection {
    // model object for 3 view controllers to select and order the
    // imageAssets from the photoLibrary
    // 3/2/2020 replaces the array userAssetCollection and supporting vars
    // answer array of all the assetSourceCollections in the assets.

   var myTargetFilterAttribute: PGLFilterAttribute?  // model object
   {
    didSet{
        // keep sections in sync.. the the PGLAlbumSource has a filter parm reference
        resetSections()
        // this will regen the sections to the new filterParm
    }
   }
     var selectedAssets = [PGLAsset]()  // [PHAsset]()  // replaces userAssetCollection array
     var sections = [String: PGLAlbumSource ]() // Dict key is album localIdentifier
    var lastTouchedAssetIndex = 0 // the last touched asset


    init( assetSources: PGLAlbumSource ) {
        myTargetFilterAttribute = assetSources.filterParm

        let sectionKey = assetSources.identifier
        sections[sectionKey] = assetSources


    }

    func releaseVars() {
        myTargetFilterAttribute = nil

    }
    deinit {
        Logger(subsystem: LogSubsystem, category: LogMemoryRelease).info("\( String(describing: self) + " - deinit" )")
    }


    func resetSections() {
        // when the filter changes then the cached attribute filterParm
        // in PGLAlbumSource needs to be updated

        for aSection in sections {
            aSection.value.filterParm = myTargetFilterAttribute!
        }
    }

    func isTransitionFilter() -> Bool {
        // answer true if the filter is in the "CICategoryTransition" category
        return myTargetFilterAttribute?.isTransitionFilter ?? false
    }
    // MARK: Changing
    func merge(newAssetSource: PGLUserAssetSelection) -> PGLAlbumSource? {
         // KEEP the current selectedAssets - new source may be added to exising selectedAssets
        // transfer incoming new Source into the existing user selection
        // assumes that the other controllers are pointing to this instance

        // if the same album is touched twice.. don't append


        guard let newSource = newAssetSource.sections.first
            else { return nil }
        let newSectionKey = newSource.value.identifier
        // from the PGLAlbumSource object
        let newSection = newSource.value

        Logger(subsystem: LogSubsystem, category: LogCategory).debug("PGLUserAssetSelection #merge key = \(newSectionKey)")


        sections[newSectionKey ] = newSection

        return newSection
        // is this released?
        // does it cause the controller to not be released?
//        let changeAlbumNotification = Notification(name:PGLImageAlbumAdded)
//        NotificationCenter.default.post(name: changeAlbumNotification.name, object: nil, userInfo: ["newSource": newSource as Any])

    }

    func cloneOdd(toParm: PGLFilterAttribute) -> PGLUserAssetSelection? {
        // copy just the even elements of the selectedAssets
        var newbie: PGLUserAssetSelection?

        var oddAssets = [PGLAsset]()

        Logger(subsystem: LogSubsystem, category: LogCategory).debug("PGLUserAssetSelection #cloneOdd")
        for (i,a) in selectedAssets.enumerated() {
            Logger(subsystem: LogSubsystem, category: LogCategory).debug("PGLUserAssetSelection #cloneOdd i = \(i)")
            if !i.isEven() { oddAssets.append(a)}
        }
        if let firstSource = oddAssets.first {
            let firstAlbumSource = sections[(firstSource.albumId)]
            // then populate the matching albums and fetch results to the newbie
            newbie = PGLUserAssetSelection(assetSources: (firstAlbumSource)! )
            if newbie == nil  { return nil }
            newbie?.append(firstSource)
            for nextOdd in oddAssets.suffix(from: 1) {
                newbie?.appendAssetAlbum(nextOdd, from: self)
            }
        }

        // remove  odd elements from self selectedAssets
        if let selectedOdd = newbie?.selectedAssets {
        for anOdd in selectedOdd {
            self.remove(anOdd)
            }
        }
        newbie?.myTargetFilterAttribute = toParm

        return newbie
    }

    func cloneAll(toParm: PGLFilterAttribute) -> PGLUserAssetSelection? {
        // copy all the elements of the selectedAssets
        var newbie: PGLUserAssetSelection?

        var allAssets = [PGLAsset]()


        for (_ ,a) in selectedAssets.enumerated() {
            allAssets.append(a) 
        }
        if let firstSource = allAssets.first {
            let firstAlbumSource = sections[(firstSource.albumId)]
            // then populate the matching albums and fetch results to the newbie
            newbie = PGLUserAssetSelection(assetSources: (firstAlbumSource)! )
            if newbie == nil  { return nil }
            newbie?.append(firstSource)
            for next in allAssets.suffix(from: 1) {
                newbie?.appendAssetAlbum(next, from: self)
            }
        }

    
        newbie?.myTargetFilterAttribute = toParm

        return newbie
    }


    func append(_ userAsset: PGLAsset) {
        if !isTransitionFilter() {
            // remove the old selected asset before adding the new on
            // only filters that can transition images can have multiple in the selection
            if let currentAsset = selectedAssets.first {
                remove(currentAsset)
            }
        }
        if userAsset.isNull() { return }
        selectedAssets.append(userAsset)

        let newAlbumId = userAsset.albumId

        if sections[newAlbumId] == nil {
                                 // add the album and the fetchResult
                                // add assetSourceCollection & fetchResult
            self.sections[newAlbumId] = userAsset.asPGLAlbumSource(onAttribute:myTargetFilterAttribute!)
                }
     }



    func appendAssetAlbum(_ userAsset: PGLAsset, from: PGLUserAssetSelection?) {

         selectedAssets.append(userAsset)
            // adds to the selection even if album source is missing

//        guard let newAlbumId = userAsset.albumId , let sourceAlbumTitle = userAsset.collectionTitle
//            else { return }
        let newAlbumId = userAsset.albumId


        // add to the album, sections, sectionTitles if the album is
        // not in the object yet

         if sections[newAlbumId] == nil {
                           // add the album and the fetchResult
                          // add assetSourceCollection & fetchResult
            if let oldSection = from?.sections[newAlbumId] {
            self.sections[newAlbumId] = oldSection
            } else
             {   let aEmptySourceFetch = PGLAlbumSource(targetAttribute: myTargetFilterAttribute!, userAsset.sourceInfo!, nil)
                self.sections[newAlbumId] = aEmptySourceFetch }
//            self.sectionTitle.append((title: (userAsset.collectionTitle), albumId: newAlbumId))
            }

    }




    func addSourceToSelection(asset: PGLAsset) {
            append(asset)
        }


    func remove(_ userAsset: PGLAsset) {
        // answer false if the assets is not found
        // answer true if found and removed

        if let assetIndex = selectedAssets.firstIndex(of: userAsset){
//            NSLog("PGLUserAssetSelection removing at index = \(assetIndex)")
            selectedAssets.remove(at: assetIndex)
//            NSLog("PGLUserAssetSelection count =  \(selectedAssets.count)")
//            lastTouchedAssetIndex = indexOf(source: userAsset)
        }

    }

    func removeSourceFromSelection(aPGLAsset: PGLAsset) {
        let selectedId = aPGLAsset.localIdentifier
        selectedAssets.removeAll(where: {$0.asset.localIdentifier == selectedId})
        }


    func moveItemAt(_ itemIndex: Int, toIndex: Int) {
        // change the order of the assets
        var item: PGLAsset
        guard (itemIndex <= selectedAssets.count ) else
            {return} // out of range do nothing
        guard (toIndex <= selectedAssets.count - 1) else
            {return} // out of range do nothing

        if itemIndex == selectedAssets.count - 1
            // last element
             { item = selectedAssets.removeLast() }
        else
            { item = selectedAssets.remove(at: itemIndex) }
        selectedAssets.insert(item, at: toIndex)

    }

    func removeAll() {
        selectedAssets = [PGLAsset]()
        lastTouchedAssetIndex = 0
    }

    func addAll() {
        var newPGLAsset: PGLAsset
        var albumAssets: [PHAsset]

        removeAll() // empty first
        for (_, albumSource ) in sections {

        albumAssets = albumSource.assetFetch?.objects ?? [PHAsset]()
            for anAsset in albumAssets {
                newPGLAsset = PGLAsset(anAsset, collectionId: albumSource.identifier, collectionLocalTitle: albumSource.albumTitle)
                append(newPGLAsset)
                }
        }


    }


// MARK: Accessors

    func asset(position:Int, albumId: String?) -> PGLAsset? {
        // nil albumId indicates the selectedAssets collection
        // otherwise the PGLAlbumSource collection with that albumId
        if albumId == nil  {
            if (selectedAssets.count > 0) && (position < selectedAssets.count) {
                    return selectedAssets[position] }
            else { return nil }
        } else {
            let thisSource = sections[albumId!]
            return thisSource?.asset(position: position)
        }
    }

    func fetchCount(albumId: String?) -> Int {
        // if albumId nil then count the selectedAssets collection
        if albumId == nil {
            return selectedAssets.count
        } else {
            return sections[albumId!]?.fetchCount() ?? 0
        }
    }

    func getAlbumAssets(albumId: String) -> [PHAsset]  {
        let albumFetch = sections[albumId]?.assetFetch
//        NSLog("PGLUserAssetSelection #getAlbumAssets albumId = \(albumId)")
//        NSLog("PGLUserAssetSelection #getAlbumAssets albumFetch = \(albumFetch)")
        return albumFetch?.objects ?? [PHAsset]()
    }


    func getSourceItem(atIndex: Int) -> PGLAsset? {
        if (atIndex < selectedAssets.count)
        {return selectedAssets[atIndex] }
        else { return nil }
    }



    func contains(localIdentifier: String) -> Bool {
        return selectedAssets.contains{ localIdentifier == $0.localIdentifier }
    }

    func sectionAlbumIdentifiers() -> [String] {
        // answer array of the identifiers of the sections
        // which is the keys of the section dictionary

        return sections.keys.map({$0})
            // the map makes the type of the return as [String]

    }

    // MARK: State

    func isEmpty() -> Bool {
        return selectedAssets.isEmpty
    }

    func isFetchEmpty() -> Bool {
        return fetchCount() < 1
    }

    func isFetchMultiple() -> Bool {
        // answer true if there is more than one in the sections
        // turns on or off the navigation buttons
        var totalFetchCount = 0
        for anAlbumId in sections.keys {
            let thisFetchCount =  fetchCount(albumId: anAlbumId)
            totalFetchCount = totalFetchCount + thisFetchCount
            if totalFetchCount > 1 {
                return true
            }
        }
        return false // did not find more than one image

    }

    func fetchCount() -> Int {
        return selectedAssets.count
    }

    func lastTouchedAsset() -> PGLAsset {
        return selectedAssets[ lastTouchedAssetIndex]
    }

// MARK: titles
    func parmInputName() -> String {
        // answer filter name and parm name
         let filterName = myTargetFilterAttribute?.aSourceFilter.descriptorDisplayName ?? ""
         let thisParmTitle = filterName + " " + ( myTargetFilterAttribute?.descriptiveNameDetail() ?? "")
         return thisParmTitle
    }

    func headerTitle(albumId: String?) -> String {
        // if albumId is nil then answer the parmInputName
        // otherwise the album localTitle
        if albumId == nil {
            return parmInputName()
        } else {
            return sections[albumId!]?.albumTitle ?? ""
        }

    }

    //MARK: output selection
    func setUserPick() {
        // modified from the PGLAssetGridController #setUserPick
        // put the selected assets into the targetFilterAttribute
         let imagesPicked = PGLImageList()

        // this needs the album source in the imageList.. album.localIdentifier & localizedTitle?

        if !self.isEmpty() {
              imagesPicked.imageAssets = selectedAssets
              imagesPicked.collectionTitle = selectedAssets.first?.collectionTitle ?? "untitled"
                // need to change in PGLImageList... more than one albumTitle
              imagesPicked.userSelection = self
              self.myTargetFilterAttribute?.setImageCollectionInput(cycleStack: imagesPicked)
            if let imageAttribute = myTargetFilterAttribute as? PGLFilterAttributeImage {
                imageAttribute.hasFilterInput = false
            }

            removeUnusedAlbums()
        }
        else {
            // empty images list
            self.myTargetFilterAttribute?.setImageParmState(newState: ImageParm.missingInput)
        }
    }

    func changeTarget(filter: PGLSourceFilter) {
        // user has changed the filter..
        // and this controller is still loaded in memory
        // update the userAssetSelection to use the new parm of the same name
        // this instance of PGLUserAssetSelection is shared by the SequenceController and the AssetGridController..
        
        if let parmName = myTargetFilterAttribute?.attributeName {
            // pick matching parm of new target filter
            if let newParm = filter.attribute(nameKey: parmName) {
                myTargetFilterAttribute = newParm
            }
        }
    }

    func removeUnusedAlbums(){
        // after user selected albums are loaded into the filter parm
        // remove albums without a selection - clean up time

        var albumSet = Set<String>()
        var removeAlbums = [String]()
        for anAsset in selectedAssets {
            albumSet.insert(anAsset.albumId)
        }

        for aSection in sections {
            // iterate all sections before doing remove
            if !(albumSet.contains(  aSection.key)) {
                // the albumId is not in the albumSet so add to remove list

                removeAlbums.append(aSection.key)
            }
        }

        for anAlbumKey in removeAlbums {
            sections.removeValue(forKey: anAlbumKey)
        }

    }

    func hasSelectedAssetOfAlbum(targetAlbum:String) -> Bool {
        // true if the albumId is in the userSelection
        let assetAlbums =  selectedAssets.map( {$0.albumId})
        return assetAlbums.contains(targetAlbum)
    }
    func removeAlbum(albumId: String) -> PGLAlbumSource? {
        // remove albumId from the sections
        if !hasSelectedAssetOfAlbum(targetAlbum: albumId) {
           return sections.removeValue(forKey: albumId)

        } else { return nil }
    }
}

