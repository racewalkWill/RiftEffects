//
//  PGLSourceFilterTests.swift
//  PictureGlance
//
//  Created by Will on 8/20/17.
//  Copyright © 2017 Will. All rights reserved.
//

import XCTest
import Photos
import os

let TestLogSubsystem = "L-BSoftwareArtist.WillsFilterTool"
var TestLogCategory = "PGL"

@testable import Surreality



class PGLSourceFilterTests: XCTestCase {

    

    var jobIndex = UInt64(0)
    var depthFilter: PGLSourceFilter?
    var inputCollection: PGLImageList?
    var appStack: PGLAppStack!

    override func setUp() {
        depthFilter = PGLSourceFilter(filter: "CIDepthOfField" )
        let myAppDelegate =  UIApplication.shared.delegate as! AppDelegate
        appStack = myAppDelegate.appStack
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.


    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
//        let myAppDelegate =  UIApplication.shared.delegate as! AppDelegate
//        myAppDelegate.saveContext() // checks if context has changes
        let newStack = PGLFilterStack()
        newStack.setStartupDefault() // not sent in the init.. need a starting point
        self.appStack.resetToTopStack(newStack: newStack)

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



    func testParmAttributes() {

        // test creation of the parmAttributes of the CIFilter. PGLSourceFilter connects parms and the filter
        
        XCTAssertNotNil(depthFilter)
        Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("testParmAttributes depthFilter = \(String(describing: self.depthFilter))")
        XCTAssert(depthFilter!.attributes.count == 7)
        
        if let depthAttributes = depthFilter?.attributes {
            let saturation = depthAttributes[4]
            XCTAssert(saturation.attributeType == "CIAttributeTypeScalar"  ) // AttrType.Scalar.rawValue
        }
    }

    func testParmDepthFilterSetter() {
        // test that parms that are not image input are set
        
//        var initialValue: Any
//        var changedValue: Any

//        let ciFilterQueue = DispatchQueue(label: "glance-ciFilter-processing")
        XCTAssertNotNil(depthFilter)
        depthFilter?.setDefaults()
        Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("testParmAttributes depthFilter = \(String(describing: self.depthFilter))")
        XCTAssert(depthFilter!.attributes.count == 7)


        for anAttribute in depthFilter?.attributes ?? [PGLFilterAttribute]() {
            if anAttribute.attributeName != "inputImage" {
               let initialValue = anAttribute.getValue()!
                anAttribute.increment()
               let  changedValue = anAttribute.getValue()!
//                NSLog("testParmInput anAttribute = \(String(describing: anAttribute.attributeDisplayName))")
//                Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("testParmInput initialValue = \(initialValue)")
//                Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("testParmInput changedValue = \(changedValue)")
////                XCTAssert(changedValue === initialValue,"Filter parm  is NOT changed. Set Value failed")
            }

        }
    }

     func testDissolveParms() {
            // test that the parms are changed for Dissolve filter
            var image1: CIImage
            var image2: CIImage
            let timerFilter = PGLSourceFilter(filter: "CIDissolveTransition" )!
            let albumFavorite = fetchFavoritesList() // PGLImageList of the favorites albume
            if albumFavorite.sizeCount() < 2 {
                XCTFail() }

            image1 = albumFavorite.image(atIndex: 0)!
            image2 = albumFavorite.image(atIndex: 1)!

            XCTAssertNotNil(timerFilter)
            timerFilter.setDefaults()
            XCTAssert(timerFilter.attributes.count == 3)

            timerFilter.setInput(image: image1, source: "shoreLine")
            timerFilter.setBackgroundInput(image: image2)
            let timerRate1 = timerFilter.valueFor(keyName: "inputTime") as! NSNumber
                // should be 0.0 as default

            timerFilter.setNumberValue(newValue: 0.05, keyName: "inputTime")
            let timerRate2 = timerFilter.valueFor(keyName: "inputTime") as! NSNumber
            XCTAssert(timerRate1 != timerRate2)

    }

    func testTransitionCategoryFilters() {
            // test that the timer rate is set and changed for Dissolve filter
            // test that image dissolves to the target

        let context = CIContext()
        let favoritesAlbumList = fetchFavoritesList()
        // get the category to create correct pglsourceFilter
        let transitionCategory = PGLFilterCategory("CICategoryTransition")!
        for aTransitionDescriptor in transitionCategory.filterDescriptors {
//            let timerFilterDescriptor = transitionCategory.filterDescriptors.first(where: {$0.filterName == "CIDissolveTransition"})
            Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("PGLSourceFilterTests \(#function) testing filter \(aTransitionDescriptor.displayName)")
            let timerFilter = aTransitionDescriptor.pglSourceFilter()!

            XCTAssertNotNil(timerFilter)
            timerFilter.setDefaults()

            let input = timerFilter.attribute(nameKey: "inputImage")
            input!.setImageCollectionInput(cycleStack: favoritesAlbumList )
                // this clones to the inputTargetImage parm
                // so two parms are set with values
            if let allImageParms = timerFilter.imageParms() {
                if allImageParms.count > 2 {
                    Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("\(String(describing: timerFilter.filterName)) has more than 2 image inputs")
                    for nextImageParm in allImageParms.suffix(from: 2) {
                        nextImageParm.set(favoritesAlbumList.increment() as Any)
                    }
                }
            }
            let timerRate1 = timerFilter.valueFor(keyName: "inputTime") as! NSNumber
                // should be 0.0 as default

            timerFilter.setNumberValue(newValue: 0.05, keyName: "inputTime")
            let timerRate2 = timerFilter.valueFor(keyName: "inputTime") as! NSNumber
            XCTAssert(timerRate1 != timerRate2)

            if let  result = timerFilter.outputImage(){
                XCTAssertTrue( (result.extent.width > 0) && (result.extent.height > 0), "result extent is zero width/height")
                let image1 = UIImage(cgImage: context.createCGImage(result, from: result.extent)!)
                for _ in 1...100 {timerFilter.addStepTime()}
                let timerImage2 = timerFilter.outputImage()!
                XCTAssertTrue( (timerImage2.extent.width > 0) && (timerImage2.extent.height > 0), "image2 extent is zero width/height")
                let image2 = UIImage(cgImage:context.createCGImage(timerImage2, from: result.extent)!)
                XCTAssertNotNil(image1)

                XCTAssertNotNil(image2)

                XCTAssertFalse( image1.isEqual( image2), "Did not change output image")

            } else {
                XCTFail("no output image filter \(transitionCategory.categoryName) \(String(describing: timerFilter.filterName)) ")
            }
        }
    }

        func testStylizeCategoryFilters() {
                // test Stylize filters
                // test that image shows is displayed

            let context = CIContext()
            let favoritesAlbumList = fetchFavoritesList()
            XCTAssert(favoritesAlbumList.assetIDs.count > 4 , "Favorites Album should have at least 4 images")
            // get the category to create correct pglsourceFilter
            let theCategory = PGLFilterCategory("CICategoryStylize")!
            for aFilter in theCategory.filterDescriptors {
    //            let timerFilterDescriptor = transitionCategory.filterDescriptors.first(where: {$0.filterName == "CIDissolveTransition"})
                  Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("PGLSourceFilterTests \(#function) testing filter \(aFilter.displayName)")
                let pglFilter = aFilter.pglSourceFilter()!

                XCTAssertNotNil(pglFilter)
                pglFilter.setDefaults()

                let imageAttributesNames = pglFilter.imageInputAttributeKeys
                for index in 0 ..< imageAttributesNames.count {
                    let imageValue = favoritesAlbumList.image(atIndex: index)!
                    pglFilter.setImageValue(newValue: imageValue , keyName: imageAttributesNames[index])
                }

                if let  result = pglFilter.outputImage(){
                    XCTAssertTrue( (result.extent.width > 0) && (result.extent.height > 0), "result extent is zero width/height")
                    let image1 = UIImage(cgImage: context.createCGImage(result, from: result.extent)!)
                    for _ in 1...100 {pglFilter.addStepTime()}
                    let result2 = pglFilter.outputImage()
                    XCTAssertTrue( (result2!.extent.width > 0) && (result2!.extent.height > 0), "result2 extent is zero width/height")
                    let image2 = UIImage(cgImage:context.createCGImage(result2!, from: result.extent)!)
                    XCTAssertNotNil(image1)

                    XCTAssertNotNil(image2)

                    XCTAssertFalse( image1.isEqual( image2), "Did not change output image")

                } else {
                   XCTFail("no output image filter \(theCategory.categoryName) \(aFilter.displayName)")
                }
            }
        }

    func testDistortFilters() {
                // test Distort filters
                // test that image shows is displayed
            var firstExtent = CGRect.init(origin: CGPoint.zero, size: CGSize(width: 100, height: 100))
            let context = CIContext()
            let favoritesAlbumList = fetchFavoritesList()
            XCTAssert(favoritesAlbumList.assetIDs.count > 4 , "Favorites Album should have at least 4 images")
            // get the category to create correct pglsourceFilter
            let theCategory = PGLFilterCategory("CICategoryDistortionEffect")!
            for aFilter in theCategory.filterDescriptors {
    //            let timerFilterDescriptor = transitionCategory.filterDescriptors.first(where: {$0.filterName == "CIDissolveTransition"})
                  Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("PGLSourceFilterTests \(#function) testing filter \(aFilter.displayName)")
                let pglFilter = aFilter.pglSourceFilter()!

                XCTAssertNotNil(pglFilter)
                

                let imageAttributesNames = pglFilter.imageInputAttributeKeys
                for index in 0 ..< imageAttributesNames.count {
                    let imageValue = favoritesAlbumList.image(atIndex: index)!
                    if index == 0 { firstExtent = imageValue.extent }
                    pglFilter.setImageValue(newValue: imageValue , keyName: imageAttributesNames[index])
                }

                if let  result = pglFilter.outputImage(){
                    XCTAssertTrue( (result.extent.width > 0) && (result.extent.height > 0), "result extent is zero width/height")
                    let image1 = UIImage(cgImage: context.createCGImage(result, from: firstExtent)!)
                    for _ in 1...100 {pglFilter.addStepTime()}
                    let result2 = pglFilter.outputImage()
                    let image2 = UIImage(cgImage:context.createCGImage(result2!, from: firstExtent)!)
                    XCTAssertTrue( (result2!.extent.width > 0) && (result2!.extent.height > 0), "result2 extent is zero width/height")
                    XCTAssertNotNil(image1)
                    XCTAssertNotNil(image2)
                    XCTAssertFalse( image1.isEqual( image2), "Did not change output image")

                } else {
                   XCTFail("no output image filter \(theCategory.categoryName) \(aFilter.displayName)")
                }
            }
        }

    func testGeometryFilters() {
                // test Stylize filters
                // test that image shows is displayed
            var firstExtent =  CGRect.init(origin: CGPoint.zero, size: CGSize(width: 100, height: 100))
            let context = CIContext()
            let favoritesAlbumList = fetchFavoritesList()
            XCTAssert(favoritesAlbumList.assetIDs.count > 4 , "Favorites Album should have at least 4 images")
            // get the category to create correct pglsourceFilter
            let theCategory = PGLFilterCategory("CICategoryGeometryAdjustment")!
            for aFilter in theCategory.filterDescriptors {
    //            let timerFilterDescriptor = transitionCategory.filterDescriptors.first(where: {$0.filterName == "CIDissolveTransition"})
                  Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("PGLSourceFilterTests \(#function) testing filter \(aFilter.displayName)")
                let pglFilter = aFilter.pglSourceFilter()!

                XCTAssertNotNil(pglFilter)
                pglFilter.setDefaults()

                let imageAttributesNames = pglFilter.imageInputAttributeKeys
                for index in 0 ..< imageAttributesNames.count {
                    let imageValue = favoritesAlbumList.image(atIndex: index)!
                    if index == 0 { firstExtent = imageValue.extent }
                    pglFilter.setImageValue(newValue: imageValue , keyName: imageAttributesNames[index])
                }

                if let  result = pglFilter.outputImage(){
                    XCTAssertTrue( (result.extent.width > 0) && (result.extent.height > 0), "result extent is zero width/height")
                    let image1 = UIImage(cgImage: context.createCGImage(result, from: firstExtent)!)
                    for _ in 1...100 {pglFilter.addStepTime()}
                    let result2 = pglFilter.outputImage()
                    let image2 = UIImage(cgImage:context.createCGImage(result2!, from: firstExtent)!)
                    XCTAssertTrue( (result2!.extent.width > 0) && (result2!.extent.height > 0), "result2 extent is zero width/height")
                    XCTAssertNotNil(image1)
                    XCTAssertNotNil(image2)
                    XCTAssertFalse( image1.isEqual( image2), "Did not change output image")

                } else {
                    XCTFail("no output image filter \(theCategory.categoryName) \(aFilter.displayName)")
                }
            }
        }

    func testGradientFilters() {
                // test Gradient filters
                // test that image shows is displayed
            let theCategory = PGLFilterCategory("CICategoryGradient")!
        var firstExtent = CGRect.init(origin: CGPoint.zero, size: CGSize(width: 100, height: 100))
            let context = CIContext()
            let favoritesAlbumList = fetchFavoritesList()
            XCTAssert(favoritesAlbumList.assetIDs.count > 4 , "Favorites Album should have at least 4 images")
            // get the category to create correct pglsourceFilter

            for aFilter in theCategory.filterDescriptors {
    //            let timerFilterDescriptor = transitionCategory.filterDescriptors.first(where: {$0.filterName == "CIDissolveTransition"})
                  Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("PGLSourceFilterTests \(#function) testing filter \(aFilter.displayName)")
                let pglFilter = aFilter.pglSourceFilter()!

                XCTAssertNotNil(pglFilter)
                pglFilter.setDefaults()

                let imageAttributesNames = pglFilter.imageInputAttributeKeys
                for index in 0 ..< imageAttributesNames.count {
                    let imageValue = favoritesAlbumList.image(atIndex: index)!
                    if index == 0 { firstExtent = imageValue.extent }
                    pglFilter.setImageValue(newValue: imageValue , keyName: imageAttributesNames[index])
                }

                if let  result = pglFilter.outputImage(){
                    XCTAssertTrue( (result.extent.width > 0) && (result.extent.height > 0), "result extent is zero width/height")
                    guard let cgImage1 =  context.createCGImage(result, from: firstExtent)
                        else { XCTFail("failed CGImage creation from result filter \(aFilter.displayName)")
                            continue // to the next filter in the iteration
                    }
                    let image1 = UIImage(cgImage: cgImage1)
                    for _ in 1...100 {pglFilter.addStepTime()}
                    let result2 = pglFilter.outputImage()
                    let image2 = UIImage(cgImage:context.createCGImage(result2!, from: firstExtent)!)
                    XCTAssertTrue( (result2!.extent.width > 0) && (result2!.extent.height > 0), "result2 extent is zero width/height")
                    XCTAssertNotNil(image1)
                    XCTAssertNotNil(image2)
                    XCTAssertFalse( image1.isEqual( image2), "Did not change output image")

                } else {
                    XCTFail("no output image filter \(theCategory.categoryName) \(aFilter.displayName)")
                }
            }
        }

    func testSharpenFilters() {
                // test Gradient filters
                // test that image shows is displayed
            let theCategory = PGLFilterCategory("CICategorySharpen")!
            var firstExtent = CGRect.init(origin: CGPoint.zero, size: CGSize(width: 100, height: 100))
            let context = CIContext()
            let favoritesAlbumList = fetchFavoritesList()
            XCTAssert(favoritesAlbumList.assetIDs.count > 4 , "Favorites Album should have at least 4 images")
            // get the category to create correct pglsourceFilter

            for aFilter in theCategory.filterDescriptors {
    //            let timerFilterDescriptor = transitionCategory.filterDescriptors.first(where: {$0.filterName == "CIDissolveTransition"})
                  Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("PGLSourceFilterTests \(#function) testing filter \(aFilter.displayName)")
                let pglFilter = aFilter.pglSourceFilter()!

                XCTAssertNotNil(pglFilter)
                pglFilter.setDefaults()

                let imageAttributesNames = pglFilter.imageInputAttributeKeys
                for index in 0 ..< imageAttributesNames.count {
                    let imageValue = favoritesAlbumList.image(atIndex: index)!
                    if index == 0 { firstExtent = imageValue.extent }
                    pglFilter.setImageValue(newValue: imageValue , keyName: imageAttributesNames[index])
                }

                if let  result = pglFilter.outputImage(){
                    XCTAssertTrue( (result.extent.width > 0) && (result.extent.height > 0), "result extent is zero width/height")
                    let image1 = UIImage(cgImage: context.createCGImage(result, from: firstExtent)!)
                    for _ in 1...100 {pglFilter.addStepTime()}
                    let result2 = pglFilter.outputImage()
                    XCTAssertTrue( (result2!.extent.width > 0) && (result2!.extent.height > 0), "result2 extent is zero width/height")
                    let image2 = UIImage(cgImage:context.createCGImage(result2!, from: firstExtent)!)
                    XCTAssertNotNil(image1)
                    XCTAssertNotNil(image2)
                    XCTAssertFalse( image1.isEqual( image2), "Did not change output image")

                } else {
                    XCTFail("no output image filter \(theCategory.categoryName) \(aFilter.displayName)")
                }
            }
        }

    func testBlurFilters() {
                // test Blure filters
                // test that image shows is displayed
            let theCategory = PGLFilterCategory("CICategoryBlur")!
            var firstExtent = CGRect.init(origin: CGPoint.zero, size: CGSize(width: 100, height: 100))
            let context = CIContext()
            let favoritesAlbumList = fetchFavoritesList()
            XCTAssert(favoritesAlbumList.assetIDs.count > 4 , "Favorites Album should have at least 4 images")
            // get the category to create correct pglsourceFilter

            for aFilter in theCategory.filterDescriptors {
    //            let timerFilterDescriptor = transitionCategory.filterDescriptors.first(where: {$0.filterName == "CIDissolveTransition"})
                  Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("PGLSourceFilterTests \(#function) testing filter \(aFilter.displayName)")
                let pglFilter = aFilter.pglSourceFilter()!

                XCTAssertNotNil(pglFilter)
                pglFilter.setDefaults()

                let imageAttributesNames = pglFilter.imageInputAttributeKeys
                for index in 0 ..< imageAttributesNames.count {
                    let imageValue = favoritesAlbumList.image(atIndex: index)!
                    if index == 0 { firstExtent = imageValue.extent }
                    pglFilter.setImageValue(newValue: imageValue , keyName: imageAttributesNames[index])
                }

                if let  result = pglFilter.outputImage(){
                    XCTAssertTrue( (result.extent.width > 0) && (result.extent.height > 0), "result extent is zero width/height")

                    guard let cgImage1 =  context.createCGImage(result, from: firstExtent)
                        else { XCTFail("failed CGImage creation from result filter \(aFilter.displayName)")
                            continue // to the next filter in the iteration
                    }
                    let image1 = UIImage(cgImage: cgImage1)
                    for _ in 1...100 {pglFilter.addStepTime()}
                    let result2 = pglFilter.outputImage()
                    XCTAssertTrue( (result2!.extent.width > 0) && (result2!.extent.height > 0), "result2 extent is zero width/height")
                    let image2 = UIImage(cgImage:context.createCGImage(result2!, from: firstExtent)!)
                    XCTAssertNotNil(image1)
                    XCTAssertNotNil(image2)
                    XCTAssertFalse( image1.isEqual( image2), "Did not change output image")

                } else {
                    XCTFail("no output image filter \(theCategory.categoryName) \(aFilter.displayName)")
                }
            }
        }

    func testCompositeFilters() {
                   // test Blure filters
                   // test that image shows is displayed
               let theCategory = PGLFilterCategory("CICategoryCompositeOperation")!
               var firstExtent = CGRect.init(origin: CGPoint.zero, size: CGSize(width: 100, height: 100))
               let context = CIContext()
               let favoritesAlbumList = fetchFavoritesList()
               XCTAssert(favoritesAlbumList.assetIDs.count > 4 , "Favorites Album should have at least 4 images")
               // get the category to create correct pglsourceFilter

               for aFilter in theCategory.filterDescriptors {
       //            let timerFilterDescriptor = transitionCategory.filterDescriptors.first(where: {$0.filterName == "CIDissolveTransition"})
                     Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("PGLSourceFilterTests \(#function) testing filter \(aFilter.displayName)")
                   let pglFilter = aFilter.pglSourceFilter()!

                   XCTAssertNotNil(pglFilter)
                   pglFilter.setDefaults()

                   let imageAttributesNames = pglFilter.imageInputAttributeKeys
                   for index in 0 ..< imageAttributesNames.count {
                       let imageValue = favoritesAlbumList.image(atIndex: index)!
                       if index == 0 { firstExtent = imageValue.extent }
                       pglFilter.setImageValue(newValue: imageValue , keyName: imageAttributesNames[index])
                   }

                   if let  result = pglFilter.outputImage(){
                    XCTAssertTrue( (result.extent.width > 0) && (result.extent.height > 0), "result extent is zero width/height")

                       guard let cgImage1 =  context.createCGImage(result, from: firstExtent)
                           else { XCTFail("failed CGImage creation from result filter \(aFilter.displayName)")
                               continue // to the next filter in the iteration
                       }
                       let image1 = UIImage(cgImage: cgImage1)
                       for _ in 1...100 {pglFilter.addStepTime()}
                       let result2 = pglFilter.outputImage()
                    XCTAssertTrue( (result2!.extent.width > 0) && (result2!.extent.height > 0), "result2 extent is zero width/height")

                       let image2 = UIImage(cgImage:context.createCGImage(result2!, from: firstExtent)!)
                       XCTAssertNotNil(image1)
                       XCTAssertNotNil(image2)
                       XCTAssertFalse( image1.isEqual( image2), "Did not change output image")

                   } else {
                       XCTFail("no output image filter \(theCategory.categoryName) \(aFilter.displayName)")
                   }
               }
           }

    func testHalfToneFilters() {
                // test Blure filters
                // test that image shows is displayed
            let theCategory = PGLFilterCategory("CICategoryHalftoneEffect")!
            var firstExtent = CGRect.init(origin: CGPoint.zero, size: CGSize(width: 100, height: 100))
            let context = CIContext()
            let favoritesAlbumList = fetchFavoritesList()
            XCTAssert(favoritesAlbumList.assetIDs.count > 4 , "Favorites Album should have at least 4 images")
            // get the category to create correct pglsourceFilter

            for aFilter in theCategory.filterDescriptors {
    //            let timerFilterDescriptor = transitionCategory.filterDescriptors.first(where: {$0.filterName == "CIDissolveTransition"})
                  Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("PGLSourceFilterTests \(#function) testing filter \(aFilter.displayName)")
                let pglFilter = aFilter.pglSourceFilter()!

                XCTAssertNotNil(pglFilter)
                pglFilter.setDefaults()

                let imageAttributesNames = pglFilter.imageInputAttributeKeys
                for index in 0 ..< imageAttributesNames.count {
                    let imageValue = favoritesAlbumList.image(atIndex: index)!
                    if index == 0 { firstExtent = imageValue.extent }
                    pglFilter.setImageValue(newValue: imageValue , keyName: imageAttributesNames[index])
                }

                if let  result = pglFilter.outputImage(){
                    XCTAssertTrue( (result.extent.width > 0) && (result.extent.height > 0), "result extent is zero width/height")

                    guard let cgImage1 =  context.createCGImage(result, from: firstExtent)
                        else { XCTFail("failed CGImage creation from result filter \(aFilter.displayName)")
                            continue // to the next filter in the iteration
                    }
                    let image1 = UIImage(cgImage: cgImage1)
                    for _ in 1...100 {pglFilter.addStepTime()}
                    let result2 = pglFilter.outputImage()
                    XCTAssertTrue( (result.extent.width > 0) && (result.extent.height > 0), "result extent is zero width/height")

                    let image2 = UIImage(cgImage:context.createCGImage(result2!, from: firstExtent)!)
                    XCTAssertNotNil(image1)
                    XCTAssertNotNil(image2)
                    XCTAssertFalse( image1.isEqual( image2), "Did not change output image")

                } else {
                    XCTFail("no output image filter \(theCategory.categoryName) \(aFilter.displayName)")
                }
            }
        }

    func testColorAdjFilters() {
                // test Color Adj filters
                // test that image shows is displayed
            let theCategory = PGLFilterCategory("CICategoryColorAdjustment")!
            var firstExtent = CGRect.init(origin: CGPoint.zero, size: CGSize(width: 100, height: 100))
            let context = CIContext()
            let favoritesAlbumList = fetchFavoritesList()
            XCTAssert(favoritesAlbumList.assetIDs.count > 4 , "Favorites Album should have at least 4 images")
            // get the category to create correct pglsourceFilter

            for aFilter in theCategory.filterDescriptors {

                  Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("PGLSourceFilterTests \(#function) testing filter \(aFilter.displayName)")
                let pglFilter = aFilter.pglSourceFilter()!

                XCTAssertNotNil(pglFilter)
                pglFilter.setDefaults()

                let imageAttributesNames = pglFilter.imageInputAttributeKeys
                for index in 0 ..< imageAttributesNames.count {
                    let imageValue = favoritesAlbumList.image(atIndex: index)!
                    if index == 0 { firstExtent = imageValue.extent }
                    pglFilter.setImageValue(newValue: imageValue , keyName: imageAttributesNames[index])
                }

                if let  result = pglFilter.outputImage(){
                    XCTAssertTrue( (result.extent.width > 0) && (result.extent.height > 0), "result extent is zero width/height")
                    let image1 = UIImage(cgImage: context.createCGImage(result, from: firstExtent)!)

                    guard let cgImage1 =  context.createCGImage(result, from: firstExtent)
                        else { XCTFail("failed CGImage creation from result filter \(aFilter.displayName)")
                            continue // to the next filter in the iteration
                    }
                    let image2 = UIImage(cgImage: cgImage1)
                    for _ in 1...100 {pglFilter.addStepTime()}
                    let result2 = pglFilter.outputImage()
                    XCTAssertTrue( (result2!.extent.width > 0) && (result2!.extent.height > 0), "result2 extent is zero width/height")
                    let image3 = UIImage(cgImage:context.createCGImage(result2!, from: firstExtent)!)
                    XCTAssertNotNil(image1)
                    XCTAssertNotNil(image2)
                    XCTAssertFalse( image1.isEqual( image3), "Did not change output image")

                } else {
                    XCTFail("no output image filter \(theCategory.categoryName) \(aFilter.displayName)")
                }
            }
        }

    func testColorEffectFilters() {
            // test Color  filters
            // test that image shows is displayed
        let theCategory = PGLFilterCategory("CICategoryColorEffect")!
        var firstExtent = CGRect.init(origin: CGPoint.zero, size: CGSize(width: 100, height: 100))
        let context = CIContext()
        let favoritesAlbumList = fetchFavoritesList()
        XCTAssert(favoritesAlbumList.assetIDs.count > 4 , "Favorites Album should have at least 4 images")
        // get the category to create correct pglsourceFilter

        for aFilter in theCategory.filterDescriptors {

            Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("PGLSourceFilterTests \(#function) testing filter \(aFilter.displayName) \(String(describing: aFilter.filterName))")
            let pglFilter = aFilter.pglSourceFilter()!

            XCTAssertNotNil(pglFilter)
            pglFilter.setDefaults()

            let imageAttributesNames = pglFilter.imageInputAttributeKeys
            for index in 0 ..< imageAttributesNames.count {
                let imageValue = favoritesAlbumList.image(atIndex: index)!
                if index == 0 { firstExtent = imageValue.extent }
//                NSLog("PGLSourceFilterTests testColorEffectFilters setting imageValue \(imageValue)")
//                NSLog("PGLSourceFilterTests testColorEffectFilters setting key \(imageAttributesNames[index])")
                pglFilter.setImageValue(newValue: imageValue , keyName: imageAttributesNames[index])
            }

            if let  result = pglFilter.outputImage(){
                XCTAssertTrue( (result.extent.width > 0) && (result.extent.height > 0), "result extent is zero width/height")

                guard let cgImage1 =  context.createCGImage(result, from: firstExtent)
                    else { XCTFail("failed CGImage creation from result filter \(aFilter.displayName) \(String(describing: aFilter.filterName))")
                        continue // to the next filter in the iteration
                }
                let image1 = UIImage(cgImage: cgImage1)
                for _ in 1...100 {pglFilter.addStepTime()}
                let result2 = pglFilter.outputImage()
                XCTAssertTrue( (result2!.extent.width > 0) && (result2!.extent.height > 0), "result2 extent is zero width/height")

                let image2 = UIImage(cgImage:context.createCGImage(result2!, from: firstExtent)!)
                XCTAssertNotNil(image1)
                XCTAssertNotNil(image2)
                XCTAssertFalse( image1.isEqual( image2), "Did not change output image")

            } else {
                XCTFail("no output image filter \(theCategory.categoryName) \(aFilter.displayName) \(String(describing: aFilter.filterName))")
            }
        }
    }

    func testTileFilters() {
               // test Color  filters
               // test that image shows is displayed
           let theCategory = PGLFilterCategory("CICategoryTileEffect")!
           var firstExtent = CGRect.init(origin: CGPoint.zero, size: CGSize(width: 100, height: 100))
           let context = CIContext()
           let favoritesAlbumList = fetchFavoritesList()
           XCTAssert(favoritesAlbumList.assetIDs.count > 4 , "Favorites Album should have at least 4 images")
           // get the category to create correct pglsourceFilter

           for aFilter in theCategory.filterDescriptors {

                 Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("PGLSourceFilterTests \(#function) testing filter \(aFilter.displayName) \(String(describing: aFilter.filterName))")
               let pglFilter = aFilter.pglSourceFilter()!

               XCTAssertNotNil(pglFilter)
               pglFilter.setDefaults()

               let imageAttributesNames = pglFilter.imageInputAttributeKeys
               for index in 0 ..< imageAttributesNames.count {
                   let imageValue = favoritesAlbumList.image(atIndex: index)!
                   if index == 0 { firstExtent = imageValue.extent }
                   pglFilter.setImageValue(newValue: imageValue , keyName: imageAttributesNames[index])
               }

               if let  result = pglFilter.outputImage(){
                XCTAssertTrue( (result.extent.width > 0) && (result.extent.height > 0), "result extent is zero width/height")

                   guard let cgImage1 =  context.createCGImage(result, from: firstExtent)
                       else { XCTFail("failed CGImage creation from result filter \(aFilter.displayName) \(String(describing: aFilter.filterName))")
                           continue // to the next filter in the iteration
                   }
                   let image1 = UIImage(cgImage: cgImage1)
                   for _ in 1...100 {pglFilter.addStepTime()}
                   let result2 = pglFilter.outputImage()
                XCTAssertTrue( (result.extent.width > 0) && (result.extent.height > 0), "result extent is zero width/height")

                   let image2 = UIImage(cgImage:context.createCGImage(result2!, from: firstExtent)!)
                   XCTAssertNotNil(image1)
                   XCTAssertNotNil(image2)
                   XCTAssertFalse( image1.isEqual( image2), "Did not change output image")

               } else {
                   XCTFail("no output image filter \(theCategory.categoryName) \(aFilter.displayName) \(String(describing: aFilter.filterName))")
               }
           }
       }

    func testGeneratorFilters() {
            // test Color  filters
            // test that image shows is displayed
        let theCategory = PGLFilterCategory("CICategoryGenerator")!
        var firstExtent = CGRect(origin: CGPoint.zero, size: CGSize(width: 100, height: 100))
        let context = CIContext()
        let favoritesAlbumList = fetchFavoritesList()
        XCTAssert(favoritesAlbumList.assetIDs.count > 4 , "Favorites Album should have at least 4 images")
        // get the category to create correct pglsourceFilter

        for aFilter in theCategory.filterDescriptors {

              Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("PGLSourceFilterTests \(#function) testing filter \(aFilter.displayName) \(String(describing: aFilter.filterName))")
            let pglFilter = aFilter.pglSourceFilter()!

            XCTAssertNotNil(pglFilter)
            pglFilter.setDefaults()

            let imageAttributesNames = pglFilter.imageInputAttributeKeys
            for index in 0 ..< imageAttributesNames.count {
                let imageValue = favoritesAlbumList.image(atIndex: index)!
                if index == 0 { firstExtent = imageValue.extent }
                pglFilter.setImageValue(newValue: imageValue , keyName: imageAttributesNames[index])
            }

            if let  result = pglFilter.outputImage(){
                XCTAssertTrue( (result.extent.width > 0) && (result.extent.height > 0), "result extent is zero width/height")

                guard let cgImage1 =  context.createCGImage(result, from: firstExtent)
                    else { XCTFail("failed CGImage creation from result filter \(aFilter.displayName) \(String(describing: aFilter.filterName))")
                        continue // to the next filter in the iteration
                }
                let image1 = UIImage(cgImage: cgImage1)
                for _ in 1...100 {pglFilter.addStepTime()}
                let result2 = pglFilter.outputImage()
                XCTAssertTrue( (result.extent.width > 0) && (result.extent.height > 0), "result extent is zero width/height")

                let image2 = UIImage(cgImage:context.createCGImage(result2!, from: firstExtent)!)
                XCTAssertNotNil(image1)
                XCTAssertNotNil(image2)
                XCTAssertFalse( image1.isEqual( image2), "Did not change output image")

            } else {
                XCTFail("no output image filter \(theCategory.categoryName) \(aFilter.displayName) \(String(describing: aFilter.filterName))")
            }
        }
    }

    func testInputListChange() {
        // confirm that changing the inputList of filter image parm will delete the stored value

        
    }
    func testDynamicFilterAttributeClass() {
        let testFilterNames = ["CISpotColor" , "CICopyMachineTransition"]

        for aFilterName in testFilterNames {
            Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("testDynamicFilterAttributeClass filter = \(aFilterName)")
        let colorFilter = PGLSourceFilter(filter: aFilterName )

        for spotAttribute in (colorFilter?.attributes)! {
            switch spotAttribute {

                case let anAttribute as PGLFilterAttributeColor:
                        XCTAssert(type(of: anAttribute) == PGLFilterAttributeColor.self )
                case let anAttribute as PGLAttributeRectangle:
                            XCTAssert(type(of: anAttribute) == PGLAttributeRectangle.self )
                case let anAttribute as PGLFilterAttributeAngle:
                        XCTAssert(type(of: anAttribute) == PGLFilterAttributeAngle.self )
                case let anAttribute as PGLFilterAttributeImage:
                    XCTAssert(type(of: anAttribute) == PGLFilterAttributeImage.self )
                case let anAttribute as PGLFilterAttributeNumber:
                    XCTAssert(type(of: anAttribute) == PGLFilterAttributeNumber.self )
                case let anAttribute as PGLFilterAttributeTime:
                    XCTAssert(type(of: anAttribute) == PGLFilterAttributeTime.self )
                default:
                        let attributeType = type(of: spotAttribute)
                        XCTAssert(attributeType == PGLFilterAttribute.self )
                        if (attributeType != PGLFilterAttribute.self ) {
                            Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("Attribute class of \(String(describing: spotAttribute.attributeName))is \(attributeType) PGLFilterAttribute") }

                }
            }
        }

    }

    func testCISpotColorFilter() {
        // test how the subclass of PGLFilterAttribute works for the CISpotColor filter

        let colorFilter = PGLSourceFilter(filter: "CISpotColor" )
        let colorAttribute = colorFilter?.attributes[1]  as? PGLFilterAttributeColor  // expected to have inputCenterColor1

        XCTAssertNotNil(colorAttribute)
        let color1 = colorAttribute?.getColorValue()

        XCTAssertNotNil(color1)
        if let attributeRed = colorAttribute?.red {
            XCTAssert(attributeRed > 0.0) } else {XCTAssertNotNil(colorAttribute?.red) }

        Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("testCISpotColorFilter color1 = \(String(describing: color1))")
    }
    
//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }
    
}
