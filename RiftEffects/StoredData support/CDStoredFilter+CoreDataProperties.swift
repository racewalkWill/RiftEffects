//
//  CDStoredFilter+CoreDataProperties.swift
//  WillsFilterTool
//
//  Created by Will on 9/8/21.
//  Copyright © 2021 Will Loew-Blosser. All rights reserved.
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
    @NSManaged public var pglSourceFilterClass: String?
    @NSManaged public var stackPosition: Int16
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

extension CDStoredFilter : Identifiable {

}
