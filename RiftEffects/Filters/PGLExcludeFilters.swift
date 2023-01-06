//
//  PGLExcludeFilters.swift
//  Surreality
//
//  Created by Will on 1/15/21.
//  Copyright © 2021 Will Loew-Blosser. All rights reserved.
//

import Foundation

class PGLExcludeFilters {
    // do not use these filters
    // either missing documentation on their parms
    // or parms can not be generated in a visual context
    
    static var skipFailingFilters = true  // change to false to include all filters
        // a test case could set this to false to test for CIFilter changes in iOS releases


    static var list = [
        // revised in release 2.2 Convolution and Affine clamps removed from excluded
        // 2023/01/03
"CIBarcodeDescriptor",
"CIBarcodeGenerator",
"CIMeshGenerator",
"CICoreMLModelFilter",
"CICameraCalibrationLensCorrection" ,
"CIEdgePreserveUpsampleFilter",
"CIColorCubeWithColorSpace",
"CIColorCubesMixedWithMask",
"CIColorCube",
"CIKMeans",
"CIPaletteCentroid" ,
"CIPalettize",
"CIColorCurves",
"CISaliencyMapFilter", // use PGLSaliencyBlurFilter instead of built in filter

"BumpFace" ,
        
// internal filters for use by custom filters
// these only work with the aux depth info from a portrait.. not an normal input image
"CITextImageGenerator" ,
"CIDepthToDisparity",
"CIDisparityToDepth",
"CIColorClamp" ,  // see note N73.7.3 CIColorClamp for how to implement interface at later time

// 2022-07-10 exclude failing for beta tests
"CIAccordionFoldTransition" ,

"CIAttributedTextImageGenerator",
"CIAztecCodeGenerator",
"CILabDeltaE",
"CIQRCodeGenerator",
"CIRoundedRectangleGenerator",
"CIPDF417BarcodeGenerator",

        ]


}
