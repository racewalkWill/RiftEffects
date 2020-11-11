//
//  StackDataCell.swift
//  Glance
//
//  Created by Will Loew-Blosser on 7/10/20.
//  Copyright © 2020 Will Loew-Blosser. All rights reserved.
//

// adapted from Apple TextCell.swift

import UIKit

class StackDataCell: UICollectionViewCell {
    static let reuseIdentifier = "stackData-cell-reuse-identifier"
    let titleLabel = UILabel()  // keep for later use
    let typeLabel = UILabel()

    let dateCreatedLabel = UILabel()
    let dateModifiedLabel = UILabel()

    var thumbnailImageView = UIImageView()
     let inset = CGFloat(3)
    let trailingConstant = CGFloat( 20)
    var representedAssetIdentifier = String()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }
}

extension StackDataCell {
//     func addChevron() {


//        let arrowImage = UIImage(systemName: "arrow.right.arrow.left")
//        accessoryImageView.image =  arrowImage // chevronImage
        // access the old constraint and change it or update with a new one
//        chevronSpaceConstraint?.constant = 10 // adds trailing space for the accessoryImageView
//        imageAssetTrailingConstraint?.constant = trailingConstant
            // moves imageAsset trailing edge off the content view for the chevron
//        accessoryImageView.isHidden = false


//    }

    override func prepareForReuse() {
        titleLabel.text = String()
        typeLabel.text = String()

        dateCreatedLabel.text = String()
        dateModifiedLabel.text = String()

//        imageAssetTrailingConstraint?.constant = -inset
        representedAssetIdentifier = String()
       thumbnailImageView = UIImageView()

        super.prepareForReuse()

    }

    func configure() {
        let labels = [titleLabel, typeLabel ] // , dateCreatedLabel, dateModifiedLabel]


        for aLabel in labels {
            aLabel.translatesAutoresizingMaskIntoConstraints = false
            aLabel.adjustsFontForContentSizeCategory = true
            aLabel.font = UIFont.preferredFont(forTextStyle: .body)
            contentView.addSubview(aLabel)
        }
       titleLabel.font = UIFont.preferredFont(forTextStyle: .title3)

        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false

        thumbnailImageView.contentMode = UIView.ContentMode.scaleAspectFit // better than .scaleAspectFill
        contentView.addSubview(thumbnailImageView)

        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)

        NSLayoutConstraint.activate([
            thumbnailImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: inset),
            thumbnailImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0),
            thumbnailImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0),
            thumbnailImageView.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 0),

            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0),
            titleLabel.trailingAnchor.constraint(equalTo: thumbnailImageView.leadingAnchor, constant: 0),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
            titleLabel.bottomAnchor.constraint(equalTo: typeLabel.topAnchor, constant: 0),

            typeLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 0),
            typeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: trailingConstant),
            typeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0)



            ])


    }


}

