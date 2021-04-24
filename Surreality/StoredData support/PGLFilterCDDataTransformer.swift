//
//  PGLFilterCDDataTransformer.swift
//  Surreality
//
//  Created by Will on 10/22/20.
//  Copyright © 2020 Will Loew-Blosser. All rights reserved.
//

import Foundation
import UIKit
import CoreImage

@objc(PGLFilterCDDataTransformer)
class PGLFilterCDDataTransformer: NSSecureUnarchiveFromDataTransformer {

//public static func register() {
//
//    let transformer = PGLFilterCDDataTransformer()
//
////sample code from forum does not make sense
//    ValueTransformer.setValueTransformer(transformer, forName: NSValueTransformerName.filterCDDataTransformer)
//
//}

    override class func allowsReverseTransformation() -> Bool {
        return true
    }

    override class func transformedValueClass() -> AnyClass {
        return CIFilter.self // what about PGLFilterCIAbstract.self & subclasses?
    }

    override class var allowedTopLevelClasses: [AnyClass] {
        return [CIFilter.self ] 
    }

    override func transformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else {
            NSLog("PGLFilterCDDataTransformer transformedValue() Wrong data type: value must be a Data object; received \(type(of: value))")
            return nil
        }
        return super.transformedValue(data)
    }

    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let thisFilter = value as? CIFilter else {
            NSLog("PGLFilterCDDataTransformer reverseTransformedValue()  Wrong data type: value must be a CIFilter object; received \(type(of: value))")
            return nil
        }
        return super.reverseTransformedValue(thisFilter)
    }
}

extension NSValueTransformerName {
    static let filterCDDataTransformer = NSValueTransformerName(rawValue: "PGLFilterCDDataTransformer")
}
