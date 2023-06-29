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
        collectionView.delegate = self
    }

    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<PGLLibraryCell, CDFilterStack> { [weak self] cell, indexPath, aCDFilterStack in
            guard self != nil else { return }

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
            let currentSnapshot = self.dataSource.snapshot()
            let sectionID = currentSnapshot.sectionIdentifiers[indexPath.section]

            supplementaryView.configurationUpdateHandler = { supplementaryView, state in
                guard let supplementaryCell = supplementaryView as? UICollectionViewListCell else { return }

                var contentConfiguration = UIListContentConfiguration.plainHeader().updated(for: state)

                contentConfiguration.textProperties.font = PGLAppearance.sectionHeaderFont
                contentConfiguration.textProperties.color = UIColor.label

                if let firstInSectionItem = currentSnapshot.itemIdentifiers(inSection: sectionID).first {
                    contentConfiguration.text = firstInSectionItem.type
                } else {
                    contentConfiguration.text = ""
                }
                    //  from dataProvider.fetchedResultsController.sections name attribute

                supplementaryCell.contentConfiguration = contentConfiguration

                supplementaryCell.backgroundConfiguration = .clear()
            }
        }
    }

    /// - Tag: Grid
    private func createLayout() -> UICollectionViewLayout {
        let sectionProvider = { (sectionIndex: Int,
            layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.8),
                                                 heightDimension: .estimated(150))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            // If there's space, adapt and go 2-up + peeking 3rd item.

            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                   heightDimension: .estimated(250))


            let containerGroupFractionalWidth = CGFloat(0.85)
            let containerGroup = NSCollectionLayoutGroup.horizontal(
                layoutSize: groupSize, subitems: [item])

            let section = NSCollectionLayoutSection(group: containerGroup)
            section.orthogonalScrollingBehavior = UICollectionLayoutSectionOrthogonalScrollingBehavior.continuous

            containerGroup.interItemSpacing = .fixed(20)


            let sectionID = self.dataSource.snapshot().sectionIdentifiers[sectionIndex]

            section.interGroupSpacing = 20

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

extension PGLLibraryController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            // pick and show this row
            // even if in edit mode

//            if let object = (for: indexPath)
        if let object = dataSource.itemIdentifier(for: indexPath)
                {
                guard let myAppDelegate =  UIApplication.shared.delegate as? AppDelegate
                    else {
                    Logger(subsystem: LogSubsystem, category: LogNavigation).fault("\( String(describing: self) + "-" + #function) appDelegate not assigned")
                    return
                }
                let stackId = object.objectID // managedObjectID

                let theAppStack = myAppDelegate.appStack


                theAppStack.resetToTopStack(newStackId: stackId)

                postStackChange()
                    // trigger the image controller to show the stack


            }
    }

    func postStackChange() {

        let stackNotification = Notification(name:PGLLoadedDataStack)
        NotificationCenter.default.post(stackNotification)
        let filterNotification = Notification(name: PGLCurrentFilterChange) // turns on the filter cell detailDisclosure button even on cancels
//            NotificationCenter.default.post(filterNotification)
        NotificationCenter.default.post(name: filterNotification.name, object: nil, userInfo: ["sender" : self as AnyObject])

    }

}

