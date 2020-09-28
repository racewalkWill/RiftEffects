//
//  PGLSelectStackController.swift
//  Glance
//
//  Created by Will Loew-Blosser on 7/9/20.
//  Copyright © 2020 Will Loew-Blosser. All rights reserved.
//

import UIKit
import Photos
import PhotosUI
import CoreData

class PGLSelectStackController: UIViewController,  NSFetchedResultsControllerDelegate , UICollectionViewDelegate {
    // NOT USED 7/15/20.. but has useful features.
    // See PGLImageController openStackActionBtn which can open
    // either PGLSelectStackController or PGLOpenStackViewController
    // PGLOpenStackViewController is the UITableViewController version
    // PGLSelectStackController is the CollectionView version

    // select saved filter stacks from the data store
    // delete stacks from the data store
    // use CollectionView

    static let sectionHeaderElementKind = "section-header-element-kind"

    lazy var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult> = setFetchController()
        //  model object

    lazy var moContext: NSManagedObjectContext = PersistentContainer.viewContext

      var simpleCollectionView: UICollectionView! = nil
      var dataSource: UICollectionViewDiffableDataSource<Int, CDFilterStack>! = nil


    // MARK: View life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        do { try fetchedResultsController.performFetch() }
               catch { fatalError("PGLSelectStackController #viewDidLoad performFetch() error = \(error)") }
        navigationItem.title = "Saved Filter Stacks"
        configureHierarchy()
        configureDataSource()

        applyDataSource()
    }

// MARK: data fetch
    func setFetchController() -> NSFetchedResultsController<NSFetchRequestResult> {
                let myMOContext = moContext
                let stackRequest = NSFetchRequest<CDFilterStack>(entityName: "CDFilterStack")
                stackRequest.predicate = NSPredicate(format: "inputToFilter = null")

                    // only CDFilterStacks with outputToParm = null.. ie it is not a child stack)
                var sortArray = [NSSortDescriptor]()

                sortArray.append(NSSortDescriptor(key: "title", ascending: true))
        //        sortArray.append(NSSortDescriptor(key: "type", ascending: true))

                stackRequest.sortDescriptors = sortArray

            fetchedResultsController = NSFetchedResultsController(fetchRequest: stackRequest, managedObjectContext: myMOContext, sectionNameKeyPath: "type", cacheName: nil ) as! NSFetchedResultsController<NSFetchRequestResult>
                    // or cacheName = "GlanceStackCache"

    //            fetchedResultsController.delegate = self
            // set delegate if change notifications are needed for insert, delete, etc in the manageobjects
                return fetchedResultsController


        }

// MARK: CompositionLayout

    func applyDataSource() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, CDFilterStack >()
        var cdFilterStacks: [CDFilterStack]
        let sectionCount = fetchedResultsController.sections!.count
        for thisSectionIndex in 0 ..< sectionCount {
            let aSection = fetchedResultsController.sections![thisSectionIndex]
            cdFilterStacks = [CDFilterStack]() // reset to empty
            for aStackFetch in aSection.objects! {
                if let thisStack = aStackFetch as? CDFilterStack {
                    cdFilterStacks.append(thisStack)
                }
            }
         snapshot.appendSections([thisSectionIndex])
         snapshot.appendItems(cdFilterStacks, toSection: thisSectionIndex)
        }
      if snapshot.numberOfSections != snapshot.sectionIdentifiers.count {
          fatalError("snapshot.numberOfSections != snapshot.sectionIdentifiers.count")
      }
        dataSource.apply(snapshot, animatingDifferences: false)
  }



      func configureHierarchy() {
        simpleCollectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        simpleCollectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        simpleCollectionView.backgroundColor = .systemBackground
        simpleCollectionView.register(StackDataCell.self, forCellWithReuseIdentifier: StackDataCell.reuseIdentifier)
        // register supplementary views
//        collectionView.register(TitleSupplementaryView.self,
//            forSupplementaryViewOfKind: PGLSelectStackController.sectionHeaderElementKind,
//            withReuseIdentifier: TitleSupplementaryView.reuseIdentifier)

        view.addSubview(simpleCollectionView)
        simpleCollectionView.delegate = self
        // Value of type '(UICollectionView, IndexPath) -> ()' has no member 'delegate'
    }

    func createLayout() -> UICollectionViewLayout {
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                     heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)

                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                      heightDimension: NSCollectionLayoutDimension.fractionalWidth(0.1))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                                 subitems: [item])

                let section = NSCollectionLayoutSection(group: group)

                let layout = UICollectionViewCompositionalLayout(section: section)
                return layout
            }

     func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Int, CDFilterStack>(collectionView: simpleCollectionView) { [weak self]
                      (collectionView: UICollectionView, indexPath: IndexPath, identifier: CDFilterStack) -> UICollectionViewCell? in
            guard self != nil
                else { return  nil}
                      // Get a cell of the desired kind.
            guard let cell = collectionView.dequeueReusableCell(
                      withReuseIdentifier: StackDataCell.reuseIdentifier,
                      for: indexPath) as? StackDataCell else { fatalError("Cannot create new cell") }

            cell.titleLabel.text = identifier.title ?? "untitled"

            cell.typeLabel.text = identifier.type
//            cell.albumLabel.text = identifier.
//            cell.dateCreatedLabel.text = String(identifier.created)
//            cell.dateModifiedLabel.text = String(identifier.modified)
            if let stackThumbnail =  identifier.thumbnail {
                    cell.thumbnailImageView.image = UIImage(data: stackThumbnail )
            }
            return cell
        }
    }


// MARK: UICollectionViewDelegate


    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // start with saved stack... later have it insert on the selected parm as new input
              if let object = (self.fetchedResultsController.object(at: indexPath)) as? CDFilterStack {

                  if let theAppStack = (UIApplication.shared.delegate as? AppDelegate)!.appStack {

                      let storedPGLStack = PGLFilterStack(readName: object.title!)
                      theAppStack.resetToTopStack(newStack: storedPGLStack)
                      postStackChange()
                  }

              }
              dismiss(animated: true, completion: nil )
        }

    func postStackChange() {

            let stackNotification = Notification(name:PGLStackChange)
            NotificationCenter.default.post(stackNotification)
            let filterNotification = Notification(name: PGLCurrentFilterChange) // turns on the filter cell detailDisclosure button even on cancels
            NotificationCenter.default.post(filterNotification)
        }
        /*
         // Override to support conditional editing of the table view.
         override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
         // Return false if you do not want the specified item to be editable.
         return true
         }
         */

        /*
         // Override to support editing the table view.
         override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
         if editingStyle == .delete {
         // Delete the row from the data source
         tableView.deleteRows(at: [indexPath], with: .fade)
         } else if editingStyle == .insert {
         // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
         }
         }
         */
}
