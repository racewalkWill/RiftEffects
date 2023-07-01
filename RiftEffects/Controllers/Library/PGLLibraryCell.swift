//
//  PGLLibraryCell.swift
//  RiftEffects
//
//  Created by Will on 6/28/23.
//  Copyright © 2023 Will Loew-Blosser. All rights reserved.
//  Based on Apple example 'Collection View Sample'
//  from WWDC21
//      'Make blazing fast lists and collection views'

import Foundation
import UIKit
import Combine
import os

extension CACornerMask {
    static func alongEdge(_ edge: CGRectEdge) -> CACornerMask {
        switch edge {
        case .maxXEdge: return [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        case .maxYEdge: return [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        case .minXEdge: return [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        case .minYEdge: return [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        }
    }
}


class PGLLibraryCell: UICollectionViewCell {

    // Set on each cell to track asset use. The cell will call cancel on the token when
    // preparing for reuse or when it deinitializes.
    public var assetToken: Cancellable?
    let dateFormatter = DateFormatter()

    private let imageView = UIImageView()
    private let propertiesView = PGLLibraryPropertiesView()

    private var validLayoutBounds: CGRect? = nil
    private var validSizeThatFits: CGSize? = nil

    override init(frame: CGRect) {
        super.init(frame: frame)
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .secondarySystemBackground
        // Clips to Bounds because images draw outside their bounds
        // when a corner radius is set.
        imageView.clipsToBounds = true

        contentView.addSubview(imageView)
        contentView.addSubview(propertiesView)

        contentView.layer.cornerCurve = .continuous
        contentView.layer.cornerRadius = 12.0
        self.pushCornerPropertiesToChildren()

        layer.shadowOpacity = 0.2
        layer.shadowRadius = 6.0
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        assetToken?.cancel()
        assetToken = nil
    }

    public func configureFor(_ asset: CDFilterStack) {

        if asset.thumbnail == nil {
            imageView.image = UIImage(systemName: "airplane.circle.fill")!
            return
        } else {
            imageView.image = UIImage(data: asset.thumbnail!)!
        }

        propertiesView.titleLabel.text = asset.title
        propertiesView.subtitleLabel.text = self.detailTextString(ofObject: asset)

    }


    func detailTextString(ofObject: CDFilterStack) -> String {
        var dateString: String
       if let modifiedDate =  ofObject.modified {
           dateString = dateFormatter.string(from: modifiedDate)
       }
       else { guard let createdDate = ofObject.created else
                {  return " "
                    }
           dateString =  dateFormatter.string(from: createdDate )

       }

        return  dateString
    }



    override func layoutSubviews() {
        super.layoutSubviews()

        let (imageFrame, propertiesFrame) = bounds.divided(atDistance: imageHeight(at: bounds.size),
                                                           from: .minYEdge)

        imageView.frame = imageFrame
        propertiesView.frame = propertiesFrame

        // Setting a shadow path avoids costly offscreen passes.
        layer.shadowPath = UIBezierPath(roundedRect: bounds,
                                        cornerRadius: contentView.layer.cornerRadius).cgPath
        previousBounds = self.bounds.size
    }

    // Override `sizeThatFits` so it can ask the `propertiesView`.
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var height = self.imageHeight(at: size)
        height += propertiesView.sizeThatFits(size).height

        return CGSize(width: size.width, height: height)
    }

    // A cache value to ensure it doesn't relay out.
    private var previousBounds: CGSize = .zero

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        // If it's already rendered at the proposed size it can just return.
        if previousBounds == layoutAttributes.size && !propertiesView.needsRelayout {
            return layoutAttributes
        } else {
            // This will call `sizeThatFits`.
            return super.preferredLayoutAttributesFitting(layoutAttributes)
        }
    }

    // Applying the corner radius to the children means not having to set `clipsToBounds` which
    // saves from having extra offscreen passes.
    private func pushCornerPropertiesToChildren() {
        imageView.layer.maskedCorners = contentView.layer.maskedCorners.intersection(.alongEdge(.minYEdge))
        propertiesView.layer.maskedCorners = contentView.layer.maskedCorners.intersection(.alongEdge(.maxYEdge))

        imageView.layer.cornerRadius = contentView.layer.cornerRadius
        propertiesView.layer.cornerRadius = contentView.layer.cornerRadius

        imageView.layer.cornerCurve = contentView.layer.cornerCurve
        propertiesView.layer.cornerCurve = contentView.layer.cornerCurve
    }

    private func imageHeight(at size: CGSize) -> CGFloat {
        return ceil(size.width * PGLAppearance.postImageHeightRatio)
    }
}

