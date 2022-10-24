//
//  CDAttributeColor+CoreDataProperties.swift
//  RiftEffects
//
//  Created by Will on 10/16/22.
//  Copyright © 2022 Will Loew-Blosser. All rights reserved.
//
//

import Foundation
import CoreData


extension CDAttributeColor {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDAttributeColor> {
        return NSFetchRequest<CDAttributeColor>(entityName: "CDAttributeColor")
    }

    @NSManaged public var alphaValue: Float
    @NSManaged public var blueValue: Float
    @NSManaged public var greenValue: Float
    @NSManaged public var redValue: Float

}
