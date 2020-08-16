//
//  PGLCategorySurvey.swift
//  SurrealityTests
//
//  Created by Will on 8/5/20.
//  Copyright © 2020 Will Loew-Blosser. All rights reserved.
//

import XCTest
import Photos
@testable import Surreality

class PGLCategorySurvey: XCTestCase {
    let context = CIContext()
    var favoritesAlbumList: PGLAlbumSource?
    var appStack: PGLAppStack!
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        favoritesAlbumList = fetchFavoritesList()
        // ensure the PGLImageController is open and can do the saveToPhotosLibrary

        let myAppDelegate =  UIApplication.shared.delegate as! AppDelegate
        appStack = myAppDelegate.appStack
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
//        let myAppDelegate =  UIApplication.shared.delegate as! AppDelegate
//               myAppDelegate.saveContext() // checks if context has changes
               super.tearDown()
    }

//    func testExample() throws {
//        // This is an example of a functional test case.
//        // Use XCTAssert and related functions to verify your tests produce the correct results.
//    }

//    func testPerformanceExample() throws {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

    // MARK: common support func

    func fetchFavoritesList() ->  PGLAlbumSource? {

            let userFavorites = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumFavorites , options: nil)


            if let theFavoriteAlbum = userFavorites.firstObject {
                 let fetchResultAssets = PHAsset.fetchAssets(in: theFavoriteAlbum , options: nil)
                let theInfo =  PGLAlbumSource(theFavoriteAlbum,fetchResultAssets)
    //                                          init(_ assetAlbum: PHAssetCollection, _ result: PHFetchResult<PHAsset>? ))
                                // init(_ assetAlbum: PHAssetCollection, _ result: PHFetchResult<PHAsset>? )
                return theInfo

            }
            return nil

        }

    func setInputTo(imageParm: PGLFilterAttribute) {
        guard let favoriteAlbumSource = fetchFavoritesList() else
                   { fatalError("favoritesAlbum contents not returned") }
        favoriteAlbumSource.filterParm = imageParm
        let favoriteAssets = favoriteAlbumSource.assets() // converts to PGLAsset
        // take the first ones for testing...

        guard let selectedAssets = favoriteAssets?.prefix(6)
            else { fatalError ("Favorite Album does not have 6 images") }

        let userSelectionInfo = PGLUserAssetSelection(assetSources: favoriteAlbumSource)
        for anAsset in selectedAssets {
            userSelectionInfo.addSourceToSelection(asset: anAsset)
        }

         //use first 6 images of the favorites
        userSelectionInfo.setUserPick()
    }

    // create class vars to hold each of the categories of filters
    // for each test case chain filters from a set of several categories.. one filter
    // per category... and 1 to 5 categories covered
    // cover all

    // MARK: Class var category filterDescriptors
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


    static var SingleFilterGroups = [BlurFilters,ColorAdjFilters, ColorEffectFilters,StylizeFilters, DistortFilters,
                               GeometryFilters,SharpenFilters, HalfToneFilters, TileFilters]
    static var GeneratorGroups = [GeneratorFilters, GradientFilters]
    static var CompositeGroups = [CompositeFilters, TransistionFilters]

// MARK: tests

    func testSingleInputFilters() {
        var category1Index = 0
        var category2Index = -1
        var category1Filter: PGLSourceFilter
        var category2Filter: PGLSourceFilter


        for i in stride(from: 0, to: (PGLCategorySurvey.SingleFilterGroups.count - 1), by: 2)  {
        let group1 = PGLCategorySurvey.SingleFilterGroups[i]
        let group2 = PGLCategorySurvey.SingleFilterGroups[i + 1]
        category2Index = -1
        while category1Index < group1.count {

            let testFilterStack = appStack.viewerStack
                // should use the appStack to supply the filterStack
           testFilterStack.removeAllFilters()
                // restores  setStartupDefault() as first filter

            let firstFilter = testFilterStack.currentFilter()
            guard let firstFilterInput = firstFilter.attribute(nameKey: "inputImage") else { return XCTFail() }
             setInputTo(imageParm: firstFilterInput) // sets 6 images from favorites album

            category1Filter = group1[category1Index].pglSourceFilter()!
            category1Filter.setDefaults()
            testFilterStack.append(category1Filter)

            if category2Index < (group2.count - 1) {
                category2Index += 1
            } else {
                category2Index = 0
            }
            category2Filter = group2[category2Index].pglSourceFilter()!
            category2Filter.setDefaults()
            testFilterStack.append(category2Filter)

            let stackResultImage = testFilterStack.stackOutputImage(false)
            XCTAssertNotNil(stackResultImage)
            XCTAssert(testFilterStack.activeFilters.count == 3, "stack does not have three filters as expected" )
            testFilterStack.stackName = category1Filter.filterName + "+" + category2Filter.filterName
            testFilterStack.stackType = "testSingleInputFilters"
            testFilterStack.exportAlbumName = "testSingleInputFilters"
            // set the stack with the title, type, exportAlbum for save
            NSLog("PGLCategorySurvey #testSingleInputFilters at groups \(i)  \(testFilterStack.stackName)")
            let photoSaveResult =  testFilterStack.saveStackImage()
            XCTAssertTrue(photoSaveResult , testFilterStack.stackName + " Error on saveStackImage")

            category1Index += 1



        }
        }
    }

}
