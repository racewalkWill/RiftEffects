//
//  GlanceTests.swift
//  GlanceTests
//
//  Created by Will on 10/11/17.
//  Copyright © 2017 Will. All rights reserved.
//

import XCTest
import Photos
import os

//@testable import Glance
@testable import WillsFilterTool

class GlanceTests: XCTestCase {
    var testCIImage: CIImage!
    var testImage2: CIImage!
    let standardFilterName = "CIDiscBlur"

    override func setUp() {
        super.setUp()
        testCIImage = fetchFavoritesList().image(atIndex: 0)!
        testImage2 = fetchFavoritesList().image(atIndex: 1)!
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func fetchFavoritesList() -> PGLImageList {
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

    func testFilterExtensions() {
        if let testFilter = PGLSourceFilter(filter: standardFilterName)  {


            let testInputKeys = testFilter.imageInputAttributeKeys
            Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("testFilterExtensions testInputKeys = \(testInputKeys)")
            XCTAssert(!(testInputKeys.contains("inputRadius")))
            XCTAssert(testInputKeys.contains("inputImage"))
            XCTAssert(testInputKeys.count > 0)
        } else {
            Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("testFilterExtensions failed to create standard Filter")
            let secondTry = CIFilter(name: standardFilterName)
            Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("testFilterExtensions secondTry = \(String(describing: secondTry))")
            XCTFail("testFilterExtensions failed to create standard Filter")
        }



    }

    func testSourceFilterAttributes() {
        // the attributess of the source filter
       
        if let testFilter = PGLSourceFilter(filter: standardFilterName)  {
            testFilter.setInput(image:testCIImage, source:"StandardTestSource")
            testFilter.setInput(image: testImage2, source:"StandardTestSource")
            let oldImage = testFilter.oldImageInput
            XCTAssertNotNil(oldImage )
            XCTAssertTrue( (oldImage!.extent.width > 0) && (oldImage!.extent.height > 0), "oldImage extent is zero width/height")
            let inputKeys = testFilter.localFilter.inputKeys

            XCTAssert(inputKeys.count == 2) //inputImage and InputRadius expected for the CIDiscBlur

         
        } else { XCTFail("PGLSourceFilter not created for CIDiscBlur standard filter") }
    }


    func testImageInputKeys() {
        if let testFilter = PGLSourceFilter(filter: standardFilterName)  {
            let keys = testFilter.imageInputAttributeKeys
            XCTAssert(keys.count == 1)
            Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("inputAttributeKeys = \(keys)")

        }
    }


    
//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }
    
}
