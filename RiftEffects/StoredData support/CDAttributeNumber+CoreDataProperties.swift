//
//  CDAttributeNumber+CoreDataProperties.swift
//  RiftEffects
//
//  Created by Will on 10/16/22.
//  Copyright © 2022 Will Loew-Blosser. All rights reserved.
//
//

import Foundation
import CoreData


extension CDAttributeNumber {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDAttributeNumber> {
        return NSFetchRequest<CDAttributeNumber>(entityName: "CDAttributeNumber")
    }

    @NSManaged public var doubleValue: Double

}
