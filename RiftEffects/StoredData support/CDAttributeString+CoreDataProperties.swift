//
//  CDAttributeString+CoreDataProperties.swift
//  RiftEffects
//
//  Created by Will on 10/16/22.
//  Copyright © 2022 Will Loew-Blosser. All rights reserved.
//
//

import Foundation
import CoreData


extension CDAttributeString {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDAttributeString> {
        return NSFetchRequest<CDAttributeString>(entityName: "CDAttributeString")
    }

    @NSManaged public var stringValue: String?

}
