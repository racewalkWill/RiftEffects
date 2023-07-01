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
import Combine

let ThumbnailPreferredHeight: CGFloat = 150.0

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

    var collectionView: UICollectionView!
    fileprivate let sectionHeaderElementKind = "SectionHeader"
    let searchBar = UISearchBar(frame: .zero)

// MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Library"
        configureHierarchy()
        configureDataSource()
        setCategoryData()
    }

}

// MARK: Configure
extension PGLLibraryController {
     func configureHierarchy() {
        let layout = createLayout()
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .systemBackground

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        searchBar.translatesAutoresizingMaskIntoConstraints = false

//        collectionView.prefetchDataSource = self
        // not implementing the prefetch yet

        view.addSubview(collectionView)
        view.addSubview(searchBar)


         let views: [String: UIView] = ["cv": collectionView, "searchBar": searchBar]
        var constraints = [NSLayoutConstraint]()
        constraints.append(contentsOf: NSLayoutConstraint.constraints(
            withVisualFormat: "H:|[cv]|", options: [], metrics: nil, views: views))
        constraints.append(contentsOf: NSLayoutConstraint.constraints(
            withVisualFormat: "H:|[searchBar]|", options: [], metrics: nil, views: views))
        constraints.append(contentsOf: NSLayoutConstraint.constraints(
            withVisualFormat: "V:[searchBar]-20-[cv]|", options: [], metrics: nil, views: views))
        constraints.append(searchBar.topAnchor.constraint(
            equalToSystemSpacingBelow: view.safeAreaLayoutGuide.topAnchor, multiplier: 1.0))
        NSLayoutConstraint.activate(constraints)

        collectionView.delegate = self
        searchBar.delegate = self


    }

    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<PGLLibraryCell, CDFilterStack> { [weak self] cell, indexPath, aCDFilterStack in
            guard let self = self else { return }

        cell.configureFor(aCDFilterStack)
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

    private func setPostNeedsUpdate(_ id: CDFilterStack) {
        var snapshot = self.dataSource.snapshot()
        snapshot.reconfigureItems([id])
        self.dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    fileprivate func applySnapShot(stacks: [CDFilterStack]) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, CDFilterStack>()

        if let sections = dataProvider.fetchedResultsController.sections {
            for index in  0..<sections.count
            {
                if let thisSectionElements = sections[index].objects as? [CDFilterStack]
                {
                    let matchingElements = thisSectionElements.filter({
                        stacks.contains($0)
                    })
                    if !matchingElements.isEmpty {
                        snapshot.appendSections([index])
                        snapshot.appendItems(matchingElements, toSection: index)
                    }

                }
            }

        }
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    private func setCategoryData() {
        // Initial data
        // load everything
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

        /// - Tag: performQuer
    func performQuery(with titleFilter: String?) {
        // load only matching titles
        var matchingStacks: [CDFilterStack]!
        if let lowerCaseFilter = titleFilter?.lowercased() {
            matchingStacks = dataProvider.fetchedStacks?.filter({
                if let lowerTitle =  $0.title?.lowercased() {
                    return lowerTitle.contains(lowerCaseFilter)
                } else {return false }
            })
        }
        else
        { matchingStacks = dataProvider.fetchedStacks }

        applySnapShot(stacks: matchingStacks)

    }

}

extension PGLLibraryController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        performQuery(with: searchText)
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
                                                 heightDimension: .estimated(ThumbnailPreferredHeight))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            // If there's space, adapt and go 2-up + peeking 3rd item.

            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                   heightDimension: .estimated(ThumbnailPreferredHeight))

            let containerGroup = NSCollectionLayoutGroup.horizontal(
                layoutSize: groupSize, subitems: [item])

            let section = NSCollectionLayoutSection(group: containerGroup)
            section.orthogonalScrollingBehavior = UICollectionLayoutSectionOrthogonalScrollingBehavior.continuous

            containerGroup.interItemSpacing = .fixed(10)

//            let sectionID = self.dataSource.snapshot().sectionIdentifiers[sectionIndex]

            section.interGroupSpacing = 10

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
        config.interSectionSpacing = 10

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


