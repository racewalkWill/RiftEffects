//
//  PGLColorVectorNumeric.swift
//  RiftEffects
//
//  Created by Will on 12/11/22.
//  Copyright © 2022 Will Loew-Blosser. All rights reserved.
//

import CoreImage

/// slider numeric values 0..1 for the Color Adjustment Filters with vector parm classes
class PGLColorVectorNumeric: PGLSourceFilter {

    required init?(filter: String, position: PGLFilterCategoryIndex) {
        super.init(filter: filter, position: position)
        // now redo the attributes that came in by default..
        let inputAttributeKeys = localFilter.inputKeys
        let inputAttributeCount = inputAttributeKeys.count
        
     
        for i in 0..<inputAttributeCount {
            let anAttributeKey = inputAttributeKeys[i]
            if anAttributeKey == "inputImage" {
                    continue
                }
            let inputParmDict = (localFilter.attributes[anAttributeKey]) as! [String : Any]

            let parmAttributeClass = PGLAttributeVectorNumeric.self
            if let thisParmAttribute = parmAttributeClass.init(pglFilter: self, attributeDict: inputParmDict, inputKey: anAttributeKey  )
                {
                    for valueAttribute in thisParmAttribute.valueInterface() {
                        // assumes exactly one new attributeUI to represent the attribute
                         // remove the thisParmAttribute and let the valueAttribute show
                        attributes[i] = valueAttribute

                    }
                }

            isImageInputType =  attributes.contains { (attribute: PGLFilterAttribute ) -> Bool in
                attribute.isImageInput()
            }
        }

    }

}
