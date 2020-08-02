//
//  CDStoredFilter+CoreDataProperties.swift
//  Glance
//
//  Created by Will on 12/10/18.
//  Copyright © 2018 Will. All rights reserved.
//
//

import Foundation
import CoreData
import CoreImage

extension CDStoredFilter {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDStoredFilter> {
        return NSFetchRequest<CDStoredFilter>(entityName: "CDStoredFilter")
    }

    @NSManaged public var ciFilter: CIFilter?
    @NSManaged public var ciFilterName: String?
    @NSManaged public var input: NSSet?
    @NSManaged public var stack: CDFilterStack?

}

// MARK: Generated accessors for input
extension CDStoredFilter {

    @objc(addInputObject:)
    @NSManaged public func addToInput(_ value: CDParmImage)

    @objc(removeInputObject:)
    @NSManaged public func removeFromInput(_ value: CDParmImage)

    @objc(addInput:)
    @NSManaged public func addToInput(_ values: NSSet)

    @objc(removeInput:)
    @NSManaged public func removeFromInput(_ values: NSSet)

}