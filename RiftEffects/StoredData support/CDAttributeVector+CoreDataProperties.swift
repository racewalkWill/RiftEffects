//
//  CDAttributeVector+CoreDataProperties.swift
//  RiftEffects
//
//  Created by Will on 10/16/22.
//  Copyright © 2022 Will Loew-Blosser. All rights reserved.
//
//

import Foundation
import CoreData


extension CDAttributeVector {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDAttributeVector> {
        return NSFetchRequest<CDAttributeVector>(entityName: "CDAttributeVector")
    }

    @NSManaged public var vectorEndX: Float
    @NSManaged public var vectorEndY: Float
    @NSManaged public var vectorX: Float
    @NSManaged public var vectorY: Float

}
