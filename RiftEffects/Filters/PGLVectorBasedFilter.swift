//
//  PGLVectorBasedFilter.swift
//  RiftEffects
//
//  Created by Will on 12/15/22.
//  Copyright © 2022 Will Loew-Blosser. All rights reserved.
//

import Foundation
import CoreImage

class PGLVectorBasedFilter: PGLSourceFilter {
    override func parmClass(parmDict: [String : Any ]) -> PGLFilterAttribute.Type  {
           // override in PGLSourceFilter subclasses..
           // most will do a lookup in the class method

        if  (parmDict[kCIAttributeClass] as! String == AttrClass.Vector.rawValue)
        {
           return PGLAttributeVectorExpand.self }
        else {
                // not a vector parm... return a normal lookup.. usually the imageParm
            return PGLFilterAttribute.parmClass(parmDict: parmDict) }
       }

}
