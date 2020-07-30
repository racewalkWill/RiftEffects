//
//  CDFilterStack+CoreDataProperties.swift
//  Glance
//
//  Created by Will on 12/10/18.
//  Copyright © 2018 Will. All rights reserved.
//
//

import Foundation
import CoreData


extension CDFilterStack {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDFilterStack> {
        return NSFetchRequest<CDFilterStack>(entityName: "CDFilterStack")
    }

    @NSManaged public var filterNames: [String]?
    @NSManaged public var title: String?
    @NSManaged public var filters: NSOrderedSet?

}

// MARK: Generated accessors for filters
extension CDFilterStack {

    @objc(insertObject:inFiltersAtIndex:)
    @NSManaged public func insertIntoFilters(_ value: CDStoredFilter, at idx: Int)

    @objc(removeObjectFromFiltersAtIndex:)
    @NSManaged public func removeFromFilters(at idx: Int)

    @objc(insertFilters:atIndexes:)
    @NSManaged public func insertIntoFilters(_ values: [CDStoredFilter], at indexes: NSIndexSet)

    @objc(removeFiltersAtIndexes:)
    @NSManaged public func removeFromFilters(at indexes: NSIndexSet)

    @objc(replaceObjectInFiltersAtIndex:withObject:)
    @NSManaged public func replaceFilters(at idx: Int, with value: CDStoredFilter)

    @objc(replaceFiltersAtIndexes:withFilters:)
    @NSManaged public func replaceFilters(at indexes: NSIndexSet, with values: [CDStoredFilter])

    @objc(addFiltersObject:)
    @NSManaged public func addToFilters(_ value: CDStoredFilter)

    @objc(removeFiltersObject:)
    @NSManaged public func removeFromFilters(_ value: CDStoredFilter)

    @objc(addFilters:)
    @NSManaged public func addToFilters(_ values: NSOrderedSet)

    @objc(removeFilters:)
    @NSManaged public func removeFromFilters(_ values: NSOrderedSet)

}
