//
//  PGLFilterCategory.swift
//  PictureGlance
//
//  Created by Will on 3/28/17.
//  Copyright © 2017 Will. All rights reserved.
//

import Foundation
import CoreImage

//let customFilters = [
    // these are for filters listed in the bridging file and have a definition file in the project
//    "FeatureTransition",
//    kPFaceFilter,
//    "ChromaKey",
//    "PixellatedPeople",
//   "TiltShift",
//    "OldeFilm",
//    "PixellateTransition",
//    "DistortionDemo"
//    //  "ColorAccent",
//    // "SobelEdge",
//    //"SobelEdgeH" , "SobelEdgeV"
//]

let AppUserDefaults = UserDefaults.init()

class PGLFilterCategory {
    // holds the filterDescriptors for a category
    // add in the custom filters


    static let classCategories = [  // copied from CIFilter.h  
        // 13 categories in use
        // + Bookmark Category as first

        kCICategoryStylize,
        kCICategoryDistortionEffect,
        kCICategoryGeometryAdjustment,
        kCICategoryGradient,

        kCICategorySharpen,
        kCICategoryBlur,

        kCICategoryCompositeOperation,
        kCICategoryHalftoneEffect,
        kCICategoryColorAdjustment,
        kCICategoryColorEffect,
        kCICategoryTransition,
        kCICategoryTileEffect,
        kCICategoryGenerator,
//       "FrequentFilters"
//        kCICategoryReduction , // NS_AVAILABLE(10_5, 5_0),
//        kCICategoryVideo,
//        kCICategoryStillImage,  // this would be all the filters currently... sort by filter name?
//        kCICategoryInterlaced,
//        kCICategoryNonSquarePixels,
//        kCICategoryHighDynamicRange,
//        kCICategoryBuiltIn
//     , kCICategoryFilterGenerator // NS_AVAILABLE(10_5, 9_0),
    ]

    static var failingFilters = ["CIBarcodeDescriptor", "CIBarcodeGenerator", "CIMeshGenerator","CICoreMLModelFilter",
        "CICameraCalibrationLensCorrection" , "CIEdgePreserveUpsampleFilter",
        "CIColorCubeWithColorSpace", "CIColorCubesMixedWithMask", "CIColorCube",
        "CIKMeans", "CIPaletteCentroid" , "CIPalettize", "CIColorCurves"]
    static var skipFailingFilters = true  // change to false to include all filters
        // a test case could set this to false to test for CIFilter changes in iOS releases

    static let Bookmark = "Bookmark"  // also described as "Frequent" "Bookmark" in code
    static var filterDescriptors = allFilterDescriptors()
    private static var filterCategories: [PGLFilterCategory]?


    fileprivate static func setDescriptorsUIPosition(_ thisNewbie: PGLFilterCategory, _ i: Int, _ catIndex: Int) {
        let newbiePosition = thisNewbie.filterDescriptors[i].uiPosition
        newbiePosition.categoryIndex = catIndex + 1 // zero is frequentCategory.. advance by one
        newbiePosition.categoryCodeName = classCategories[catIndex]
        newbiePosition.filterIndex = i
        newbiePosition.filterCodeName = thisNewbie.filterDescriptors[i].filterName
    }

    static func allFilterCategories() -> [PGLFilterCategory] {
        // return categories as defined in the CIFilter.h
        // this should be a class var.. not read for each stack.
        if let cachedCategories = filterCategories {
            return cachedCategories
        }
        var answerArray = [PGLFilterCategory]()
//       PGLFilterCIAbstract.register()
//
//       
//        WarpItMetalFilter.register()
        if AppUserDefaults.stringArray(forKey: Bookmark) == nil
        {
            let newFrequentFilters = ["Dissolve"]
            AppUserDefaults.set(newFrequentFilters, forKey: Bookmark)
        }
       
        
        // kuwahara & Perlin not working WL-B 3/7/19
//        MetalKuwaharaFilter.register()
//        MetalPerlinNoise.register()
        if let frequentFilters = AppUserDefaults.stringArray(forKey: Bookmark) {
            let frequentCategory = PGLFilterCategory(specialCategory: Bookmark, filterNames: frequentFilters )
            answerArray.append(frequentCategory) // frequent category is position zero
        }

        for catIndex in 0..<classCategories.count   {
            if let thisNewbie = PGLFilterCategory(classCategories[catIndex]) {
                thisNewbie.categoryIndex = catIndex + 1 // frequentCategory is assigned to zero index

                for i in 0..<thisNewbie.filterDescriptors.count{
                    setDescriptorsUIPosition(thisNewbie, i, catIndex)

                }
                answerArray.append(thisNewbie)

            }
            else {
                NSLog("PGLFilterCategory creation failed for \(classCategories[catIndex])") }
        }

        filterCategories = answerArray
        return answerArray
    }

    static func allFilterDescriptors() -> [PGLFilterDescriptor] {
        var answerFilters = [PGLFilterDescriptor]()
        for aCategory in allFilterCategories() {
            answerFilters.append(contentsOf: aCategory.filterDescriptors)
        }

        return answerFilters.sorted(by: {$0.displayName <= $1.displayName})

    }

    static func getFilterDescriptor(aFilterName: String, cdFilterClass: String) -> PGLFilterDescriptor? {
        //
        // from aFilter name you also need the pglSourceFilter class.. some CIFilters are used
        // by more than one PGLSourceFilter subclass - see CIFilter.pglClassMap()
        var answerDescriptor: PGLFilterDescriptor?
        if let myPGLClassMaps = CIFilter.pglClassMap()[aFilterName] {
            for aPGLSourceClass in myPGLClassMaps {
                // usually just one class per ciFilterName.. but a few cases of multiples
                if aPGLSourceClass.classStringName() == cdFilterClass {
                    let thisDescriptor  = PGLFilterDescriptor(aFilterName, aPGLSourceClass)
                    answerDescriptor = thisDescriptor
                    break // out of the for loop
                }
                }
        } else {
            // dissolve with have the nil case as the 'normal'
          answerDescriptor =  PGLFilterDescriptor(aFilterName,nil)
        }
        return answerDescriptor
    }


    let categoryName: String
    let categoryConstant: String
    var categoryIndex = 0
    var filterDescriptors = [PGLFilterDescriptor]()


     func buildCategoryFilterDescriptors( filterNames: [String]) -> [PGLFilterDescriptor] {
        var builtDescriptors = [PGLFilterDescriptor]()

        for aFilterName in filterNames {
            if (PGLFilterCategory.failingFilters.contains(aFilterName))
                && (PGLFilterCategory.skipFailingFilters)
                {continue}
            if let myPGLClassMaps = CIFilter.pglClassMap()[aFilterName] {
                for aPGLSourceClass in myPGLClassMaps {
                    // usually just one class per ciFilterName.. but a few cases of multiples
                  if let thisDescriptor  = PGLFilterDescriptor(aFilterName, aPGLSourceClass)
                  { builtDescriptors.append(thisDescriptor) }
                }
            }
            else { // use the default pglSourceClass of PGLSourceFilter
                if let thisDescriptor  = (PGLFilterDescriptor(aFilterName,nil)) {
                      builtDescriptors.append(thisDescriptor)
                }

            }

        }
        return builtDescriptors
    }



    init? (_ thisCategoryString: String) {

             categoryConstant = thisCategoryString
            categoryName = CIFilter.localizedName(forCategory: thisCategoryString)
            filterDescriptors = buildCategoryFilterDescriptors( filterNames: CIFilter.filterNames(inCategory: thisCategoryString) )
        // removed the setup of the customCategory 8/27/18 version has custom category code


    }

    init(specialCategory: String, filterNames: [String]) {
        categoryConstant = specialCategory
        categoryName = specialCategory
        filterDescriptors = buildCategoryFilterDescriptors( filterNames: filterNames )
    }

    func filterDescriptor(atIndex: Int) -> PGLFilterDescriptor? {
        // answer the filter descriptor in the array or nil
        return filterDescriptors[atIndex]
    }

    func appendCopy(_ sourceDescriptor: PGLFilterDescriptor) {
        // appends a new filterDescriptor copied from the sourceDescriptor

        filterDescriptors.append( sourceDescriptor.copy() )

        //save into userDefaults
        var myDefaults = AppUserDefaults.stringArray(forKey: categoryName) ?? [String]()
        myDefaults.append(sourceDescriptor.displayName)
        AppUserDefaults.set(myDefaults, forKey: categoryName)

    }

    func removeDescriptor( _ trashDescriptor: PGLFilterDescriptor) {
        // remove from the UI array and the stored defaults array

          var myDefaults = AppUserDefaults.stringArray(forKey: categoryName) ?? [String]()

        filterDescriptors.removeAll(where: {$0.displayName == trashDescriptor.displayName })
        myDefaults.removeAll(where: {$0 == trashDescriptor.displayName })
         AppUserDefaults.set(myDefaults, forKey: categoryName)

    }

    func isEmpty() -> Bool {
        return filterDescriptors.isEmpty
    }


}
