//
//  CIFilterExtensions.swift
//  PictureGlance
//
//  Created by Will Loew-Blosser on 3/11/17.
//  Copyright © 2017 Will Loew-Blosser. All rights reserved.
//  based on Apple sample app CIFunHouse file CIFilter+FHAdditions
//

import Foundation
import CoreImage

enum Stack { case begin, middle, end }

// constants for custom filter creation / loading

let kPFaceFilter = "FaceFilter"
let kPBumpBlend = "BumpBlend"
let kPBumpFace = "BumpFace"
let kPImages = "Images"
let kPCarnivalMirror = "CarnivalMirror"
let kPTiltShift = "TiltShift"
let kPWarpItMetal  = "WarpItMetal"
let kTextImageGenerator = "ImageText"
let kCompositeTextPositionFilter = "CompositeTextPositionFilter"

extension CIFilter {
   class func pglClassMap() -> [String: [PGLSourceFilter.Type]] {
        // answer dictionary of collection of pglSourceFilter subclasses for filterDescriptors
    // This classMap is used with the user facing filter categories.
    // a custom filter such as the PGLDissolveWrapper is omitted from the answer
    // the filter is constructed with
            //    let wrapperDesc = PGLFilterDescriptor("CIDissolveTransition", PGLDissolveWrapperFilter.self)!
            //        let wrapperFilter = wrapperDesc.pglSourceFilter() as! PGLDissolveWrapperFilter
    
        let answerDict: [String: [PGLSourceFilter.Type]] =   [
          "CICrop": [PGLRectangleFilter.self] ,
          kPFaceFilter : [PGLDetectorFilter.self],
           kPBumpFace : [PGLDetectorFilter.self],
           kPBumpBlend : [PGLBumpBlend.self] ,
            "CIDissolveTransition" : [ PGLFaceTransitionFilter.self, PGLTransitionFilter.self , PGLBumpTransitionFilter.self
//                , PGLDissolveWrapperFilter.self  PGLDissolveWrapperFilter is NOT a user facing filter.. only use internally
            ],
            kPImages : [PGLTransitionFilter.self ],
            "CIAccordionFoldTransition" : [PGLTransitionFilter.self ],
            "CIBarsSwipeTransition" : [PGLTransitionFilter.self] ,
            "CICopyMachineTransition" : [PGLTransitionFilter.self ],
            "CIDisintegrateWithMaskTransition" :  [PGLTransitionFilter.self ],
            "CIFlashTransition" : [PGLTransitionFilter.self],
            "CIModTransition" : [PGLTransitionFilter.self],
            "CIPageCurlTransition" : [PGLTransitionFilter.self],
            "CIPageCurlWithShadowTransition" : [PGLTransitionFilter.self ],
            "CIRippleTransition" : [PGLTransitionFilter.self],
            "CISwipeTransition": [PGLTransitionFilter.self] ,
            "CIQRCodeGenerator": [PGLQRCodeGenerator.self ],
            "CIDepthBlurEffect" : [PGLDisparityFilter.self],
            kTextImageGenerator : [PGLTextImageGenerator.self],
            kCompositeTextPositionFilter: [PGLTextImageGenerator.self]
            
        ]
        return answerDict
    }
}

extension Int { func isEven() -> Bool { return (self % 2 == 0) } }

