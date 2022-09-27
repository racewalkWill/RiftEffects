//
//  CDParmValue+CoreDataProperties.swift
//  RiftEffects
//
//  Created by Will on 9/26/22.
//  Copyright © 2022 Will Loew-Blosser. All rights reserved.
//
//

import Foundation
import CoreData


extension CDParmValue {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDParmValue> {
        return NSFetchRequest<CDParmValue>(entityName: "CDParmValue")
    }

    @NSManaged public var alphaValue: Float
    @NSManaged public var attributeName: String?
    @NSManaged public var binaryValue: Data?
    @NSManaged public var blueValue: Float
    @NSManaged public var booleanValue: Bool
    @NSManaged public var dateValue: Date?
    @NSManaged public var decimalValue: NSDecimalNumber?
    @NSManaged public var doubleValue: Double
    @NSManaged public var floatValue: Float
    @NSManaged public var greenValue: Float
    @NSManaged public var heightValue: Double
    @NSManaged public var integerValue: Int32
    @NSManaged public var pglParmClass: String?
    @NSManaged public var redValue: Float
    @NSManaged public var stringValue: String?
    @NSManaged public var vectorAngle: Float
    @NSManaged public var vectorLength: Float
    @NSManaged public var vectorX: Float
    @NSManaged public var vectorY: Float
    @NSManaged public var vectorZ: Float
    @NSManaged public var widthValue: Double
    @NSManaged public var xPoint: Double
    @NSManaged public var yPoint: Double
    @NSManaged public var storedFilter: CDStoredFilter?

}

extension CDParmValue : Identifiable {

}
