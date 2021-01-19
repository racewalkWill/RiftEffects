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
        "CISaliencyMapFilter"  // use PGLSaliencyBlurFilter instead of built in filter

        // 2020-10-18 test run failed filters mostly in testMultipleInputTransitionFilters
//        "CIDroste", "CIHeightFieldFromMask", "CIColorCrossPolynomial", "CIEdges",
//        "CICrystallize", "CICMYKHalftone","CIGaborGradients", "CISpotColor", "CIEdgeWork"
        ]


}
