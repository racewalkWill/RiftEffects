//
//  PGLFilterCI.swift
//  Glance
//
//  Created by Will on 1/30/19.
//  Copyright © 2019 Will Loew-Blosser All rights reserved.
//

import UIKit

class PGLFilterCIAbstract: CIFilter {
    //abstract class for registration and setup of custom CIFilter subclasses
    // all custom CIFilters should be subclasses

    // subclasses(of: PGLFilterCIAbstract.self)
    static let FilterCISubclasses  = [ PGLBumpBlendCI.self,
        PGLBumpFaceCIFilter.self,
//        PGLCarnivalMirror.self,
        PGLFaceCIFilter.self,

        PGLTiltShift.self,
        
        ]


    class override var supportsSecureCoding: Bool { get {
        // subclasses of PGLFilterCIAbstract must  each implement this
//         Core Data requires secureCoding to store the filter
        return true
    }}


    class func register() {

        for aFilterClass in FilterCISubclasses {
            aFilterClass.register()
        }

    }
    @objc    class func customAttributes() -> [String: Any] {
        let customDict:[String: Any] = [
          
                        "inputFeatureSelect" : [
                            kCIAttributeMin       :  -1.0,
                            kCIAttributeSliderMin :  -1.0,
                            kCIAttributeSliderMax :    5 ,
                            kCIAttributeIdentity  :  -1.0,
                            kCIAttributeType : kCIAttributeTypeInteger

                        ] as [String : Any] as [String : Any]
        ]
        return customDict
    }

    class func combineCustomAttributes( otherAttributes: [String:Any]) -> [String:Any] {
        var allCustomAttributes = PGLFilterCIAbstract.customAttributes()
        for (key, value) in otherAttributes {
            allCustomAttributes.updateValue(value, forKey: key)
            // a subclass may change the value of this classes customDict for the same key in both dictionaries
        }
        return allCustomAttributes

    }

    @objc dynamic  var inputImage: CIImage?
    @objc dynamic var inputFeatureSelect: NSInteger = -1

    var  features = [PGLFaceBounds]() {
        didSet {
            displayFeatures = features.indices
        }
    }
    var  displayFeatures: CountableRange<Int>?
    // detector and features vars are set by the  PGLDetector.. tricky

}
