//
//  CoreImageKernels.metal
//  Glance
//
//  Created by Will on 3/27/19.
//  Copyright © 2019 Will Loew-Blosser. All rights reserved.
//  This has "C" coreimage kernels
//
// sample of a kernel created with Metal kernel as shown in
// https://developer.apple.com/documentation/coreimage/cikernel/2880194-init
// add the compiler flags in the above doc
//


#include <metal_stdlib>
using namespace metal;

#include <CoreImage/CoreImage.h>



extern "C" {
    namespace coreimage {
        float2 crtWarp(float2 extent, float factor, float2 distortionCenter, destination dest ) {
            // compute the source pixel for the output pixel
            // Core Image then samples from the source image at the returned coordinates to produce a pixel for the output image.
            // these values are in coord space of the image
            float2 mappedDest = ((dest.coord()/extent) - 0.5 ) * 2.0;
            float2 mapCenter = ((distortionCenter / extent) - 0.5 ) * 2.0;
            float dcX = mapCenter.x;
            float dcY = mapCenter.y;

            float rD2 = pow((mappedDest.x - dcX),2.0) + pow((mappedDest.y - dcY), 2.0);
            float divisor = 1 + (factor * rD2);
            float addX = (mappedDest.x - dcX) / divisor;
            float addY = (mappedDest.y - dcY) / divisor;

            mappedDest.x = mappedDest.x  + addX;  // or addX to dcX?
            mappedDest.y = mappedDest.y  + addY;


            mappedDest = ((mappedDest / 2.0 ) + 0.5) * extent;
            return mappedDest;

        }
    }
}
