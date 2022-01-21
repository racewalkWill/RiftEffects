//
//  PGLFilterDescriptorTests.swift
//  PictureGlance
//
//  Created by Will on 3/27/17.
//  Copyright © 2017 Will. All rights reserved.
//

import XCTest
import os

@testable import RiftEffects

class PGLFilterDescriptorTests: XCTestCase {
     let standardFilterName = "CIDiscBlur"
    let standardClass = PGLSourceFilter.self
    var appStack: PGLAppStack!

    override func setUp() {
        let myAppDelegate =  UIApplication.shared.delegate as! AppDelegate
        appStack = myAppDelegate.appStack
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        let newStack = PGLFilterStack()
        newStack.setStartupDefault() // not sent in the init.. need a starting point
        self.appStack.resetToTopStack(newStack: newStack)
        super.tearDown()
    }
    func testCategoryDescription() {
        let classCategories = [kCICategoryDistortionEffect,
                               kCICategoryGeometryAdjustment]
        for aCategory in classCategories {
            let allFilters = CIFilter.filterNames(inCategory: aCategory)
//            Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("all filters by category \(aCategory) = \(allFilters)")
            XCTAssertNotNil(allFilters)

        }


    }
    func testDescriptionFilterDescriptor() {
        // check that the print description is working
        let newDescriptor = PGLFilterDescriptor(standardFilterName, standardClass)
        XCTAssert(newDescriptor?.filterName == standardFilterName )  // should be a localized description

        XCTAssert(newDescriptor?.displayName != standardFilterName)



    }

    func testFilterCategory() {
        if let aCategory = PGLFilterCategory("CICategoryDistortionEffect") {
            XCTAssert(aCategory.filterDescriptors.count > 2) }
        else { XCTFail("did not create the filter category CICategoryDistortionEffect") }

    }

    func testAllFilterCategories() {
        let allCategories = PGLFilterCategory.allFilterCategories()

       let categoryGeometryAdjustment = allCategories[2]
//        Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice( "categoryGeometryAdjustment = \(categoryGeometryAdjustment)")

     XCTAssert(categoryGeometryAdjustment.filterDescriptors.count > 5 )
    }

    func testAllFilterCreation() {
        let allCategories = PGLFilterCategory.allFilterCategories()
        for aCategory in allCategories {
            let categoryFilterNames = CIFilter.filterNames(inCategory: aCategory.categoryConstant)

            for aFilterName in categoryFilterNames {
                Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("testing filter \(aFilterName) category \(aCategory.categoryConstant)")
                let thisFilterDescriptor = PGLFilterDescriptor(aFilterName, standardClass)
                // these filters should already be cached in the categories but checking direct creation here
                XCTAssertNotNil(thisFilterDescriptor?.filter, "CIFilter did not create filter /(aFilterName) from category \(aCategory.categoryConstant)")
                XCTAssertNotNil(thisFilterDescriptor?.pglSourceFilter(), "CIFilter did not create pglSourceFilter /(aFilterName) from category \(aCategory.categoryConstant)")
            }
            //            Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("all filters by category \(aCategory) = \(allFilters)")


        }
    }

    func testFilterDescriptionCapture() {
        // capture to the log all of the filter info for analysis
        var filterAttributes = [String:Any]()

        let allCategories = PGLFilterCategory.allFilterCategories()
        for aCategory in allCategories {
            let categoryFilterNames = CIFilter.filterNames(inCategory: aCategory.categoryConstant)

            for aFilterName in categoryFilterNames {
                filterAttributes = [String:Any]()
                Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("testing filter \(aFilterName) category \(aCategory.categoryConstant)")
                let thisFilterDescriptor = PGLFilterDescriptor(aFilterName, standardClass)
                // these filters should already be cached in the categories but checking direct creation here
                if let myFilter = thisFilterDescriptor?.pglSourceFilter() {
                    Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("\(aFilterName)")
                    Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("\(CIFilter.localizedDescription(forFilterName: aFilterName)!)" )

                    filterAttributes = (myFilter.localFilter.attributes)
                    Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("\(filterAttributes.description)")
                }
//                        Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("all filters by category \(aCategory) = \(allFilters)")


            }

        }
    }

    func testUnknownFilterAttributesList() {
        // capture to the log filter attributes that are not implemented for UI

        var nonUIParmCount = 0
        let allCategories = PGLFilterCategory.allFilterCategories()
        for aCategory in allCategories {
            let categoryFilterNames = CIFilter.filterNames(inCategory: aCategory.categoryConstant)

            for aFilterName in categoryFilterNames {
                if (PGLExcludeFilters.list.contains(aFilterName))
                    && (PGLExcludeFilters.skipFailingFilters)
                    {continue}
                let thisFilterDescriptor = PGLFilterDescriptor(aFilterName, standardClass)
                // these filters should already be cached in the categories but checking direct creation here
                if let myFilter = thisFilterDescriptor?.pglSourceFilter() {
                    let  filterAttributes = (myFilter.attributes)
                    for anAttribute in filterAttributes {
                        if anAttribute.attributeUIType() == AttrUIType.filterPickUI {
                            // pointUI, sliderUI, imagePickUI, rectUI are not filterPickUI.. interfaces exist
                            nonUIParmCount += 1
//                            Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("testing filter \(aFilterName) category \(aCategory.categoryConstant)")
                            Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("filter \(aFilterName) category \(aCategory.categoryConstant) NOT UI Parm \(anAttribute.description)")
                        }
                    }
                }
            }
        }
        Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("Count of nonUI Parms = \(nonUIParmCount)")
    }

    func testFilterAttributeCounter() {
        // capture to the log counts of filter classes, types
        var filterAttributes = [String:Any]()
        var filters = [String:CIFilter]()
        var attributeCounts = [0:0] // key is number of inputAttributes, value is number of occurences in all the filters
        var attributeTypeCounts = [String:Int]() // key is type name, value is number of occurences in all the filters
        var attributeClassCounts = [String:Int]() // key is class name , value is number of occurences in all the filters
        var countedFilter: CIFilter?
        var oldCount = 0
        var filtersUsingVectors = [String]()


        let allCategories = PGLFilterCategory.allFilterCategories()
        for aCategory in allCategories {
            let categoryFilterNames = CIFilter.filterNames(inCategory: aCategory.categoryConstant)
            Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("filters in category \(aCategory.categoryName) = \(categoryFilterNames.count)")
            for aFilterName in categoryFilterNames {
                filterAttributes = [String:Any]()  // reset to empty attributes
                if let thisFilter = CIFilter(name: aFilterName) {
                    countedFilter = filters.updateValue(thisFilter, forKey: aFilterName)
                    if countedFilter == nil {
                        // old value was nil, this is a new filter.. process with counts for thisFilter

                    filterAttributes = (thisFilter.attributes)
                    let inputKeysCount = thisFilter.inputKeys.count
                        if inputKeysCount > 5 {
//                            Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice(" large parm count for \(aFilterName) count = \(inputKeysCount)")
                        }
                    oldCount = attributeCounts[inputKeysCount] ?? 0 // needs to count only the input parms
                    attributeCounts[inputKeysCount] = oldCount + 1

                        for thisAttribute in filterAttributes {
                            if let thisAttributeDict = thisAttribute.value as? [String:Any] {
                            let attributeClass = thisAttributeDict[kCIAttributeClass] as! String
                            oldCount = attributeClassCounts[attributeClass] ?? 0
                            attributeClassCounts[attributeClass] = oldCount + 1
                                if attributeClass == "CIVector" {
                                    filtersUsingVectors.append(aFilterName)
                                }
                            if let attibuteType = thisAttributeDict[kCIAttributeType] as? String {
                                    oldCount = attributeTypeCounts[attibuteType] ?? 0
                                    attributeTypeCounts[attibuteType] = oldCount + 1
                                }

                            }
                        }
                    }


                }
                //            Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("all filters by category \(aCategory) = \(allFilters)")


            }

        }
        Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("testFilterAttibuteCounter filter count = \(filters.count)")
        Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("testFilterAttibuteCounter PARMS (parmsSize: filterCount) \(attributeCounts)")
        Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("testFilterAttibuteCounter CLASS (class: count) \(attributeClassCounts)")
        Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("testFilterAttibuteCounter TYPE (type: count) \(attributeTypeCounts)")
        Logger(subsystem: TestLogSubsystem, category: TestLogCategory).notice("filters with Vectors \(filtersUsingVectors)")

    }

    func testDescriptorSort() {
        // test duplicate filters in the
        // PGLFilterCategory.filterDescriptors var
        // descriptors are built by category and some filters are in multiple categories
        // but the var should only have unique filters by filterName

        var answerFilters = [PGLFilterDescriptor]()
        for aCategory in PGLFilterCategory.allFilterCategories() {
            answerFilters.append(contentsOf: aCategory.filterDescriptors)
        }
        let categoryCount = answerFilters.count

        let filterDescriptors = PGLFilterCategory.filterDescriptors
        let filterCount = filterDescriptors.count
        XCTAssert(filterCount <= categoryCount, "filterCount = \(filterCount)")

    }

//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

}
