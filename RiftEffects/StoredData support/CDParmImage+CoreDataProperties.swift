//
//  CDParmImage+CoreDataProperties.swift
//  Glance
//
//  Created by Will on 12/10/18.
//  Copyright © 2018 Will. All rights reserved.
//
//

import Foundation
import CoreData


extension CDParmImage {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDParmImage> {
        return NSFetchRequest<CDParmImage>(entityName: "CDParmImage")
    }

    @NSManaged public var parmName: String?
    @NSManaged public var filter: CDStoredFilter?
    @NSManaged public var inputAssets: CDImageList?
    @NSManaged public var inputStack: CDFilterStack?

}
