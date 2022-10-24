//
//  CDAttributeAttributedString+CoreDataProperties.swift
//  RiftEffects
//
//  Created by Will on 10/16/22.
//  Copyright © 2022 Will Loew-Blosser. All rights reserved.
//
//

import Foundation
import CoreData


extension CDAttributeAttributedString {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDAttributeAttributedString> {
        return NSFetchRequest<CDAttributeAttributedString>(entityName: "CDAttributeAttributedString")
    }

    @NSManaged public var attribute: String?
    @NSManaged public var stringValue: String?

}
