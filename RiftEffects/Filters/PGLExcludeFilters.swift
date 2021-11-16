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

        // Convolution group needs an interface for the parm
        // thinking of grid of values and a grid of gray squares to drag value changes over.
        // a draggable grid would allow calculation of the sum adjustments as one value changes.
        "CIConvolution3X3",
        "CIConvolution5X5",
        "CIConvolution7X7",
        "CIConvolution9Horizontal",
        "CIConvolution9Vertical",

        // internal filters for use by custom filters
        // these only work with the aux depth info from a portrait.. not an normal input image
        "CIDepthToDisparity",
        "CIDisparityToDepth",
        "CIColorClamp"   // see note N73.7.3 CIColorClamp for how to implement interface at later time

        // 2020-10-18 test run failed filters mostly in testMultipleInputTransitionFilters
//        "CIDroste", "CIHeightFieldFromMask", "CIColorCrossPolynomial", "CIEdges",
//        "CICrystallize", "CICMYKHalftone","CIGaborGradients", "CISpotColor", "CIEdgeWork"
//        "FaceFilter"
        ]


}
