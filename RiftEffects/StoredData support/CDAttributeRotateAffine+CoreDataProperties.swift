//
//  CDAttributeRotateAffine+CoreDataProperties.swift
//  RiftEffects
//
//  Created by Will on 10/16/22.
//  Copyright © 2022 Will Loew-Blosser. All rights reserved.
//
//

import Foundation
import CoreData


extension CDAttributeRotateAffine {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDAttributeRotateAffine> {
        return NSFetchRequest<CDAttributeRotateAffine>(entityName: "CDAttributeRotateAffine")
    }

    @NSManaged public var rotationAngle: Float

}
