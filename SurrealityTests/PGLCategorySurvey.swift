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

    func add9FiltersTo(stack: PGLFilterStack) {
        // put 9 random filters on the stack
        for aGroup in PGLCategorySurvey.SingleFilterGroups {
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
            stack.append(thisFilter!)

        }

    }

    func setInputTo(imageParm: PGLFilterAttribute) {
        guard let favoriteAlbumSource = fetchFavoritesList() else
                   { fatalError("favoritesAlbum contents not returned") }
        favoriteAlbumSource.filterParm = imageParm
        let favoriteAssets = favoriteAlbumSource.assets() // converts to PGLAsset
       // mix it up with photos

        var selectedAssets = [PGLAsset]()
        let maxIndex = favoriteAssets!.count
        while selectedAssets.count <= 6 {
            let randomIndex = Int.random(in: 0 ..< maxIndex)
            selectedAssets.append(favoriteAssets![randomIndex])
        }

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

    func testMultipleInputTransitionFilters() {
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

                NSLog("testMultipleInputTransitionFilters group1 filter = \(category1Filter.localizedName()) \(String(describing: thisFilter!.filterName))")
                let imageAttributesNames = category1Filter.imageInputAttributeKeys
                for anImageAttributeName in imageAttributesNames {
                    guard let thisAttribute = category1Filter.attribute(nameKey: anImageAttributeName) else { continue }
                    setInputTo(imageParm: thisAttribute) // the six images from favorites
                }

                testFilterStack.append(category1Filter)

                add9FiltersTo(stack: testFilterStack)

                let stackResultImage = testFilterStack.stackOutputImage(false)
                XCTAssertNotNil(stackResultImage)

                testFilterStack.stackName = category1Filter.filterName + "+ various filters"
                testFilterStack.stackType = "testMultipleInputTransitionFilters"
                testFilterStack.exportAlbumName = "testMultipleInputTransitionFilters"
                // set the stack with the title, type, exportAlbum for save
                NSLog("PGLCategorySurvey #testMultipleInputTransitionFilters at groups \(i)  \(testFilterStack.stackName)")
                let photoSaveResult =  testFilterStack.saveStackImage()
                XCTAssertTrue(photoSaveResult , testFilterStack.stackName + " Error on saveStackImage")

                category1Index += 1



            }
        }
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

               testFilterStack.stackName = newFilter.filterName
               testFilterStack.stackType = "testiOS13Filters"
               testFilterStack.exportAlbumName = "exportTestiOS13Filters"
               // set the stack with the title, type, exportAlbum for save
               NSLog("PGLCategorySurvey #testiOS13Filters  \(testFilterStack.stackName)")
               let photoSaveResult =  testFilterStack.saveStackImage()
               XCTAssertTrue(photoSaveResult , testFilterStack.stackName + " Error on saveStackImage")
        }

       }

    func testGeneratorChildStack() {
        // put a generator on a child stack
        var category1Index = 0

        var category1Filter: PGLSourceFilter

        let maxIterations = 2
//        for i in 0 ..< PGLCategorySurvey.CompositeGroups.count {
        NSLog("testGeneratorChildStack PGLCategorySurvey.CompositeGroups.count = \(PGLCategorySurvey.CompositeGroups.count)")
        for i in 0 ..< maxIterations {
               let group1 = PGLCategorySurvey.CompositeGroups[i]

            while category1Index < maxIterations {
//               while category1Index < group1.count {
                   let newStack = PGLFilterStack()
                   newStack.setStartupDefault() // not sent in the init.. need a starting point
                   self.appStack.resetToTopStack(newStack: newStack)

                   let testFilterStack = appStack.viewerStack
                       // should use the appStack to supply the filterStack


                _ = testFilterStack.removeLastFilter() // only one at start

                   category1Filter = group1[category1Index].pglSourceFilter()!
                   category1Filter.setDefaults()

                   NSLog("testGeneratorChildStack group1 filter = \(category1Filter.localizedName())")
                   let imageAttributesNames = category1Filter.imageInputAttributeKeys
                   for anImageAttributeName in imageAttributesNames {
                       guard let thisAttribute = category1Filter.attribute(nameKey: anImageAttributeName) else { continue }
                       setInputTo(imageParm: thisAttribute) // the six images from favorites
                    }

                   testFilterStack.append(category1Filter)

                    // Create a child stack and append to one of the image inputs
                if imageAttributesNames.count > 1 {
                    guard let stackInputAttribute = category1Filter.attribute(nameKey: imageAttributesNames[1]) else { continue }
                    appStack.addChildStackTo(parm: stackInputAttribute)
                    let childStack = appStack.viewerStack // the new childStack
                    _ = childStack.removeLastFilter()
                    let aFilterIndex = Int.random(in: 0 ..< PGLCategorySurvey.DistortFilters.count)
                    let childFilter1 = PGLCategorySurvey.DistortFilters[aFilterIndex].pglSourceFilter()

                    // set the image inputs of childFilter1
                    let imageAttributesNames = childFilter1!.imageInputAttributeKeys
                        for anImageAttributeName in imageAttributesNames {

                            guard let thisAttribute = childFilter1!.attribute(nameKey: anImageAttributeName) else { continue }
                           setInputTo(imageParm: thisAttribute) // the six images from favorites
                       }
                    childStack.append(childFilter1!)


                }

                let stackResultImage = testFilterStack.stackOutputImage(false)
               XCTAssertNotNil(stackResultImage)

               testFilterStack.stackName = category1Filter.filterName + "+ child filters"
               testFilterStack.stackType = "testGeneratorChildStack"
               testFilterStack.exportAlbumName = "testGeneratorChildStack"
               // set the stack with the title, type, exportAlbum for save
               NSLog("PGLCategorySurvey #testGeneratorChildStack at groups \(i)  \(testFilterStack.stackName)")
               let photoSaveResult =  testFilterStack.saveStackImage()
               XCTAssertTrue(photoSaveResult , testFilterStack.stackName + " Error on saveStackImage")

                category1Index += category1Index
            }
        }
    }

    func testSelectedFilters() {

            var newFilter: PGLSourceFilter
            // from a failing testMultipleInput run
            let filterNames = [
//                "CIDivideBlendMode",
//                "CIDepthBlurEffect" ,
//                 "CIColorMatrix",
//                 "CIColorMonochrome",
//                 "CIConvolution9Vertical",
//                 "CIDroste",
//                 "CIPerspectiveTransform",
//                 "CISharpenLuminance",
//                 "CICMYKHalftone",
//                 "CIClamp",
                // 2020-10-20 failing filters
//                "CIHeightFieldFromMask"
//               "CIEdges",
//                "CICrystallize",
//                "CICMYKHalftone",
//                "CIGaborGradients"
                "CIAdditionCompositing",
//                "CIDepthBlurEffect",
                "CIExposureAdjust",
                "CIPhotoEffectMono",
                "CIHexagonalPixellate",
                "CIBumpDistortionLinear",
                "CIKeystoneCorrectionVertical",
                "CIUnsharpMask",
                "CILineScreen",
                "CITriangleTile"

            ]

            let constructedCategory = PGLFilterCategory("constructedCategory")!
            let descriptors = constructedCategory.buildCategoryFilterDescriptors(filterNames: filterNames)

            for aFilterDescriptor in descriptors {
                let newStack = PGLFilterStack()
                  newStack.setStartupDefault() // not sent in the init.. need a starting point
                  self.appStack.resetToTopStack(newStack: newStack)
                  let testFilterStack = appStack.viewerStack
                      // should use the appStack to supply the filterStack
                _ = testFilterStack.removeLastFilter() // only one at start

                newFilter = aFilterDescriptor.pglSourceFilter()!
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

                   testFilterStack.stackName = newFilter.filterName
                   testFilterStack.stackType = "CIDivideBlendMode"
                   testFilterStack.exportAlbumName = "exportCIDivideBlendModeTest"
                   // set the stack with the title, type, exportAlbum for save
                   NSLog("PGLCategorySurvey #testSelectedFilters  \(testFilterStack.stackName)")
                   let photoSaveResult =  testFilterStack.saveStackImage()
                   XCTAssertTrue(photoSaveResult , testFilterStack.stackName + " Error on saveStackImage")
            }

           }



}
