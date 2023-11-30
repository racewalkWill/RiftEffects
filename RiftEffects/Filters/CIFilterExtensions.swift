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

let kPSequencedFilter = "Sequenced Filters"
let kPChildSequenceStack = "ChildSequenceStack"
let kPFaceFilter = "FaceFilter"
let kPBumpBlend = "BumpBlend"
let kPBumpFace = "BumpFace"
let kPImages = "Images"
let kPRandom = "Random Filters"
let kPCarnivalMirror = "CarnivalMirror"
let kPTiltShift = "TiltShift"
let kPWarpItMetal  = "WarpItMetal"
let kPScaleDown = "ScaleDown"

let kCompositeTextPositionFilter = "CompositeTextPositionFilter"
let kSaliencyBlurFilter = "Saliency Blur"

/*
 MOVED in  121.05  to CIFilterToPGLFilter.Map
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
            "CIClamp": [PGLRectangleFilter.self] ,
            "CIPerspectiveTransformWithExtent": [PGLRectangleFilter.self] ,
            "CIGaussianGradient": [PGLScalingFilter.self] ,
          "CIPersonSegmentation": [PGLPersonSegmentation.self],
          kPFaceFilter : [PGLDetectorFilter.self],
           kPBumpFace : [PGLDetectorFilter.self],
           kPBumpBlend : [PGLBumpBlend.self] ,
            "CIDissolveTransition" : [ PGLFaceTransitionFilter.self, PGLTransitionFilter.self
//              PGLBumpTransitionFilter.self  , PGLDissolveWrapperFilter.self  PGLDissolveWrapperFilter is NOT a user facing filter.. only use internally
            ],
            kPImages : [PGLTransitionFilter.self ],
            kPScaleDown : [PGLScaleDownFrame.self],
            kPRandom : [PGLRandomFilterMaker.self ],
          kPSequencedFilter : [PGLSequencedFilters.self ] ,
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
            "CIAztecCodeGenerator" : [PGLCIAztecCodeGenerator.self],
            "CIDepthBlurEffect" : [PGLDisparityFilter.self],

          kCompositeTextPositionFilter: [PGLTextImageGenerator.self],
          "CIColorMatrix": [PGLColorVectorNumeric.self],
          "CIColorPolynomial": [PGLColorVectorNumeric.self],
          "CIColorCrossPolynomial": [PGLColorVectorNumeric.self],

          "CIToneCurve": [PGLVectorBasedFilter.self],

          "CIConvolution3X3" : [PGLConvolutionFilter.self],
          "CIConvolution5X5" : [PGLConvolutionFilter.self],
          "CIConvolution7X7" : [PGLConvolutionFilter.self],
          "CIConvolution9Horizontal" : [PGLConvolutionFilter.self],
          "CIConvolution9Vertical" : [PGLConvolutionFilter.self],
          "CIConvolutionRGB3X3" : [PGLConvolutionFilter.self],
          "CIConvolutionRGB5X5" : [PGLConvolutionFilter.self],
          "CIConvolutionRGB7X7" : [PGLConvolutionFilter.self],
          "CIConvolutionRGB9Horizontal" : [PGLConvolutionFilter.self],
          "CIConvolutionRGB9Vertical" : [PGLConvolutionFilter.self]
            
        ]
        return answerDict
    }
}
 */

extension Int { func isEven() -> Bool { return (self % 2 == 0) } }

extension CGRect {
    func isNAN() -> Bool {
        return width.isNaN || height.isNaN
    }

    func isXYInfinite() -> Bool {
        return origin.x.isInfinite || origin.y.isInfinite
    }

    func isOutofRange() -> Bool {
        let answer =  isNAN() || isXYInfinite()
        return answer
    }
}

