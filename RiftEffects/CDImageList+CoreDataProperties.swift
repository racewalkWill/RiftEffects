//
//  CDImageList+CoreDataProperties.swift
//  Glance
//
//  Created by Will on 12/4/18.
//  Copyright © 2018 Will. All rights reserved.
//
//

import Foundation
import CoreData


extension CDImageList {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDImageList> {
        return NSFetchRequest<CDImageList>(entityName: "CDImageList")
    }

    @NSManaged public var assetIDs: [String]?
    @NSManaged public var attributeName: String?

}
