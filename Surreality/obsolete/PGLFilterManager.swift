//
//  PGLFilterManager.swift
//  PictureGlance
//
//  Created by Will Loew-Blosser on 2/23/17.
//  Copyright © 2017 Will Loew-Blosser. All rights reserved.
//

import Foundation
import CoreImage

class PGLFilterManager {
// not used.. delete
    //    NSArray* filterNames = @[ @"CIHoleDistortion",
    //                              @"CIBumpDistortion",
    //                              @"CIVortexDistortion",
    //                              @"CITwirlDistortion",
    //                              @"CICircleSplashDistortion"];
    //                              CIGlassLozenge, CIPinchDistortion

    var currentFilter = CIFilter(name: "CITwirlDistortion")
    var dissolveFilter = CIFilter(name: "CIDissolveTransition")
    var lastImage: CIImage

    var centerVector = CIVector(x: 900.0, y: 900.0)
    var effectRadius = 100.0
    var useDissolve = false

    init(_ startImage: CIImage) {
        lastImage = startImage
//        NSLog("PGLFilterManager init startImage extent = \(startImage.extent)")
    }

    func dissolveFrom (_ fromImage: CIImage, toImage: CIImage, dissolveDuration: Double) -> CIImage {
        if let dissolve = dissolveFilter {
            dissolve.setValue(fromImage, forKey: "inputImage")
            dissolve.setValue(toImage, forKey: "inputTargetImage")
            dissolve.setValue( NSNumber (value: dissolveDuration as Double), forKey: "inputTime") //NSValue(nonretainedObject:
            return dissolve.outputImage!
        }
        else { return toImage }
    }
    
    func setFilter(_ descriptor: PGLFilterDescriptor) {
//        NSLog (" PGLFilterManager->setFilter to \(descriptor)")
        currentFilter = descriptor.filter()
    }
    
    func runFilter( inputImage: CIImage) -> CIImage {
//        NSLog("PGLFilterManager runFilter inputImage.extent = \(inputImage.extent)")
        currentFilter?.setDefaults()
//        currentFilter?.setValuesForKeys(["inputImage" : inputImage ,
//                                         "inputCenter" : centerVector ,
//                                         "inputRadius": effectRadius])
        if let currentEffectImage = currentFilter?.outputImage {
        
            var filterReturnImage = currentEffectImage
            if useDissolve {
                filterReturnImage =  dissolveFrom(lastImage, toImage: currentEffectImage, dissolveDuration: 0.2)
                lastImage = currentEffectImage
                return filterReturnImage }
            }
            else { return inputImage }

        NSLog("PGLFilterManager -> runFilter currentEffectImage is nil Returning input image ")
        return inputImage

    }

    func expandRadius(by: Double) {
        effectRadius += by
        if effectRadius >= 3000.0 { effectRadius = 100.0 }
    }


}
