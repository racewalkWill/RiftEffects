//
//  PGLCategorySurvey.swift
//  SurrealityTests
//
//  Created by Will on 8/5/20.
//  Copyright © 2020 Will Loew-Blosser. All rights reserved.
//

import XCTest
import Photos
import os
import CoreData

@testable import RiftEffects

class PGLCategorySurvey: XCTestCase {
    let context = CIContext()
    var favoritesAlbumList: PGLAlbumSource?
    var appStack: PGLAppStack!
    let saveOutputToPhotoLib = false  // change to true as needed
    lazy var dataProvider: PGLStackProvider = {
       let appDelegate = UIApplication.shared.delegate as? AppDelegate
       let provider = PGLStackProvider(with: appDelegate!.dataWrapper.persistentContainer,
                                   fetchedResultsControllerDelegate: nil)
       return provider
   }()
    var deleteStackIds = [NSManagedObjectID]()

    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        favoritesAlbumList = fetchFavoritesList()
        // ensure the PGLImageController is open and can do the saveToPhotosLibrary

        let myAppDelegate =  UIApplication.shared.delegate as! AppDelegate
        appStack = myAppDelegate.appStack
        deleteStackIds = [NSManagedObjectID]()  //

    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
//        let myAppDelegate =  UIApplication.shared.delegate as! AppDelegate
//               myAppDelegate.saveContext() // checks if context has changes

        let newStack = PGLFilterStack()
        newStack.setStartupDefault() // not sent in the init.. need a starting point
        self.appStack.resetToTopStack(newStack: newStack)
        dataProvider.batchDelete(deleteIds: deleteStackIds)
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

//    func fetchFavoritesList() ->  PGLAlbumSource? {
//        //MARK: Move to PGLDemo
//            let userFavorites = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumFavorites , options: nil)
//
//
//            if let theFavoriteAlbum = userFavorites.firstObject {
//                 let fetchResultAssets = PHAsset.fetchAssets(in: theFavoriteAlbum , options: nil)
//                let theInfo =  PGLAlbumSource(theFavoriteAlbum,fetchResultAssets)
//    //                                          init(_ assetAlbum: PHAssetCollection, _ result: PHFetchResult<PHAsset>? ))
//                                // init(_ assetAlbum: PHAssetCollection, _ result: PHFetchResult<PHAsset>? )
//                return theInfo
//
//            }
//            return nil
//
//        }

    func add9FiltersTo(stack: PGLFilterStack) {
        // put 9 random filters on the stack
        //MARK: Move to PGLDemo

        for aGroup in PGLCategorySurvey.SingleFilterGroups {
                let aFilterIndex = Int.random(in: 0 ..< aGroup.count)
                let thisFilter = aGroup[aFilterIndex].pglSourceFilter()
                thisFilter?.setDefaults()
            Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("addFiltersTo \(thisFilter!.localizedName()) \(String(describing: thisFilter!.filterName))")
            let imageAttributesNames = thisFilter!.imageInputAttributeKeys
                for anImageAttributeName in imageAttributesNames {
                    if anImageAttributeName == kCIInputImageKey { continue
                        // skip the default.. adding to the stack will set the input
                    }
                    guard let thisAttribute = thisFilter!.attribute(nameKey: anImageAttributeName) else { continue }
                   setInputTo(imageParm: thisAttribute) // the six images from favorites
               }
//            stack.append(thisFilter!) this just adds without an input
            stack.appendFilter(thisFilter!) // this sets the input
            let outputImage = stack.outputImage()
            XCTAssertNotNil(outputImage)
            if outputImage != nil {
            XCTAssertTrue( (outputImage!.extent.width > 0) && (outputImage!.extent.height > 0), " \(stack) outputImage extent is zero width/height")
            }

        }

    }

    func setInputTo(imageParm: PGLFilterAttribute) {
        //MARK: Move to PGLDemo
        guard let favoriteAlbumSource = fetchFavoritesList() else
                   {
            DispatchQueue.main.async {
                // put back on the main UI loop for the user alert
                let alert = UIAlertController(title: "Favorites Album", message: "Favorites is empty ", preferredStyle: .alert)

                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
                Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("The userSaveErrorAlert alert occured.")
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
        if imageParm.isTransitionFilter { allowedAssetCount = 6 }
        let maxIndex = favoriteAssets!.count
        while selectedAssets.count < allowedAssetCount {
            let randomIndex = Int.random(in: 0 ..< maxIndex)
            selectedAssets.append(favoriteAssets![randomIndex])
        }

        let userSelectionInfo = PGLUserAssetSelection(assetSources: favoriteAlbumSource)
        for anAsset in selectedAssets {
            Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("parm = \(String(describing: imageParm.attributeName)) added local id = \(anAsset.localIdentifier)")
            userSelectionInfo.addSourceToSelection(asset: anAsset)
        }

         //use first 6 images of the favorites if a transition filter
        // otherwise just one image
        userSelectionInfo.setUserPick()
    }

    // create class vars to hold each of the categories of filters
    // for each test case chain filters from a set of several categories.. one filter
    // per category... and 1 to 5 categories covered
    // cover all

    // MARK: Class var category filterDescriptors
    // MARK: move to PGLDemo
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
            let newStack = PGLFilterStack()
            newStack.setStartupDefault() // not sent in the init.. need a starting point
            self.appStack.resetToTopStack(newStack: newStack)
            
            let testFilterStack = appStack.viewerStack
                // should use the appStack to supply the filterStack


            let firstFilter = testFilterStack.currentFilter()
            guard let firstFilterInput = firstFilter.attribute(nameKey: "inputImage") else { return XCTFail() }
             setInputTo(imageParm: firstFilterInput) // sets 6 images from favorites album

            category1Filter = group1[category1Index].pglSourceFilter()!

            // check if this is really a single image input filter - the blend with mask filters in stylize take three
             let imageAttributesNames = category1Filter.imageInputAttributeKeys
            if imageAttributesNames.count > 1 {
                category1Index += 1
                continue
                // exit this loop iteration and go to the next category1Index value
            }
            category1Filter.setDefaults()
            testFilterStack.append(category1Filter)

            if category2Index < (group2.count - 1) {
                category2Index += 1
            } else {
                category2Index = 0
            }
            category2Filter = group2[category2Index].pglSourceFilter()!
            let imageAttributesCategory2 = category2Filter.imageInputAttributeKeys
                      if imageAttributesCategory2.count > 1 {
                          // category2Filter is incremented on the next loop
                          continue
                          // exit this loop iteration and go to the next category1Index value
                      }
            category2Filter.setDefaults()
            testFilterStack.append(category2Filter)

            let stackResultImage = testFilterStack.stackOutputImage(false)
            XCTAssertNotNil(stackResultImage)
            XCTAssertTrue( (stackResultImage.extent.width > 0) && (stackResultImage.extent.height > 0), "oldImage extent is zero width/height")
            XCTAssert(testFilterStack.activeFilters.count == 3, "stack does not have three filters as expected" )
            testFilterStack.stackName = category1Filter.filterName + "+" + category2Filter.filterName
            testFilterStack.stackType = "testSingleInputFilters"
            if saveOutputToPhotoLib {
                testFilterStack.exportAlbumName = "testSingleInputFilters" }
            else { testFilterStack.exportAlbumName = nil }
            // set the stack with the title, type, exportAlbum for save
            Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("PGLCategorySurvey #testSingleInputFilters at groups \(i)  \(testFilterStack.stackName)")
            testFilterStack.saveTestStackImage(stackProvider: dataProvider )
            if let stackID = testFilterStack.storedStack?.objectID {
                deleteStackIds.append(stackID) }
           // confirm that output is saved and the coreData has saved

            category1Index += 1



        }
        }
    }

    func testMultipleInputTransitionFilters() {
        //MARK: Move to PGLDemo
        var category1Index = 0

        var category1Filter: PGLSourceFilter



        for i in 0 ..< PGLCategorySurvey.CompositeGroups.count {

            let group1 = PGLCategorySurvey.CompositeGroups[i]

            while category1Index < group1.count {
                let newStack = PGLFilterStack()
                newStack.setStartupDefault() // not sent in the init.. need a starting point
                self.appStack.resetToTopStack(newStack: newStack)

                let testFilterStack = appStack.viewerStack
                    // should use the appStack to supply the filterStack


                _ = testFilterStack.removeLastFilter() // only one at start

                category1Filter = group1[category1Index].pglSourceFilter()!
                category1Filter.setDefaults()

                Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("testMultipleInputTransitionFilters group1 filter \(category1Filter.fullFilterName())")
                let imageAttributesNames = category1Filter.imageInputAttributeKeys
                for anImageAttributeName in imageAttributesNames {
                    guard let thisAttribute = category1Filter.attribute(nameKey: anImageAttributeName) else { continue }
                    setInputTo(imageParm: thisAttribute) // the six images from favorites
                }

                testFilterStack.append(category1Filter)

                add9FiltersTo(stack: testFilterStack)

                let stackResultImage = testFilterStack.stackOutputImage(false)
                XCTAssertNotNil(stackResultImage)
                XCTAssertTrue( (stackResultImage.extent.width > 0) && (stackResultImage.extent.height > 0), "oldImage extent is zero width/height")

                testFilterStack.stackName = category1Filter.filterName + "+ various filters"
                testFilterStack.stackType = "testMultipleInputTransitionFilters"
                if saveOutputToPhotoLib {
                    testFilterStack.exportAlbumName = "testMultipleInputTransitionFilters" }
                else { testFilterStack.exportAlbumName = nil }

                // set the stack with the title, type, exportAlbum for save
                Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("PGLCategorySurvey #testMultipleInputTransitionFilters at groups \(i)  \(testFilterStack.stackName)")
                testFilterStack.saveTestStackImage(stackProvider: dataProvider )
                if let stackID = testFilterStack.storedStack?.objectID {
                    deleteStackIds.append(stackID) }
               // confirm that output is saved and the coreData has saved

                category1Index += 1



            }
        }
    }

    func testSelectedMultipleFilters() {
        // paste in a filter list from a failed test run
        // this will build the list and test for zero extent in each filter output
        
        let testGroupFilters = [
            // list the filters
            "CILuminosityBlendMode",


            "CIMorphologyGradient",
            "CIExposureAdjust",
            "CIPhotoEffectInstant",
            "CIEdges",
            "BumpBlend",
            "CIAffineTransform",
            "CIUnsharpMask",
            "CICircularScreen"
            ]

        let constructedCategory = PGLFilterCategory("constructedCategory")!
        let descriptors = constructedCategory.buildCategoryFilterDescriptors(filterNames: testGroupFilters)

        let newStack = PGLFilterStack()
        newStack.setStartupDefault() // not sent in the init.. need a starting point
        self.appStack.resetToTopStack(newStack: newStack)
        let testFilterStack = appStack.viewerStack
            // should use the appStack to supply the filterStack

        _ = testFilterStack.removeLastFilter() // only one at start

        let category1Filter = descriptors.first?.pglSourceFilter()
        XCTAssertNotNil(category1Filter, "Failed to load filter \(testGroupFilters[0])")
        category1Filter!.setDefaults()

        Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("testSelectedMultipleInputTransitionFilters group1 filter \(category1Filter!.fullFilterName())")
        let imageAttributesNames = category1Filter!.imageInputAttributeKeys
        for anImageAttributeName in imageAttributesNames {
            guard let thisAttribute = category1Filter!.attribute(nameKey: anImageAttributeName) else { continue }
            setInputTo(imageParm: thisAttribute) // the six images from favorites
        }

        testFilterStack.append(category1Filter!)

        for filterNameIndex in 1 ..< testGroupFilters.count {
            let newFilter = descriptors[filterNameIndex].pglSourceFilter()
            XCTAssertNotNil(newFilter)
            newFilter!.setDefaults()

            let imageAttributesNames = newFilter!.imageInputAttributeKeys
            for anImageAttributeName in imageAttributesNames {
                guard let thisAttribute = newFilter!.attribute(nameKey: anImageAttributeName) else { continue }
                setInputTo(imageParm: thisAttribute) // the six images from favorites
            }
            Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("testSelectedMultipleInputTransitionFilters appending filter: \(String(describing: newFilter!.filterName))")
            testFilterStack.append(newFilter!)
            // check each filter added
            let stackResultImage = testFilterStack.stackOutputImage(false)
            XCTAssertNotNil(stackResultImage)
            XCTAssertTrue( (stackResultImage.extent.width > 0) && (stackResultImage.extent.height > 0), "oldImage extent is zero width/height")

        }


        testFilterStack.stackName = category1Filter!.filterName + " + testGroup filters"
        testFilterStack.stackType = "testSelectedFilters"
        if saveOutputToPhotoLib {
            testFilterStack.exportAlbumName = "testSelectedFilters" }
        else { testFilterStack.exportAlbumName = nil }
            // sets the stack with the title, type, exportAlbum for save

        testFilterStack.saveTestStackImage(stackProvider: dataProvider )
        if let stackID = testFilterStack.storedStack?.objectID {
            deleteStackIds.append(stackID) }
       // confirm that output is saved and the coreData has saved


    }

    func testiOS13Filters() {
          /*   CIDocumentEnhancer
               CIGaborGradients
               CIKeystoneCorrectionCombined
               CIKeystoneCorrectionHorizontal
               CIKeystoneCorrectionVertical
               CIKMeans
               CIMorphologyRectangleMaximum
               CIMorphologyRectangleMinimum
               CIPaletteCentroid
               CIPalettize
               CIPerspectiveRotate
        */
        var newFilter: PGLSourceFilter

        let iOS13FilterNames = [
            "CIDocumentEnhancer",
            "CIGaborGradients",
             "CIKeystoneCorrectionCombined",
             "CIKeystoneCorrectionHorizontal",
             "CIKeystoneCorrectionVertical",
 //           PGLFilterCategory.failingFilter             "CIKMeans",
             "CIMorphologyRectangleMaximum",
             "CIMorphologyRectangleMinimum",
//           PGLFilterCategory.failingFilter  "CIPaletteCentroid",
//           PGLFilterCategory.failingFilter              "CIPalettize",
             "CIPerspectiveRotate"
        ]

        let iOS13Category = PGLFilterCategory("ios13Filters")!
        let descriptors = iOS13Category.buildCategoryFilterDescriptors(filterNames: iOS13FilterNames)

        for ios13FilterDescriptor in descriptors {
            let newStack = PGLFilterStack()
              newStack.setStartupDefault() // not sent in the init.. need a starting point
              self.appStack.resetToTopStack(newStack: newStack)
              let testFilterStack = appStack.viewerStack
                  // should use the appStack to supply the filterStack
            _ = testFilterStack.removeLastFilter() // only one at start

            newFilter = ios13FilterDescriptor.pglSourceFilter()!
            newFilter.setDefaults()

            XCTAssertNotNil(newFilter)
            let imageAttributesNames = newFilter.imageInputAttributeKeys
            for anImageAttributeName in imageAttributesNames {
                guard let thisAttribute = newFilter.attribute(nameKey: anImageAttributeName) else { continue }
                setInputTo(imageParm: thisAttribute) // the six images from favorites
            }
            testFilterStack.append(newFilter)

            let stackResultImage = testFilterStack.stackOutputImage(false)
               XCTAssertNotNil(stackResultImage)
            XCTAssertTrue( (stackResultImage.extent.width > 0) && (stackResultImage.extent.height > 0), "\(String(describing: newFilter.filterName)) extent is zero width/height")
               testFilterStack.stackName = newFilter.filterName
               testFilterStack.stackType = "testiOS13Filters"

            if saveOutputToPhotoLib {
                testFilterStack.exportAlbumName = "exportTestiOS13Filters" }
            else { testFilterStack.exportAlbumName = nil }
               // set the stack with the title, type, exportAlbum for save
               Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("PGLCategorySurvey #testiOS13Filters  \(testFilterStack.stackName)")
                testFilterStack.saveTestStackImage(stackProvider: dataProvider )
            if let stackID = testFilterStack.storedStack?.objectID {
                deleteStackIds.append(stackID) }
               // confirm that output is saved and the coreData has saved
        }

       }

    func testCompositeChildStack() {
        // static var CompositeGroups = [CompositeFilters, TransistionFilters]


        var category1Filter: PGLSourceFilter
        var child1Filter: PGLSourceFilter
        var childFilterName: String!



        let group1 = PGLCategorySurvey.CompositeFilters
         let testSize =  group1.count // 2

        for filterIndex in (0..<testSize) {

                   let newStack = PGLFilterStack()
                   newStack.setStartupDefault() // not sent in the init.. need a starting point
                   self.appStack.resetToTopStack(newStack: newStack)

                   let testFilterStack = appStack.viewerStack
                       // should use the appStack to supply the filterStack


                    _ = testFilterStack.removeLastFilter() // only one at start
                    let aFilterIndex = Int.random(in: 0 ..< PGLCategorySurvey.DistortFilters.count)

                category1Filter = PGLCategorySurvey.DistortFilters[aFilterIndex].pglSourceFilter()!
                   category1Filter.setDefaults()

                   Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("testCompositeChildStack group1 filter = \(category1Filter.localizedName())")
                   let imageAttributesNames = category1Filter.imageInputAttributeKeys
                   for anImageAttributeName in imageAttributesNames {
                       guard let thisAttribute = category1Filter.attribute(nameKey: anImageAttributeName) else { continue }
                       setInputTo(imageParm: thisAttribute) // the six images from favorites
                    }

                   testFilterStack.append(category1Filter)

                    // Create a child stack and append to one of the image inputs
                if imageAttributesNames.count > 0 {
                    guard let stackInputAttribute = category1Filter.attribute(nameKey: imageAttributesNames[0]) else { continue }
                    appStack.addChildStackTo(parm: stackInputAttribute)
                    let childStack = appStack.viewerStack // the new childStack
//                    _ = childStack.removeLastFilter()

                    child1Filter = group1[filterIndex].pglSourceFilter()!
                    childFilterName = child1Filter.filterName
                        // set the image inputs of childFilter1
                    let imageAttributesNames = child1Filter.imageInputAttributeKeys
                        for anImageAttributeName in imageAttributesNames {

                            guard let thisAttribute = child1Filter.attribute(nameKey: anImageAttributeName) else { continue }
                           setInputTo(imageParm: thisAttribute) // the six images from favorites
                       }
                    childStack.append(child1Filter)


                }

                let stackResultImage = testFilterStack.stackOutputImage(false)
               XCTAssertNotNil(stackResultImage)
            XCTAssertTrue( (stackResultImage.extent.width > 0) && (stackResultImage.extent.height > 0), "oldImage extent is zero width/height")

               testFilterStack.stackName = category1Filter.filterName + " " + childFilterName
               testFilterStack.stackType = "testCompositeChildStack"

                if saveOutputToPhotoLib {
                    testFilterStack.exportAlbumName = "testCompositeChildStack" }
                else { testFilterStack.exportAlbumName = nil }

               // set the stack with the title, type, exportAlbum for save
               Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("PGLCategorySurvey #testCompositeChildStack  \(testFilterStack.stackName)")
              testFilterStack.saveTestStackImage(stackProvider: dataProvider )
            if let stackID = testFilterStack.storedStack?.objectID {
                deleteStackIds.append(stackID) }


            }

    }

    func testTransitionChildStacks() {
        // put a transition on a child stack
        // static var CompositeGroups = [CompositeFilters, TransistionFilters]


        var category1Filter: PGLSourceFilter
        var child1Filter: PGLSourceFilter
        var childFilterName: String!

//        for i in 0 ..< PGLCategorySurvey.CompositeGroups.count {


        let group1 = PGLCategorySurvey.TransistionFilters
         let testSize =  group1.count

//        while category1Index <  testSize {
        for filterIndex in ( 0..<testSize) {

                   let newStack = PGLFilterStack()
                   newStack.setStartupDefault() // not sent in the init.. need a starting point
                   self.appStack.resetToTopStack(newStack: newStack)

                   let testFilterStack = appStack.viewerStack
                       // should use the appStack to supply the filterStack


                    _ = testFilterStack.removeLastFilter() // only one at start
                    let aFilterIndex = Int.random(in: 0 ..< PGLCategorySurvey.DistortFilters.count)

                category1Filter = PGLCategorySurvey.DistortFilters[aFilterIndex].pglSourceFilter()!
                   category1Filter.setDefaults()

                   Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("testTransitionChildStacks group1 filter = \(category1Filter.localizedName())")
                   let imageAttributesNames = category1Filter.imageInputAttributeKeys
                   for anImageAttributeName in imageAttributesNames {
                       guard let thisAttribute = category1Filter.attribute(nameKey: anImageAttributeName) else { continue }
                       setInputTo(imageParm: thisAttribute) // the six images from favorites
                    }

                   testFilterStack.append(category1Filter)

                    // Create a child stack and append to one of the image inputs
                if imageAttributesNames.count > 0 {
                    guard let stackInputAttribute = category1Filter.attribute(nameKey: imageAttributesNames[0]) else { continue }
                    appStack.addChildStackTo(parm: stackInputAttribute)
                    let childStack = appStack.viewerStack // the new childStack
                    _ = childStack.removeLastFilter()

                    child1Filter = group1[filterIndex].pglSourceFilter()!
                    childFilterName = child1Filter.filterName
                        // set the image inputs of childFilter1
                    let imageAttributesNames = child1Filter.imageInputAttributeKeys
                        for anImageAttributeName in imageAttributesNames {

                            guard let thisAttribute = child1Filter.attribute(nameKey: anImageAttributeName) else { continue }
                           setInputTo(imageParm: thisAttribute) // the six images from favorites
                       }
                    childStack.append(child1Filter)


                }

                let stackResultImage = testFilterStack.stackOutputImage(false)
               XCTAssertNotNil(stackResultImage)
            XCTAssertTrue( (stackResultImage.extent.width > 0) && (stackResultImage.extent.height > 0), "oldImage extent is zero width/height")

               testFilterStack.stackName = category1Filter.filterName + " " + childFilterName
               testFilterStack.stackType = "testTransitionChildStacks"

                if saveOutputToPhotoLib {
                    testFilterStack.exportAlbumName = "testTransitionChildStacks" }
                else { testFilterStack.exportAlbumName = nil }

               // set the stack with the title, type, exportAlbum for save
               Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("PGLCategorySurvey #testTransitionChildStacks  \(testFilterStack.stackName)")
              testFilterStack.saveTestStackImage(stackProvider: dataProvider )
            if let stackID = testFilterStack.storedStack?.objectID {
                deleteStackIds.append(stackID) }

            }

    }
    func testSelectedFilters() {

            var newFilter: PGLSourceFilter
            // from a failing testMultipleInput run
            let filterNames = [
// zero extent output failing filters 2021-04-20
                "CICircleSplashDistortion",
                "CIClamp",   // failed 2021-08-16  others passed on this run
                "CITriangleTile",

                "CIKeystoneCorrectionHorizontal",
                "CIUnsharpMask",
                "CIHatchedScreen"


                // old list below
//                "CICircleSplashDistortion",
//                "FaceFilter",
//                 "CIAdditionCompositing",
//                 "CIVibrance",
//                 "CIColorMap",
//                 "CIDepthOfField",
//                 "CITorusLensDistortion",
//
//                 "CISharpenLuminance",
//                 "CICMYKHalftone",
//                 "CIClamp",
//                // 2020-10-20 failing filters
//              "CIHeightFieldFromMask",
//               "CIEdges",
//                "CICrystallize",
//                "CICMYKHalftone",
//                "CIGaborGradients",
//                "CIAdditionCompositing",
//                "CIDepthBlurEffect",
//                "CIExposureAdjust",
//                "CIPhotoEffectMono",
//                "CIHexagonalPixellate",
//                "CIBumpDistortionLinear",
//                "CIKeystoneCorrectionVertical",
//                "CIUnsharpMask",
//                "CILineScreen",
//                "CITriangleTile",
//
//                // 2020-12-18 failed filter
//                "CIColorAbsoluteDifference",
//
//                "CINinePartStretched"


            ]

            let constructedCategory = PGLFilterCategory("constructedCategory")!
            let descriptors = constructedCategory.buildCategoryFilterDescriptors(filterNames: filterNames)

            for aFilterDescriptor in descriptors {
                let newStack = PGLFilterStack()
                  newStack.setStartupDefault() // not sent in the init.. need a starting point
                  newStack.removeDefaultFilter()
                  self.appStack.resetToTopStack(newStack: newStack)
                  let testFilterStack = appStack.viewerStack
                      // should use the appStack to supply the filterStack
//                _ = testFilterStack.removeLastFilter() // only one at start

                newFilter = aFilterDescriptor.pglSourceFilter()!
                newFilter.setDefaults()

                XCTAssertNotNil(newFilter)
                let imageAttributesNames = newFilter.imageInputAttributeKeys
                for anImageAttributeName in imageAttributesNames {
                    guard let thisAttribute = newFilter.attribute(nameKey: anImageAttributeName) else { continue }
                    setInputTo(imageParm: thisAttribute) // the six images from favorites
                }
                testFilterStack.append(newFilter)
                Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("PGLCategorySurvey #testSelectedFilters newFilter = \(newFilter.fullFilterName())")
                let stackResultImage = testFilterStack.stackOutputImage(false)
                   XCTAssertNotNil(stackResultImage)
                XCTAssertTrue( (stackResultImage.extent.width > 0) && (stackResultImage.extent.height > 0), "ciImage extent is zero width/height")

                   testFilterStack.stackName = newFilter.fullFilterName()
                   testFilterStack.stackType = "testSelectedFilters"
               
                if saveOutputToPhotoLib {
                    testFilterStack.exportAlbumName = "ExportTestSelectedFilters" }
                else { testFilterStack.exportAlbumName = nil }
                   // set the stack with the title, type, exportAlbum for save
                   Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("PGLCategorySurvey #testSelectedFilters  \(testFilterStack.stackName)")
                    testFilterStack.saveTestStackImage(stackProvider: dataProvider )
                if let stackID = testFilterStack.storedStack?.objectID {
                    deleteStackIds.append(stackID) }
            }

           }



}
