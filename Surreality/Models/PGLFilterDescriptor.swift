//
//  PGLFilterDescriptor.swift
//  PictureGlance
//
//  Created by Will on 3/18/17.
//  Copyright © 2017 Will. All rights reserved.
//

import Foundation
import CoreImage


class PGLFilterDescriptor:  NSObject, NSCoding {
    func encode(with aCoder: NSCoder) {
        fatalError("PGLFilterDescriptor does not implement encode")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("PGLFilterDescriptor does not implement coder")
    }
    
    
    let  kFilterSettingsKey = "FilterSettings"
    let  kFilterOrderKey = "FilterOrder"

@objc    var filterName = "InitialFilterName"
@objc    var displayName = "InitialDisplayName"
    var inputImageCount = -1
    var userDescription = "emptyDescription"
    var uiPosition = PGLFilterCategoryIndex()

 override  var debugDescription: String {
        return filterName
    }


    var pglSourceFilterClass = PGLSourceFilter.self  //some will use a subclass ie PGLCropFilter etc..

    // connect the ciFilter name to a PGLSourceFilter class
    // the ciFilter will get installed into the PGLSourceFilter instances
    // this fails if a ciFilter is used by several PGLSourceFilters because dictionary has unique keys
    // it is a many to many relationship from CIFilter instances to (PGLSourceFilter & PGLSourceFilter subclasses)
// see implementation in CIFilter class func pglClassMap()
    // constructed in PGLFilterCategory, PGLFilterDescriptors, CIFilter

    init?(_ ciFilterName: String, _ pglClassType: PGLSourceFilter.Type? ) {

            filterName = ciFilterName  // keep the code name around

            if let myUserDescription = CIFilter.localizedDescription(forFilterName: ciFilterName) {
                userDescription = myUserDescription
            }
        if let aPGLClass = pglClassType {
            pglSourceFilterClass = aPGLClass
            if let pglSourceDisplayName =  pglSourceFilterClass.displayName() {
              displayName =  pglSourceDisplayName
                
            }
        }
        // else the default value is PGLSourceFilter.self
         if displayName == "InitialDisplayName"
         {
            displayName = CIFilter.localizedName(forFilterName: ciFilterName) ?? ciFilterName }
                // will be localized to Dissolve or other...
    }

    func filter() -> CIFilter {
        // see also PGLFilterConstructor filter(withName: String

        return PGLFilterConstructor().filter(withName: filterName)!
            // triggers nil unwrap error if filter is not returned
    }

    func pglSourceFilter() -> PGLSourceFilter? {
        // create and return a new instance of my real filter
        // or nil if the real filter can not be created

        let newSourceFilter = pglSourceFilterClass.init(filter: filterName, position: uiPosition)
        newSourceFilter?.setDefaults()
        newSourceFilter?.descriptorDisplayName = displayName
        return newSourceFilter


    }

    func copy() -> PGLFilterDescriptor {
        let newbie = PGLFilterDescriptor(filterName, pglSourceFilterClass)!

        return newbie
    }


}




