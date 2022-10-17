//
//  CDAttributeData+CoreDataProperties.swift
//  RiftEffects
//
//  Created by Will on 10/16/22.
//  Copyright © 2022 Will Loew-Blosser. All rights reserved.
//
//

import Foundation
import CoreData


extension CDAttributeData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDAttributeData> {
        return NSFetchRequest<CDAttributeData>(entityName: "CDAttributeData")
    }

    @NSManaged public var binaryValue: Data?

}
