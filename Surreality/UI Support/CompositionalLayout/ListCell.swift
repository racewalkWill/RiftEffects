/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A generic cell for a List-list compositional layout
*/

import UIKit

class ListCell: UICollectionViewCell {
    static let reuseIdentifier = "list-cell-reuse-identifier"
    let label = UILabel()  // keep for later use
    let accessoryImageView = UIImageView()  // keep for later use

    var chevronSpaceConstraint: NSLayoutConstraint?
    var imageAssetTrailingConstraint: NSLayoutConstraint?

    let seperatorView = UIView()
    var assetImageView = UIImageView()
     let inset = CGFloat(3)
    let trailingConstant = CGFloat( -20)
    var representedAssetIdentifier = String()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
//        fatalError("Not implemented")
        return
    }
}

extension ListCell {
     func addChevron() {


        let arrowImage = UIImage(systemName: "arrow.right.arrow.left")
        accessoryImageView.image =  arrowImage // chevronImage
        // access the old constraint and change it or update with a new one
//        chevronSpaceConstraint?.constant = 10 // adds trailing space for the accessoryImageView
        imageAssetTrailingConstraint?.constant = trailingConstant
            // moves imageAsset trailing edge off the content view for the chevron
        accessoryImageView.isHidden = false


    }

    override func prepareForReuse() {
        accessoryImageView.isHidden = true
        imageAssetTrailingConstraint?.constant = -inset
        representedAssetIdentifier = String()
//        assetImageView = UIImageView()

        super.prepareForReuse()

    }

    func configure() {
        seperatorView.translatesAutoresizingMaskIntoConstraints = false
        seperatorView.backgroundColor = .lightGray
        contentView.addSubview(seperatorView)

//        label.translatesAutoresizingMaskIntoConstraints = false
//        label.adjustsFontForContentSizeCategory = true
//        label.font = UIFont.preferredFont(forTextStyle: .body)
//        contentView.addSubview(label)

        accessoryImageView.translatesAutoresizingMaskIntoConstraints = false
       
        accessoryImageView.tintColor = UIColor.lightGray.withAlphaComponent(0.7)
        
        contentView.addSubview(accessoryImageView)

        assetImageView.translatesAutoresizingMaskIntoConstraints = false

        assetImageView.contentMode = UIView.ContentMode.scaleAspectFit // better than .scaleAspectFill
        contentView.addSubview(assetImageView)

        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)



        NSLayoutConstraint.activate([
//            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: inset),
//            label.widthAnchor.constraint(equalToConstant: 50),
//            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: inset),
//            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -inset),
//            label.trailingAnchor.constraint(equalTo: accessoryImageView.leadingAnchor, constant: -inset),


//            assetImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
//            assetImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            assetImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: inset),
            assetImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -inset),

            assetImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: inset),


            accessoryImageView.centerYAnchor.constraint(equalTo: assetImageView.centerYAnchor),
            accessoryImageView.widthAnchor.constraint(equalToConstant: 13),
            accessoryImageView.heightAnchor.constraint(equalToConstant: 20),
            accessoryImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -inset),

            seperatorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: inset),
            seperatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            seperatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -inset),
            seperatorView.heightAnchor.constraint(equalToConstant: 0.5)
            ])
            imageAssetTrailingConstraint =  assetImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -inset)
            imageAssetTrailingConstraint?.isActive = true
//            chevronSpaceConstraint = accessoryImageView.leadingAnchor.constraint(equalTo: assetImageView.trailingAnchor, constant: inset)
//            chevronSpaceConstraint?.isActive = true
    }


}
