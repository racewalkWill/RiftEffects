//
//  PGLGradientAttribute.swift
//  RiftEffects
//
//  Created by Will on 3/23/24.
//  Copyright © 2024 Will Loew-Blosser. All rights reserved.
//

import Foundation
import CoreImage
import simd
import UIKit
import os

let kPGradientKeyDelimitor = Character(".")

class PGLGradientChildFilter: PGLSourceFilter {
        // parent is PGLTriangleGradientFilter or subclass

    var parentFilter: PGLTriangleGradientFilter?
    var sideKey = 0


    required init?(filter: String, position: PGLFilterCategoryIndex) {
        super.init(filter: filter, position: position)
    }

    override func parmClass(parmDict: [String : Any ]) -> PGLFilterAttribute.Type  {
           // override in PGLSourceFilter subclasses..
           // most will do a lookup in the class method

        if  (parmDict[kCIAttributeClass] as! String == AttrClass.Vector.rawValue)
        {
           return PGLGradientVectorAttribute.self }
        else {
                // not a vector parm... return a normal lookup.. usually the imageParm
            return PGLFilterAttribute.parmClass(parmDict: parmDict) }
       }

        /// need to filter the keyName to the base part that the ciFilter supports
        ///  keyName has format to be unique when there are multiple gradients in use
        ///    format is gradient.keyName  ie linear1.inputPoint1
    override func setVectorValue(newValue: CIVector, keyName: String) {

            let suffixKeyName = baseKeyName(compoundKeyName: keyName)
            super.setVectorValue(newValue: newValue, keyName: suffixKeyName)

    }

        /// answer suffix part of the keyName inputPoint1
        ///    format is gradient.keyName  ie linear1.inputPoint1
    func baseKeyName(compoundKeyName: String ) -> String {
        if let suffixPosition = compoundKeyName.firstIndex(of: kPGradientKeyDelimitor)  {
            var answer =  String(compoundKeyName.suffix(from: suffixPosition))
            answer.removeFirst() // take out the period delimitor that is now leading char
            return answer
        }
        else { return compoundKeyName }
    }

    /// format is gradient.keyName  ie linear1.inputPoint1
    /// prefix shows which of the multiple gradient filters this kay belongs to
    ///  value for inputPoint1
    override func valueFor( keyName: String) -> Any? {
        let suffixKeyName = baseKeyName(compoundKeyName: keyName )
           return super.valueFor(keyName: suffixKeyName)
    }
}


