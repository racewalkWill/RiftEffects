//
//  PGLSequencedFilters.swift
//  RiftEffects
//
//  Created by Will on 10/1/22.
//  Copyright © 2022 Will Loew-Blosser. All rights reserved.
//

import Foundation
import CoreImage
import simd
import UIKit
import os

class PGLSequencedFilters: PGLTransitionFilter {

    override func addChildSequenceStack(appStack: PGLAppStack) {
        // actually do the add
        if let myImageParm = getInputImageAttribute() {
            appStack.addChildSequenceStackTo(parm: myImageParm)
        }
    }

    override  func outputImageBasic() -> CIImage? {
        // assign input to the child sequence stack
        // return the outpput of the child sequence stack

        // instead of returning empty on errors.. return the output same as
        // images??
        guard let myImage = inputImage()
            else { return CIImage.empty()}

        guard let imageAttribute = getInputImageAttribute()
            else { return CIImage.empty()}

        guard let mySequenceStack = imageAttribute.inputStack as? PGLFilterSequence
        else { return  CIImage.empty()}

       return mySequenceStack.imageUpdate(myImage, true)


    }

}
