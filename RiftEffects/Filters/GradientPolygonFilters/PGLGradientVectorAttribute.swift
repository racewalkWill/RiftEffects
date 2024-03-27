//
//  PGLGradientVectorAttribute.swift
//  RiftEffects
//
//  Created by Will on 3/27/24.
//  Copyright © 2024 Will Loew-Blosser. All rights reserved.
//

import Foundation

import UIKit
import Photos
import CoreImage

class PGLGradientVectorAttribute: PGLFilterAttributeVector {

    func baseKeyName(compoundKeyName: String ) -> String {

        if let suffixPosition = compoundKeyName.firstIndex(of: kPGradientKeyDelimitor)  {
            var answer =  String(compoundKeyName.suffix(from: suffixPosition))
            answer.removeFirst() // take out the period delimitor that is now leading char
            return answer
        }
        else { return compoundKeyName }


    }


    override func set(_ value: Any) {
        if attributeName != nil {
            if let newVectorValue = value as? CIVector {
                let simpleAttributeName = baseKeyName(compoundKeyName: attributeName!)
                aSourceFilter.setVectorValue(newValue: newVectorValue, keyName: simpleAttributeName) }
        }
    }

    override func getVectorValue() -> CIVector? {
        var generic: Any? = nil

        if attributeName != nil {
            let simpleAttributeName = baseKeyName(compoundKeyName: attributeName!)
             generic = myFilter.value(forKey: simpleAttributeName)
            }
    //        NSLog("PGLFilterAttribute #getValue generic = \(generic)")
        return generic as? CIVector
        }

}
