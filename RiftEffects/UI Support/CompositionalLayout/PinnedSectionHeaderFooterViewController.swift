/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Pinned sction headers example
*/

import UIKit
import Photos
import PhotosUI

//class PinnedSectionHeaderFooterViewController: UIViewController {
//
//    static let sectionHeaderElementKind = "section-header-element-kind"
//
//
//    var dataSource: UICollectionViewDiffableDataSource<Int, Int>! = nil
//    var collectionView: UICollectionView! = nil
//    // Glance additions
//    var userAssetSelection: PGLUserAssetSelection!
//    fileprivate let imageManager = PHCachingImageManager()
//     fileprivate var thumbnailSize: CGSize!
//
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
////        PHPhotoLibrary.shared().register(self)
//
//        navigationItem.title = "Pinned Section Headers"
//        configureHierarchy()
//        configureDataSource()
//    }
//
//
////deinit {
////      PHPhotoLibrary.shared().unregisterChangeObserver(self)
////
////  }
//
//}
//
//extension PinnedSectionHeaderFooterViewController {
//    func createLayout() -> UICollectionViewLayout {
//        let columnCount = 5
//        let groupSizeHeight: CGFloat = 1.0/CGFloat(columnCount)
//
//        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
//                                             heightDimension: .fractionalHeight(1.0))
//        let item = NSCollectionLayoutItem(layoutSize: itemSize)
//        item.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)
//        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
//                                               heightDimension: .fractionalHeight(groupSizeHeight))
////            .estimated(80.0))  //heightDimension: .absolute(80)
//
//        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: columnCount)
//
//        let spacing = CGFloat(2)
////        group.interItemSpacing = .fixed(spacing)
//        group.interItemSpacing = .flexible(spacing)
//
//        let section = NSCollectionLayoutSection(group: group)
//        section.interGroupSpacing = spacing
//        section.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5)
//
//        let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
//            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
//                                              heightDimension: .estimated(44)),
//            elementKind: PinnedSectionHeaderFooterViewController.sectionHeaderElementKind,
//            alignment: .top)
//
//        sectionHeader.pinToVisibleBounds = true
////        sectionHeader.zIndex = 2  // what does this do?
//            // defn -   default is 0; all other section items will be automatically be promoted to zIndex=1
//
//         section.boundarySupplementaryItems = [sectionHeader ]
//
//        let layout = UICollectionViewCompositionalLayout(section: section)
//        return layout
//    }
//}
//
//extension PinnedSectionHeaderFooterViewController {
//    func configureHierarchy() {
//        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
//        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        collectionView.backgroundColor = .systemBackground
//        collectionView.register(ListCell.self, forCellWithReuseIdentifier: ListCell.reuseIdentifier)
//        collectionView.register(TitleSupplementaryView.self,
//                    forSupplementaryViewOfKind: PinnedSectionHeaderFooterViewController.sectionHeaderElementKind,
//                    withReuseIdentifier: TitleSupplementaryView.reuseIdentifier)
//
//        view.addSubview(collectionView)
//        collectionView.delegate = self
//    }
//    func configureDataSource() {
//        dataSource = UICollectionViewDiffableDataSource<Int, Int>(collectionView: collectionView) {
//            (collectionView: UICollectionView, indexPath: IndexPath, identifier: Int) -> UICollectionViewCell? in
//
//            // Get a cell of the desired kind.
//            guard let cell = collectionView.dequeueReusableCell(
//                withReuseIdentifier: ListCell.reuseIdentifier,
//                for: indexPath) as? ListCell else { fatalError("Cannot create new cell") }
//
//            // Populate the cell with our item description.
////            cell.label.text = "\(indexPath.section),\(indexPath.item)"
//            let asset = self.userAssetSelection.fetchResult?.object(at: indexPath.item)
//
//             cell.representedAssetIdentifier = asset.localIdentifier
//
//
//            let thumbnailSize = CGSize(width: 100.0, height: 100.0)
//
//
//            self.imageManager.requestImage(for: asset, targetSize: thumbnailSize, contentMode: .aspectFill, options: nil, resultHandler: { image, _ in
//                // The cell may have been recycled by the time this handler gets called;
//                // set the cell's thumbnail image only if it's still showing the same asset.
//                if cell.representedAssetIdentifier == asset.localIdentifier {
////                    cell.thumbnailImage = image
//                    if let storedThumbNail  = image {
//                        cell.assetImageView.image = storedThumbNail
//                    }
//                }
//                
//            })
//
//            // Return the cell.
//            return cell
//        }
//        dataSource.supplementaryViewProvider = {
//            (collectionView: UICollectionView, kind: String, indexPath: IndexPath) -> UICollectionReusableView? in
//
//            // Get a supplementary view of the desired kind.
//            guard let headerFooter = collectionView.dequeueReusableSupplementaryView(
//                ofKind: kind,
//                withReuseIdentifier: TitleSupplementaryView.reuseIdentifier,
//                for: indexPath) as? TitleSupplementaryView else { fatalError("Cannot create new header") }
//
//            // Populate the view with our section's description.
//            let viewKind = kind == PinnedSectionHeaderFooterViewController.sectionHeaderElementKind ?
//                "Header" : "Footer"
//            headerFooter.label.text = "\(viewKind) for section \(indexPath.section)"
//            headerFooter.backgroundColor = .lightGray
//            headerFooter.layer.borderColor = UIColor.black.cgColor
//            headerFooter.layer.borderWidth = 1.0
//
//            // Return the view.
//            return headerFooter
//        }
//
//        // initial data
//        let itemsPerSection = userAssetSelection.fetchCount()
//        let sections = [0]
//        var snapshot = NSDiffableDataSourceSnapshot<Int, Int>()
//        var itemOffset = 0
//        sections.forEach {
//            snapshot.appendSections([$0])
//            snapshot.appendItems(Array(itemOffset..<itemOffset + itemsPerSection))
//            itemOffset += itemsPerSection
//        }
//        dataSource.apply(snapshot, animatingDifferences: false)
//    }
//}
//
//extension PinnedSectionHeaderFooterViewController: UICollectionViewDelegate {
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        collectionView.deselectItem(at: indexPath, animated: true)
//    }
//}
