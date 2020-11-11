/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A cell for displaying an item in our outline view
*/

import UIKit

class OutlineItemCell: UITableViewCell {

    static let reuseIdentifer = "outline-item-cell-reuse-identifier"

    let containerView = UIView()


    var indentLevel: Int = 0 {
        didSet {
            indentContraint.constant = CGFloat(20 * indentLevel)
        }
    }
    var isExpanded = false {
        didSet {
            configureChevron()
        }
    }
    var isGroup = false {
        didSet {
            configureChevron()
        }
    }
    override var isHighlighted: Bool {
        didSet {
            configureChevron()
        }
    }
    override var isSelected: Bool {
        didSet {
            configureChevron()
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?)
    {
        super.init(style:style, reuseIdentifier: reuseIdentifier)
        configure()
        configureChevron()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    fileprivate var indentContraint: NSLayoutConstraint! = nil
    fileprivate let inset = CGFloat(10)
}

extension OutlineItemCell {
    func configure() {
        imageView?.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(imageView!)

        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)

        textLabel!.translatesAutoresizingMaskIntoConstraints = false
        textLabel!.font = UIFont.preferredFont(forTextStyle: .headline)
        textLabel!.adjustsFontForContentSizeCategory = true
        textLabel!.highlightedTextColor = .blue


        indentContraint = containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: inset)
        NSLayoutConstraint.activate([
            indentContraint,
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            imageView!.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            imageView!.heightAnchor.constraint(equalToConstant: 25),
            imageView!.widthAnchor.constraint(equalToConstant: 25),
            imageView!.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),

            textLabel!.leadingAnchor.constraint(equalTo: imageView!.trailingAnchor, constant: 10),
            textLabel!.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            textLabel!.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            textLabel!.topAnchor.constraint(equalTo: containerView.topAnchor)
            ])
    }

    func configureChevron() {
        let rtl = effectiveUserInterfaceLayoutDirection == .rightToLeft
        let chevron = rtl ? "chevron.left.circle.fill" : "chevron.right.circle.fill"
        let chevronSelected = rtl ? "chevron.left.circle.fill" : "chevron.right.circle.fill"
        let circle = "circle.fill"
        let circleFill = "circle.fill"
        let highlighted = isHighlighted || isSelected

        if isGroup {
            let imageName = highlighted ? chevronSelected : chevron
            let image = UIImage(systemName: imageName)
            imageView!.image = image
            let rtlMultiplier = rtl ? CGFloat(-1.0) : CGFloat(1.0)
            let rotationTransform = isExpanded ?
                CGAffineTransform(rotationAngle: rtlMultiplier * CGFloat.pi / 2) :
                CGAffineTransform.identity
            imageView!.transform = rotationTransform
            imageView!.isHidden = false
        } else {

            let imageName = highlighted ? circleFill : circle
            let image = UIImage(systemName: imageName)
            imageView!.image = image
            imageView!.transform = CGAffineTransform.identity
            imageView?.isHidden = true
        }

        imageView!.tintColor = isExpanded ? .systemBlue   :  .systemGreen
//        extension UIColor {
//        static var cornflowerBlue: UIColor {
//            return UIColor(displayP3Red: 100.0 / 255.0, green: 149.0 / 255.0, blue: 237.0 / 255.0, alpha: 1.0)
//        }

    }
}
