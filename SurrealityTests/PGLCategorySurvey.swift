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
    var favoritesAlbumList: PGLImageList?
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
        let myAppDelegate =  UIApplication.shared.delegate as! AppDelegate
               myAppDelegate.saveContext() // checks if context has changes
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

    func fetchFavoritesList() -> PGLImageList {
        // only need several or one image.. omit the whole favorites?

        var favIDs = [String]()
        let userFavorites = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumFavorites , options: nil)
        if let theFavoriteAlbum = userFavorites.firstObject {
             let assets = PHAsset.fetchAssets(in: theFavoriteAlbum , options: nil)
                assets.enumerateObjects{(asset,index,stop) in
                    favIDs.append(asset.localIdentifier)
                }
            let albumIDs = Array(repeating: theFavoriteAlbum.localIdentifier, count: favIDs.count)

            let theFavorites =  PGLImageList(localAssetIDs: favIDs, albumIds: albumIDs)
            // this init assumes two matching arrays of same size localId and albumid

            //        theFavorites.isAssetList = true
            return theFavorites

        }
        return PGLImageList()

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

// MARK: tests

    func testSingleInputFilters() {
        var category1Index = 0
        var category2Index = 0
        var category1Filter: PGLSourceFilter
        var category2Filter: PGLSourceFilter




        while category1Index < PGLCategorySurvey.BlurFilters.count {
             var testFilterStack = PGLFilterStack()
                // should use the appStack to supply the filterStack
            testFilterStack.removeDefaultFilter()
            category1Filter = PGLCategorySurvey.BlurFilters[category1Index].pglSourceFilter()!
            testFilterStack.append(category1Filter)
           let input = category1Filter.attribute(nameKey: "inputImage")
            input!.setImageCollectionInput(cycleStack: favoritesAlbumList! )

            if category1Index < PGLCategorySurvey.ColorAdjFilters.count {
                category2Index = category1Index
                category2Filter = PGLCategorySurvey.ColorAdjFilters[category2Index].pglSourceFilter()!
                testFilterStack.append(category2Filter)
                let stackResultImage = testFilterStack.stackOutputImage(false)
                XCTAssertNotNil(stackResultImage)

                testFilterStack.stackName = category1Filter.filterName + "+" + category2Filter.filterName
                testFilterStack.stackType = "testSingleInputFilters"
                testFilterStack.exportAlbumName = "testSingleInputFilters"
                // set the stack with the title, type, exportAlbum for save
                
                testFilterStack.saveStackImage()

                // save this output PGLImageController saveToPhotosLibrary
                //  appStack.writeCDStacks()

                // need the metalRender for the metalContext

//                if let offScreenRender = Renderer(metalView:) {
//                    appStack.saveStack(metalRender: )
//                }
            }
            category1Index += 1
            testFilterStack.removeAllFilters()

            // next continue with remaining category2 filters if there are more
        }
    }

}
