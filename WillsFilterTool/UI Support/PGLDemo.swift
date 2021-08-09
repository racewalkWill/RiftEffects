//
//  PGLDemo.swift
//  Surreality
//
//  Created by Will on 1/23/21.
//  Copyright © 2021 Will Loew-Blosser. All rights reserved.
//

import Foundation
import Photos
import UIKit
import os

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


    static var SingleFilterGroups = [BlurFilters,ColorAdjFilters, ColorEffectFilters,StylizeFilters, DistortFilters, GeometryFilters,SharpenFilters, HalfToneFilters , TileFilters ,GeneratorFilters, GradientFilters] //TileFilters
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
        // put 4 random filters on the stack
        // filters from random groups in singleFilterGroups


//        for aGroup in PGLDemo.SingleFilterGroups {
        for filterIndex in 0...3 {
            let groupIndex = Int.random(in: 0 ..< PGLDemo.SingleFilterGroups.count)
            let aGroup = PGLDemo.SingleFilterGroups[groupIndex]
            let aFilterIndex = Int.random(in: 0 ..< aGroup.count)
            guard let thisFilter = aGroup[aFilterIndex].pglSourceFilter() else {
                continue
            }
            thisFilter.setDefaults()
            Logger(subsystem: LogSubsystem, category: LogCategory).notice("addFiltersTo \(thisFilter.localizedName()) \(String(describing: thisFilter.filterName))")

            switch filterIndex {
                case  0 :
                // first filter special setup
                    setImageInputs(thisFilter)
                    stack.append(thisFilter)
                    thisFilter.setInputImageParmState(newState: ImageParm.inputPhoto)
                default  :


                    let imageAttributesNames = thisFilter.imageInputAttributeKeys
                        for anImageAttributeName in imageAttributesNames {
                            if anImageAttributeName == kCIInputImageKey { continue
                                // skip the default.. adding to the stack will set the input
                            }
                            guard let thisAttribute = thisFilter.attribute(nameKey: anImageAttributeName) else { continue }
                            let newChildAdded = mightAddChildStack(attribute: thisAttribute)
                            if !newChildAdded {
                                setInputTo(imageParm: thisAttribute) // the six images from favorites
                            }

                       }
                    stack.appendFilter(thisFilter) // this sets the input
            }
        }
    }

    func setInputTo(imageParm: PGLFilterAttribute) {
        //MARK: Move to PGLDemo
        //use first 6 images of the favorites if a transition filter
       // otherwise just one image

        guard let favoriteAlbumSource = fetchFavoritesList() else
                   {
            DispatchQueue.main.async {
                // put back on the main UI loop for the user alert
                let alert = UIAlertController(title: "Favorites Album", message: "Favorites is empty ", preferredStyle: .alert)

                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
                Logger(subsystem: LogSubsystem, category: LogCategory).error("PGLDemo #setInputTo Favorites album is empty")
                }))
                let myAppDelegate =  UIApplication.shared.delegate as! AppDelegate
                myAppDelegate.displayUser(alert: alert)
            }
            return
        }
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

        // ensure an image is only picked once.
        var pickedIndexes = [Int]()
        let maxLoopCount = allowedAssetCount * 2
            // stop at some point
        var whileLoopCount = 0
        while (selectedAssets.count <= allowedAssetCount) && (whileLoopCount <= maxLoopCount) {
            let randomIndex = Int.random(in: 0 ..< maxIndex)
            if pickedIndexes.contains(randomIndex) {
                // skip to next  loop for new random
                continue }
            pickedIndexes.append(randomIndex)
            selectedAssets.append(favoriteAssets![randomIndex])
            whileLoopCount += 1
        }

        let userSelectionInfo = PGLUserAssetSelection(assetSources: favoriteAlbumSource)
        for anAsset in selectedAssets {
            Logger(subsystem: LogSubsystem, category: LogCategory).debug("parm = \(String(describing: imageParm.attributeName)) added local id = \(anAsset.localIdentifier)")
            userSelectionInfo.addSourceToSelection(asset: anAsset)
        }
        userSelectionInfo.setUserPick()
    }
    func mightAddChildStack(attribute: PGLFilterAttribute) -> Bool {
       // use childStack infrequently..
        // need a guard to usually return false without change
        // if childStack added then return true
        // random 1 in 10 chance to addChildStack..
        let skipAddChild = Int.random(in: 1...100) < 90
        if skipAddChild { return false }

        Logger(subsystem: LogSubsystem, category: LogCategory).debug("adding ChildStack at \(String(describing: attribute.attributeName))")
        guard let imageAttribute = attribute as? PGLFilterAttributeImage
            else { return false }
        appStack.addChildStackTo(parm: imageAttribute)
        let childStack = appStack.viewerStack // the new childStack
        setInputTo(imageParm: imageAttribute)
        addFiltersTo(stack: childStack)
        return true
    }

    fileprivate func setImageInputs(_ firstRandomFilter: PGLSourceFilter) {
        let imageAttributesNames = firstRandomFilter.imageInputAttributeKeys

        for anImageAttributeName in imageAttributesNames {
            guard let thisAttribute = firstRandomFilter.attribute(nameKey: anImageAttributeName) else { continue }

            if imageAttributesNames.count == 1 {
                // for a single image input set an image without a child stack
                setInputTo(imageParm: thisAttribute)
                return
            }

            let newChildAdded = mightAddChildStack(attribute: thisAttribute)
            if !newChildAdded {
                setInputTo(imageParm: thisAttribute) // the six images from favorites
            }
        }
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

        if PGLDemo.Category1Index < (group1.count - 1 ){

            addFiltersTo(stack: targetStack)

            targetStack.stackName = "Random Favorites"
                //was  firstRandomFilter.filterName + "+ various filters"
            targetStack.stackType = targetStack.stackName
            if saveOutputToPhotoLib {
                targetStack.exportAlbumName = "Random" }
            else { targetStack.exportAlbumName = nil }

            // set the stack with the title, type, exportAlbum for save
            Logger(subsystem: LogSubsystem, category: LogCategory).notice("PGLDemo multipleInputTransitionFilters \(targetStack.stackName)")
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
