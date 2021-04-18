//
//  PGLDemo.swift
//  Surreality
//
//  Created by Will on 1/23/21.
//  Copyright © 2021 Will Loew-Blosser. All rights reserved.
//

import Foundation
import Photos

class PGLDemo {
    // create random groups of image/filters
    // pull images from 'Favorites' album
    // supports PGLStackController Random button
    // supports Test classes

    static var FavoritesAlbumList: PGLAlbumSource?
    var appStack: PGLAppStack!
    let saveOutputToPhotoLib = false
    static var CurrentDemoGroup = 0
    static var Category1Index = 0


    static var TransistionFilters =  PGLFilterCategory("CICategoryTransition")!.filterDescriptors
    static var StylizeFilters =  PGLFilterCategory("CICategoryStylize")!.filterDescriptors
    static var DistortFilters = PGLFilterCategory("CICategoryDistortionEffect")!.filterDescriptors
    static var GeometryFilters = PGLFilterCategory("CICategoryGeometryAdjustment")!.filterDescriptors
    static var GradientFilters = PGLFilterCategory("CICategoryGradient")!.filterDescriptors
    static var SharpenFilters = PGLFilterCategory("CICategorySharpen")!.filterDescriptors
    static var BlurFilters = PGLFilterCategory("CICategoryBlur")!.filterDescriptors
    static var CompositeFilters = PGLFilterCategory("CICategoryCompositeOperation")!.filterDescriptors
    static var HalfToneFilters = PGLFilterCategory("CICategoryHalftoneEffect")!.filterDescriptors
    static var ColorAdjFilters = PGLFilterCategory("CICategoryColorAdjustment")!.filterDescriptors
    static var ColorEffectFilters = PGLFilterCategory("CICategoryColorEffect")!.filterDescriptors
    static var TileFilters = PGLFilterCategory("CICategoryTileEffect")!.filterDescriptors
    static var GeneratorFilters = PGLFilterCategory("CICategoryGenerator")!.filterDescriptors


    static var SingleFilterGroups = [BlurFilters,ColorAdjFilters, ColorEffectFilters,StylizeFilters, DistortFilters, GeometryFilters,SharpenFilters, HalfToneFilters] //TileFilters
    static var GeneratorGroups = [GeneratorFilters, GradientFilters]
    static var CompositeGroups = [CompositeFilters, TransistionFilters]


    func fetchFavoritesList() ->  PGLAlbumSource? {

        if PGLDemo.FavoritesAlbumList == nil {
            let userFavorites = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumFavorites , options: nil)


            if let theFavoriteAlbum = userFavorites.firstObject {
                 let fetchResultAssets = PHAsset.fetchAssets(in: theFavoriteAlbum , options: nil)
                let theInfo =  PGLAlbumSource(theFavoriteAlbum,fetchResultAssets)
    //                                          init(_ assetAlbum: PHAssetCollection, _ result: PHFetchResult<PHAsset>? ))
                                // init(_ assetAlbum: PHAssetCollection, _ result: PHFetchResult<PHAsset>? )
                PGLDemo.FavoritesAlbumList = theInfo
            }
        }
        return PGLDemo.FavoritesAlbumList

    }

    func addFiltersTo(stack: PGLFilterStack) {
        // put 9 random filters on the stack
        // one filter from each group: blur, colorAdj, colorEffect, stylize, distort
        //MARK: Move to PGLDemo

        for aGroup in PGLDemo.SingleFilterGroups {
                let aFilterIndex = Int.random(in: 0 ..< aGroup.count)
                let thisFilter = aGroup[aFilterIndex].pglSourceFilter()
                thisFilter?.setDefaults()
            NSLog("addFiltersTo \(thisFilter!.localizedName()) \(String(describing: thisFilter!.filterName))")
            let imageAttributesNames = thisFilter!.imageInputAttributeKeys
                for anImageAttributeName in imageAttributesNames {
                    if anImageAttributeName == kCIInputImageKey { continue
                        // skip the default.. adding to the stack will set the input
                    }
                    guard let thisAttribute = thisFilter!.attribute(nameKey: anImageAttributeName) else { continue }
                   setInputTo(imageParm: thisAttribute) // the six images from favorites
               }
//            stack.append(thisFilter!)
            //  this just adds without an input
            stack.appendFilter(thisFilter!) // this sets the input

        }

    }

    func setInputTo(imageParm: PGLFilterAttribute) {
        //MARK: Move to PGLDemo
        //use first 6 images of the favorites if a transition filter
       // otherwise just one image

        guard let favoriteAlbumSource = fetchFavoritesList() else
                   { fatalError("favoritesAlbum contents not returned") }
        favoriteAlbumSource.filterParm = imageParm
        let favoriteAssets = favoriteAlbumSource.assets() // converts to PGLAsset
       // mix it up with photos

        var selectedAssets = [PGLAsset]()
        var allowedAssetCount = 1
        if imageParm.isTransitionFilter() { allowedAssetCount = 6 }
        let maxIndex = favoriteAssets!.count
        if maxIndex == 0 {
            // may be limited access to photo lib
            return
        }
        while selectedAssets.count <= allowedAssetCount {
            let randomIndex = Int.random(in: 0 ..< maxIndex)
            selectedAssets.append(favoriteAssets![randomIndex])
        }

        let userSelectionInfo = PGLUserAssetSelection(assetSources: favoriteAlbumSource)
        for anAsset in selectedAssets {
            NSLog("parm = \(String(describing: imageParm.attributeName)) added local id = \(anAsset.localIdentifier)")
            userSelectionInfo.addSourceToSelection(asset: anAsset)
        }
        userSelectionInfo.setUserPick()
    }

    func multipleInputTransitionFilters() -> PGLSourceFilter{
        // answer first addedFilter
        //MARK: Move to PGLDemo

        var firstRandomFilter: PGLSourceFilter

        if PGLDemo.CurrentDemoGroup >= PGLDemo.CompositeGroups.count {
        // keeps moving forward each time random button is clicked
        // clears back to zero if app restarts
            PGLDemo.CurrentDemoGroup = 0
      }

        let group1 = PGLDemo.CompositeGroups[PGLDemo.CurrentDemoGroup]
        let targetStack = appStack.outputFilterStack()
        firstRandomFilter = group1[PGLDemo.Category1Index].pglSourceFilter()!

        if PGLDemo.Category1Index < group1.count {

            firstRandomFilter.setDefaults()

            NSLog("multipleInputTransitionFilters group1 filter \(firstRandomFilter.fullFilterName())")
            let imageAttributesNames = firstRandomFilter.imageInputAttributeKeys
            for anImageAttributeName in imageAttributesNames {
                guard let thisAttribute = firstRandomFilter.attribute(nameKey: anImageAttributeName) else { continue }
                setInputTo(imageParm: thisAttribute) // the six images from favorites
            }

//                targetStack.append(category1Filter)
            targetStack.appendFilter(firstRandomFilter)
            // since this is opposite order to the ui where the filter is picked then the inputs
            // reset the input source
            firstRandomFilter.setInputImageParmState(newState: ImageParm.inputPhoto)
            addFiltersTo(stack: targetStack)

            targetStack.stackName = firstRandomFilter.filterName + "+ various filters"
            targetStack.stackType = "multipleInputTransitionFilters"
            if saveOutputToPhotoLib {
                targetStack.exportAlbumName = "testMultipleInputTransitionFilters" }
            else { targetStack.exportAlbumName = nil }

            // set the stack with the title, type, exportAlbum for save
            NSLog("PGLDemo multipleInputTransitionFilters \(targetStack.stackName)")
//                targetStack.saveStackImage()
           // confirm that output is saved and the coreData has saved

            PGLDemo.Category1Index += 1

            PGLDemo.CurrentDemoGroup += 1
            // increment
        } else {
            PGLDemo.Category1Index = 0 // reset
        }
        return firstRandomFilter
    }

}
