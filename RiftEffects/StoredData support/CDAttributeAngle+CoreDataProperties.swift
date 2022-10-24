//
//  CDAttributeAngle+CoreDataProperties.swift
//  RiftEffects
//
//  Created by Will on 10/16/22.
//  Copyright © 2022 Will Loew-Blosser. All rights reserved.
//
//

import Foundation
import CoreData


extension CDAttributeAngle {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDAttributeAngle> {
        return NSFetchRequest<CDAttributeAngle>(entityName: "CDAttributeAngle")
    }

    @NSManaged public var doubleValue: Double

}
