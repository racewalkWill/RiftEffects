//
//  PGLAppearance.swift
//  RiftEffects
//
//  Created by Will on 6/28/23.
//  Copyright © 2023 Will Loew-Blosser. All rights reserved.
//
//  Based on Apple example 'Collection View Sample'
//  from WWDC21
//      'Make blazing fast lists and collection views'

import Foundation
import UIKit

struct PGLAppearance {
    static let sectionHeaderFont: UIFont = {
        let boldFontDescriptor = UIFontDescriptor
            .preferredFontDescriptor(withTextStyle: .largeTitle)
            .withSymbolicTraits(.traitBold)!
        return UIFont(descriptor: boldFontDescriptor, size: 0)
    }()

    static let postImageHeightRatio = 0.8

    static let titleFont: UIFont = {
        let descriptor = UIFontDescriptor
            .preferredFontDescriptor(withTextStyle: .title1)
            .withSymbolicTraits(.traitBold)!
        return UIFont(descriptor: descriptor, size: 0)
    }()

    static let subtitleFont: UIFont = {
        let descriptor = UIFontDescriptor
            .preferredFontDescriptor(withTextStyle: .body)
            .withSymbolicTraits(.traitBold)!
        return UIFont(descriptor: descriptor, size: 0)
    }()

    static let likeCountFont: UIFont = {
        let descriptor = UIFontDescriptor
            .preferredFontDescriptor(withTextStyle: .subheadline)
            .withDesign(.monospaced)!
        return UIFont(descriptor: descriptor, size: 0)
    }()
}
