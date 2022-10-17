//
//  CDAttributeScaleAffine+CoreDataProperties.swift
//  RiftEffects
//
//  Created by Will on 10/16/22.
//  Copyright © 2022 Will Loew-Blosser. All rights reserved.
//
//

import Foundation
import CoreData


extension CDAttributeScaleAffine {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDAttributeScaleAffine> {
        return NSFetchRequest<CDAttributeScaleAffine>(entityName: "CDAttributeScaleAffine")
    }

    @NSManaged public var scaleX: Float
    @NSManaged public var scaleY: Float

}
