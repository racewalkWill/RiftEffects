//
//  CDAttributeVector3+CoreDataProperties.swift
//  RiftEffects
//
//  Created by Will on 10/16/22.
//  Copyright © 2022 Will Loew-Blosser. All rights reserved.
//
//

import Foundation
import CoreData


extension CDAttributeVector3 {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDAttributeVector3> {
        return NSFetchRequest<CDAttributeVector3>(entityName: "CDAttributeVector3")
    }

    @NSManaged public var vectorZ: Float

}
