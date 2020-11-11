//
//  PGLFilterGroup.swift
//  Surreality
//
//  Created by Will on 8/30/20.
//  Copyright © 2020 Will Loew-Blosser. All rights reserved.
//

import Foundation

import CoreImage
import UIKit
import Photos
import PhotosUI

class PGLFilterGroup: PGLFilterStack {
    //provide prebuilt group of filters that work together for an effect
    // appears as a single filter in the filter selection
    // component filters show after adding to the current stack
    // for depth effects as demoed in WWDC 2017 & 2018 sessions
    // Editing with Depth
    //          https://developer.apple.com/videos/play/wwdc2017/508
    // Creating Photo and Video Effects using Depth
    //          https://developer.apple.com/videos/play/wwdc2018/503/
    // Show FilterGroup as a special category -
    // remove CIDepthBlurEffect from existing category

    // create a protocol for the filter choosing so the group acts like a
    // filter

    // components will be pushed down to specific group subclasses
    // initially the FilterGroup will implement all of the DepthBlurEffect
    let backgroundEffectGroup = [
        "CIAreaMinMaxRed",
        "CIColorMatrix",
        "CIColorClamp",
        "CIPhotoEffectMono",
        "CIBlendWithMask"
    ]

    // depthToDark uses CIColorKernel
    let depthToDarkGroup  = [String]()

    // CIDepthBlurEffect
    let depthBlurGroup = [
        "CIDepthBlurEffect"
    ]
    // DollyZoom - vertexShader, Fragement Shader

    let dollyZoom = [String
    ]()
}
