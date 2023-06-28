//
//  PGLSectionBackgroundDecorationView.swift
//  RiftEffects
//
//  Created by Will on 6/28/23.
//  Copyright © 2023 Will Loew-Blosser. All rights reserved.
//   Based on Apple example 'Collection View Sample'
//  from WWDC21
//      'Make blazing fast lists and collection views'


import UIKit

class PGLSectionBackgroundDecorationView: UICollectionReusableView {
    private var gradientLayer = CAGradientLayer()
    override init(frame: CGRect) {
        super.init(frame: frame)

        configure()
    }
    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }
}

extension PGLSectionBackgroundDecorationView {
    func configure() {
        gradientLayer.colors = [UIColor.systemBackground.withAlphaComponent(0).cgColor, UIColor.systemPink.withAlphaComponent(0.5).cgColor]
        layer.addSublayer(gradientLayer)
        gradientLayer.frame = layer.bounds
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = layer.bounds
    }
}

