/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Simple example of a self-sizing supplementary title view
*/

import UIKit

class TitleSupplementaryView: UICollectionReusableView {
    let label = UILabel()
    let symbolImage = UIImageView()
    static let reuseIdentifier = "title-supplementary-reuse-identifier"
    static let expandSymbol = UIImage(systemName: "plus.magnifyingglass"
    )
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
//        fatalError()
    }
    var headerAlbumId: String?
}

extension TitleSupplementaryView {
    func configure() {
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.font = UIFont.preferredFont(forTextStyle: .title3)  // title2


        symbolImage.image = TitleSupplementaryView.expandSymbol
        symbolImage.translatesAutoresizingMaskIntoConstraints = false
        symbolImage.contentMode = UIView.ContentMode.scaleAspectFit
        symbolImage.backgroundColor = .systemGreen
        symbolImage.translatesAutoresizingMaskIntoConstraints = false
        addSubview(symbolImage)

        let margins = self.layoutMarginsGuide
        let inset = CGFloat(10)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: inset),
            label.trailingAnchor.constraint(equalTo: margins.trailingAnchor, constant: -inset),
            label.topAnchor.constraint(equalTo: margins.topAnchor, constant: inset),
            label.bottomAnchor.constraint(equalTo: margins.bottomAnchor, constant: -inset),
//            symbolImage.firstBaselineAnchor.constraint(equalTo: label.firstBaselineAnchor),
            symbolImage.trailingAnchor.constraint(equalTo: margins.trailingAnchor, constant: -inset),
            symbolImage.topAnchor.constraint(equalTo: margins.topAnchor),
            symbolImage.bottomAnchor.constraint(equalTo: margins.bottomAnchor),
            symbolImage.widthAnchor.constraint(equalToConstant: 40.0) // keep it big
        ])





    }
}
