//
//  PGLLibraryController.swift
//  RiftEffects
//
//  Created by Will on 6/28/23.
//  Copyright © 2023 Will Loew-Blosser. All rights reserved.
//

import UIKit
import CoreData
import os

class PGLLibraryController:  UIViewController, NSFetchedResultsControllerDelegate {
    // combines example CollectionViewSample from WWDC21
    //  'Make blazing fast lists and collection views'
    // with  old PGLOpenStackController
    // change to large sizer images and arrange rows by categories

    var dataSource: UICollectionViewDiffableDataSource<Int, CDFilterStack>! = nil
    private lazy var dataProvider: PGLStackProvider = {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
      let provider = PGLStackProvider(with: appDelegate!.dataWrapper.persistentContainer)
//        let provider = appDelegate?.appStack.dataProvider
        provider.setFetchControllerForStackViewContext()
        provider.fetchedResultsController.delegate = self
        return provider
    }()

    var collectionView: UICollectionView! = nil
    fileprivate let sectionHeaderElementKind = "SectionHeader"

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Library"
        configureHierarchy()
        configureDataSource()
        setCategoryData()
    }

}

extension PGLLibraryController {
    private func configureHierarchy() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .systemBackground

//        collectionView.prefetchDataSource = self
        // not implementing the prefetch yet

        view.addSubview(collectionView)
    }

    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<PGLLibraryCell, CDFilterStack> { [weak self] cell, indexPath, aCDFilterStack in
            guard let self = self else { return }

            cell.configureFor(aCDFilterStack)
            //MARK: pre fetch
//            let post = self.postsStore.fetchByID(postID)
//            let asset = self.assetsStore.fetchByID(post.assetID)
//
//            // Retrieve the token that's tracking this asset from either the prefetching operations dictionary
//            // or just use a token that's already set on the cell, which is the case when a cell is being reconfigured.
//            var assetToken = self.prefetchingIndexPathOperations.removeValue(forKey: indexPath) ?? cell.assetToken
//
//            // If the asset is a placeholder and there is no token, ask the asset store to load it, reconfiguring
//            // the cell in its completion handler.
//            if asset.isPlaceholder && assetToken == nil {
//                assetToken = self.assetsStore.loadAssetByID(post.assetID) { [weak self] in
//                    self?.setPostNeedsUpdate(postID)
//                }
//            }

        }

        dataSource = UICollectionViewDiffableDataSource<Int, CDFilterStack>(collectionView: collectionView) {
            (collectionView, indexPath, aCDFilterStack) in

            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: aCDFilterStack)
        }

        let headerRegistration = createSectionHeaderRegistration()
        dataSource.supplementaryViewProvider = { collectionView, elementKind, indexPath in
            return collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
        }
    }
    
    private func setCategoryData() {
        // Initial data
        try? dataProvider.fetchedResultsController.performFetch()

        var snapshot = NSDiffableDataSourceSnapshot<Int, CDFilterStack>()
        
        if let sections = dataProvider.fetchedResultsController.sections {
            for index in  0..<sections.count
              {
                snapshot.appendSections([index])
                let thisSection = sections[index]
                if let sectionStacks = thisSection.objects as? [CDFilterStack]
                {
                        snapshot.appendItems(sectionStacks)
                }
                 // show empty snapshot
            }

        }
        dataSource.apply(snapshot, animatingDifferences: false)
    }

}

extension PGLLibraryController {
    private func createSectionHeaderRegistration() -> UICollectionView.SupplementaryRegistration<UICollectionViewListCell> {
        return UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(
            elementKind: sectionHeaderElementKind
        ) { [weak self] supplementaryView, elementKind, indexPath in
            guard let self = self else { return }

            let sectionID = self.dataSource.snapshot().sectionIdentifiers[indexPath.section]

            supplementaryView.configurationUpdateHandler = { supplementaryView, state in
                guard let supplementaryCell = supplementaryView as? UICollectionViewListCell else { return }

                var contentConfiguration = UIListContentConfiguration.plainHeader().updated(for: state)

                contentConfiguration.textProperties.font = PGLAppearance.sectionHeaderFont
                contentConfiguration.textProperties.color = UIColor.label

                contentConfiguration.text = "SectionID" // sectionID

                supplementaryCell.contentConfiguration = contentConfiguration

                supplementaryCell.backgroundConfiguration = .clear()
            }
        }
    }

    /// - Tag: Grid
    private func createLayout() -> UICollectionViewLayout {
        let sectionProvider = { (sectionIndex: Int,
            layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                 heightDimension: .estimated(350))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            // If there's space, adapt and go 2-up + peeking 3rd item.
            let columnCount = layoutEnvironment.container.effectiveContentSize.width > 500 ? 3 : 1
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                   heightDimension: .estimated(350))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: columnCount)
            group.interItemSpacing = .fixed(20)

            let section = NSCollectionLayoutSection(group: group)
            let sectionID = self.dataSource.snapshot().sectionIdentifiers[sectionIndex]

            section.interGroupSpacing = 20

            if sectionID == 0   //.featured
            {
                section.decorationItems = [
                    .background(elementKind: "SectionBackground")
                ]

                let titleSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                       heightDimension: .estimated(PGLAppearance.sectionHeaderFont.lineHeight))
                let titleSupplementary = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: titleSize,
                    elementKind: self.sectionHeaderElementKind,
                    alignment: .top)

                section.boundarySupplementaryItems = [titleSupplementary]
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 20, trailing: 20)
            } else {
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 20, trailing: 20)
            }
            return section
        }

        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.interSectionSpacing = 20

        let layout = UICollectionViewCompositionalLayout(
            sectionProvider: sectionProvider, configuration: config)

        layout.register(PGLSectionBackgroundDecorationView.self, forDecorationViewOfKind: "SectionBackground")
        return layout
    }
}

