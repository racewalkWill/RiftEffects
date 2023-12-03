//
//  PGLCIFilterToClass.swift
//  RiftEffects
//
//  Created by Will on 4/18/23.
//  Copyright © 2023 Will Loew-Blosser. All rights reserved.
//

import Foundation

    /// answer dictionary of ciFilterNames to pglSourceFilter subclasses
    /// use to build  filterDescriptors
class CIFilterToPGLFilter {
    // answers CIFilterToPGLFilter.Map dictionary [String: [PGLSourceFilter.Type]]

    // a custom filter such as the PGLDissolveWrapper is omitted from the answer
    // Typical filter is constructed with
    //         let wrapperDesc = PGLFilterDescriptor("CIDissolveTransition", PGLDissolveWrapperFilter.self)!
    //        let wrapperFilter = wrapperDesc.pglSourceFilter() as! PGLDissolveWrapperFilter
    
    static var Map: [String: [PGLSourceFilter.Type]] =   [
            "CICrop": [PGLRectangleFilter.self] ,
            "CIClamp": [PGLRectangleFilter.self] ,
            "CIPerspectiveTransformWithExtent": [PGLRectangleFilter.self] ,
//            "CIGaussianGradient": [PGLScalingFilter.self] ,
            "CIPersonSegmentation": [PGLPersonSegmentation.self],
            kPFaceFilter : [PGLDetectorFilter.self],
            kPBumpFace : [PGLDetectorFilter.self],
            kPBumpBlend : [PGLBumpBlend.self] ,
            "CIDissolveTransition" : [ PGLFaceTransitionFilter.self, PGLTransitionFilter.self  ],
//              PGLBumpTransitionFilter.self  , PGLDissolveWrapperFilter.self  PGLDissolveWrapperFilter is NOT a user facing filter.. only use internally
            kPImages : [PGLTransitionFilter.self ],
            kPScaleDown : [ PGLScaleDownFrame.self] ,
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
}
