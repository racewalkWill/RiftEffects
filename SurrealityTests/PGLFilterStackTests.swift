//
//  PGLFilterStackTests.swift
//  PictureGlance
//
//  Created by Will on 3/24/17.
//  Copyright © 2017 Will. All rights reserved.
//

import XCTest
import Photos

@testable import Surreality


class PGLFilterStackTests: XCTestCase {

    var filterStack: PGLFilterStack!  
    var testAppStack = PGLAppStack() // creates an empty filterStack
    var testCIImage: CIImage!
    var activeFilterCount = 0


    override func setUp() {
       // Put setup code here. This method is called before the invocation of each test method in the class.
        super.setUp()
        // change activeFilterCount if more filters are included in setup


       filterStack = testAppStack.viewerStack
        // filterStack gets one default filter
        // add two more
       guard let inputAttribute = filterStack.currentFilter().attribute(nameKey: kCIInputImageKey)
        else { XCTFail("setup filter does not have an input image parm")
              fatalError()
        }
        guard let favoriteAlbumSource = fetchFavoritesList() else
            { fatalError("favoritesAlbum contents not returned") }
        favoriteAlbumSource.filterParm = inputAttribute

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


        if let bumpFilter = PGLSourceFilter(filter: "CIBumpDistortion") {
            bumpFilter.setDefaults()
            filterStack.appendFilter(bumpFilter) }

        // 2018-12-14  most of the tile filters seem to error.. skip CIPerspectiveTile for now..
        // CIKaleidoscope does work in tile category..
        if let tileFilter = PGLSourceFilter(filter: "CIKaleidoscope") {
            tileFilter.setDefaults()
            filterStack.appendFilter(tileFilter)
        }
        activeFilterCount = filterStack.activeFilters.count
        NSLog("PGLFilterStackTests setup activeFilterCount = \(activeFilterCount)")

        filterStack.stackType = "testCase PGLFilterStackTests"

    }

    override  func tearDown() {
        let myAppDelegate =  UIApplication.shared.delegate as! AppDelegate
        myAppDelegate.saveContext()
        let newStack = PGLFilterStack()
        newStack.setStartupDefault() // not sent in the init.. need a starting point
        testAppStack.resetToTopStack(newStack: newStack)
        super.tearDown()
    }

    func fetchFavoritesList() -> PGLAlbumSource? {
        
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

    func testStackSetup() {
        // shows that the suite setup has an output image
        // and save the output image
        filterStack.stackName = "testStackSetup" + " \(Date())"
        _ = filterStack.writeCDStack()
        XCTAssertNotNil(filterStack.storedStack)
        

    }
    func testThreeFilterStack() {
        XCTAssert(filterStack.activeFilters.count == 3)
        let output = filterStack.outputImage()
        XCTAssertNotNil(output)
    }

   

    func testAddDeleteFilters() {
        // show removing a filter from a stored stack
        // show adding a filter to a stored stack.
        let defaultTitle = "testAddDeleteFilters" +  " \(Date())"
        filterStack.stackName = defaultTitle
        NSLog("PGLFilterStackTests #testWriteStack() stackName = \(defaultTitle)")
        let writtenStack = filterStack.writeCDStack()
        NSLog("PGLFilterStackTests #testAddDeleteFilters wroteCDStack \(writtenStack)")


        _ = filterStack.removeLastFilter()
        XCTAssert(filterStack.activeFilters.count == activeFilterCount - 1)


        let savedStack = filterStack.writeCDStack() // should update with delete
        let newStack2 = PGLFilterStack()
        newStack2.on(cdStack: savedStack)
        XCTAssert(filterStack.activeFilters.count == newStack2.activeFilters.count)
        XCTAssert(filterStack.activeFilters.count == activeFilterCount - 1)

        // the managed object is the same on all three stacks
        XCTAssert(filterStack.storedStack === newStack2.storedStack)
        

        for aFilter in filterStack.activeFilters {
            NSLog("filterStack filter = \(String(describing: aFilter.filterName))")
        }

        for aFilter in newStack2.activeFilters {
            NSLog("newStack2 filter = \(String(describing: aFilter.filterName))")
        }

        

    }

    func testCycleSave() {
        //confirm that the multiple inputs to a filter are saved
        let stackName = "testCycleSave" +  " \(Date())"
        filterStack.stackName = stackName
        // need a filter then assign the test PGLImageList to it..
        // the save of the filter should create the CDImageList
        let aImageList = PGLDataStoreTests.imageListTestObject()
        // setImageCollectionInput(cycleStack: PGLImageList, firstAssetData: PHAsset)
        let currentFilterName = filterStack.currentFilter().filterName
        let currentFilterIndex = filterStack.activeFilterIndex
        if let anImageParm = filterStack.currentFilter().imageParms()?.first {
           anImageParm.setImageCollectionInput(cycleStack: aImageList)
           
        }

        let savedStack = filterStack.writeCDStack()
            // stack, filters, imageList should all be stored

        let aNewStack = PGLFilterStack()
        aNewStack.on(cdStack: savedStack)
        aNewStack.activeFilterIndex = currentFilterIndex // put back to saved position

        XCTAssert( aNewStack.currentFilter().filterName == currentFilterName)
        let storedImageParm = aNewStack.currentFilter().imageParms()?.first
        let storedImageList = storedImageParm!.inputCollection!
        let storedIDs =  (storedImageList.assetIDs).sorted()
        let listIDs = (aImageList.assetIDs).sorted()
        XCTAssert( storedIDs == listIDs )
        // fails due to different order of the elements


        // confirm that the stored data CDFi
    }

    func testInputFilterSave() {
        // one of the parms uses a filter stack as input..
        // save and read back
        let stackName = "testInputFilterSave" + " \(Date())"
         filterStack.stackName = stackName
        // need a filter then assign the test PGLImageList to it..
        // the save of the filter should create the CDImageList

        if let dissolveFilter = (PGLFilterDescriptor("CIDissolveTransition", PGLTransitionFilter.self))?.pglSourceFilter()
             {
            filterStack.replaceFilter(at: 0, newFilter: dissolveFilter)
        }
        if let blendFilter = PGLSourceFilter(filter: "CIBlendWithMask") {
            blendFilter.setDefaults()
            filterStack.moveActiveBack()
            if let aParm = filterStack.currentFilter().imageParms()?.first {
                NSLog("PGLFilterStackTests #testInputFilterSave to  \(filterStack.stackName)")
                NSLog("PGLFilterStackTests #testInputFilterSave to \(String(describing: filterStack.currentFilter().filterName))")
                NSLog("PGLFilterStackTests #testInputFilterSave to \(String(describing: aParm.attributeName))")

                testAppStack.addChildStackTo(parm: aParm)
                let newMasterStack = testAppStack.viewerStack

                XCTAssert(newMasterStack.currentFilter().filterName == defaultFilterName )
                newMasterStack.replace(updatedFilter: blendFilter)

                XCTAssert(newMasterStack.currentFilter().filterName == "CIBlendWithMask")
                XCTAssert((testAppStack.hasParentStack()))
                XCTAssert(testAppStack.viewerStack === newMasterStack)
                XCTAssert(testAppStack.outputFilterStack() === filterStack)



                testAppStack.showFilterImage = true // change output to the current stack
                XCTAssert(testAppStack.outputFilterStack() === newMasterStack)
                testAppStack.showFilterImage = false // change back

                let outputAttributes = testAppStack.outputFilterStack().currentFilter().attributes
                let inputStackAttribute = outputAttributes.filter( {$0.inputStack != nil} ).first
                let inputFilterPosition = testAppStack.outputFilterStack().activeFilterIndex
                let testInputStack = inputStackAttribute!.inputStack
                XCTAssertNotNil(outputAttributes)
                XCTAssertNotNil(testInputStack)
                NSLog("Filter with child inputStack = \(testAppStack.outputFilterStack().currentFilter())")
                NSLog("Filter position = \(inputFilterPosition)")
                NSLog("attribute \(String(describing: inputStackAttribute)) has inputStack \(String(describing: testInputStack))")

                _ = testAppStack.outputFilterStack().stackName
                 testAppStack.writeCDStacks()

                let newStack = PGLFilterStack()
                let newStackStored = testAppStack.firstStack()!.storedStack!
                newStack.on(cdStack: newStackStored)

                newStack.activeFilterIndex = inputFilterPosition
                let topAttributes = newStack.currentFilter().attributes
                let newInputStackAttribute = (topAttributes.filter( {$0.inputStack != nil} )).first
                XCTAssertNotNil(newInputStackAttribute)
                XCTAssert(newInputStackAttribute?.attributeName == inputStackAttribute?.attributeName)
                XCTAssertNotNil(newInputStackAttribute?.inputStack)
                XCTAssert(testInputStack!.stackName == newInputStackAttribute?.inputStack?.stackName)

                // compare all components of the stacks
//                let runFilters = testAppStack.outputFilterStack().activeFilters
//                let savedFilters = newStack.activeFilters
//                for (i, runFilter) in runFilters.enumerated() {
//                    let savedFilter = savedFilters[i]
//                    XCTAssert(runFilter.filterName == savedFilter.filterName)
//                    // continue the compare at the attributes level .. some typeCasting is needed for the
//                    // various subclasses of PGLFilterAttribute
//                }

            }

        }


    }



}
