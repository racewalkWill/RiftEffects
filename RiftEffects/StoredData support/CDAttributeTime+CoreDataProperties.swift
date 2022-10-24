//
//  CDAttributeTime+CoreDataProperties.swift
//  RiftEffects
//
//  Created by Will on 10/16/22.
//  Copyright © 2022 Will Loew-Blosser. All rights reserved.
//
//

import Foundation
import CoreData


extension CDAttributeTime {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDAttributeTime> {
        return NSFetchRequest<CDAttributeTime>(entityName: "CDAttributeTime")
    }

    @NSManaged public var floatValue: Float

}
