//
//  PGLOpenStackViewController.swift
//  Glance
//
//  Created by Will on 12/13/18.
//  Copyright © 2018 Will. All rights reserved.
//

import UIKit
import CoreData
import os

let  PGLLoadedDataStack = NSNotification.Name(rawValue: "PGLLoadedDataStack")
let PGLStackHasSavedNotification = NSNotification.Name(rawValue: "PGLStackHasSavedNotification")
let PGLRemoteChange = NSNotification.Name(rawValue: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

class PGLOpenStackViewController: UIViewController , UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate {


    // this is the current controller to open stacks 7/15/20
    // See PGLImageController openStackActionBtn caller
    // PGLOpenStackViewController is a UITableView form working as the UITableViewDelegate


    static let tableViewCellIdentifier = "stackCell"
    private static let nibName = "StackCell"
    var notifications = [Any]() // an opaque type is returned from addObservor

    private lazy var dataProvider: PGLStackProvider = {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
      let provider = PGLStackProvider(with: appDelegate!.dataWrapper.persistentContainer)
//        let provider = appDelegate?.appStack.dataProvider
        provider.setFetchControllerForStackViewContext()
        provider.fetchedResultsController.delegate = self
        return provider
    }()

//    lazy var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult> = setFetchController()
//    lazy var moContext: NSManagedObjectContext = PersistentContainer.viewContext



    let filterOpenTitle = "Library"
     let dateFormatter = DateFormatter()



    // diffableDataSource
    var dataSource: DataSource!
    var tableView: UITableView!

     // assigned in configureHierarchy of viewDidLoad
    let searchBar = UISearchBar(frame: .zero)


    // MARK: View LifeCycle

    override func viewDidLoad() {
        super.viewDidLoad()
        Logger(subsystem: LogSubsystem, category: LogNavigation).info("\( String(describing: self) + "-" + #function)")
        // Do any additional setup after loading the view.

         navigationItem.title = filterOpenTitle
         navigationController?.delegate = self



        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        dateFormatter.locale = Locale.current


        configureHierarchy()
        configureDataSource()
        configureNavigationItem()
        let snapshot = initialSnapShot()
        dataSource.apply(snapshot, animatingDifferences: false)
        dataSource.dataProvider = dataProvider
//         NSLog("PGLOpenStackViewControler viewDidLoad completed")

        let myCenter =  NotificationCenter.default
        let queue = OperationQueue.main
        
        let stackSaveObservor = myCenter.addObserver(forName: PGLStackHasSavedNotification , object: nil , queue: queue) { [weak self ]
            myUpdate in
            guard let self = self else { return}
//             commented out.. this causes a UIDiffableDataSource crash on
//              BUG_IN_CLIENT_OF_DIFFABLE_DATA_SOURCE__IDENTIFIER_ALREADY_EXISTS
            // this is OK after the data context changes
            if let userDataDict = myUpdate.userInfo {
                if let newStackId = userDataDict["stackObjectID"] as? NSManagedObjectID {
                    // read the stack and insert into the data source
                    if let theCDStack = self.dataProvider.persistentContainer.viewContext.object(with: newStackId) as? CDFilterStack {
                        self.dataSource.insertStack(self, theCDStack: theCDStack)

                    }
                }
            }


        }
        notifications.append(stackSaveObservor)


        let updateLibraryObservor = myCenter.addObserver(forName: PGLUpdateLibraryMenu , object: nil , queue: queue) { [weak self ]
            myUpdate in
            guard let self = self else { return}
            Logger(subsystem: LogSubsystem, category: LogNavigation).info("PGLOpenStackViewController  notificationBlock PGLUpdateLibraryMenu")
            let deviceIdom = self.traitCollection.userInterfaceIdiom
                    if deviceIdom == .phone {
                        if self.traitCollection.horizontalSizeClass == .compact {
                            if self.tableView.numberOfRows(inSection: 0) < 1 {
                                    // plain tables without sections just have a zero section
                                    self.dismiss(animated: true, completion: nil)
                                    }
                                }
                        }

         }
        notifications.append(updateLibraryObservor)



        let remoteChangeObservor = myCenter.addObserver(forName: PGLRemoteChange , object: nil , queue: queue) { [weak self ]
        myUpdate in
        guard let self = self else { return}
            Logger(subsystem: LogSubsystem, category: LogNavigation).info("PGLOpenStackViewController  notificationBlock PGLRemoteChange")
        let snapshot = self.initialSnapShot()
        self.dataSource.apply(snapshot, animatingDifferences: false)
     }
        notifications.append(remoteChangeObservor)





        // check for zero rows in compact mode and trigger segue  compactOpenToStackView
        let deviceIdom = traitCollection.userInterfaceIdiom
        if deviceIdom == .phone {
            if let mySplitView = splitViewController as? PGLSplitViewController {
                if !mySplitView.stackProviderHasRows() {
                    // no stacks .. just go to the stackView for a new one.
                    //  init(identifier: NSStoryboardSegue.Identifier,
//                    source sourceController: Any,
//               destination destinationController: Any,
//            performHandler: @escaping () -> Void)

//                    performSegue(withIdentifier: "compactOpenToStackView", sender: self)
//                    performSegue(withIdentifier: "openStackView", sender: self)
//                    mySplitView.show(.supplementary) // should go to the stackView

//                    mySplitView.setViewController(PGLStackController(), for: .compact)
                            // or secondary?

            }
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
//        let snapshot = initialSnapShot()
//        dataSource.apply(snapshot, animatingDifferences: false)
//        dataSource.dataProvider = dataProvider
        tableView.reloadData()
    }
    override func viewWillLayoutSubviews() {
        let deviceIdom = traitCollection.userInterfaceIdiom
        if deviceIdom == .phone {
            navigationItem.leftItemsSupplementBackButton = true
            navigationItem.hidesBackButton = false
//            showsSecondaryOnlyButton = true
            }
        else {
            navigationItem.leftItemsSupplementBackButton = true
        }
    }

//    override func viewWillDisappear(_ animated: Bool) {
//        for anObserver in  notifications {
//            NotificationCenter.default.removeObserver(anObserver)
//        }
//        notifications = [Any]() // reset
//
//    }


    // MARK: - Table view data source

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        Logger(subsystem: LogSubsystem, category: LogCategory).notice("PGLOpenStackViewController cellForRowAt \(indexPath)")
           return dataSource.tableView(tableView, cellForRowAt: indexPath)
       }


//    override func numberOfSections(in tableView: UITableView) -> Int {
//
//            return fetchedResultsController.sections!.count
//
//    }
// MARK: TableView interface
     func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            let rowCount = dataSource.tableView(tableView, numberOfRowsInSection: section)
        return rowCount

    }


    func detailTextString(ofObject: CDFilterStack) -> String {
        var dateString: String
       if let modifiedDate =  ofObject.modified {
            dateString = dateFormatter.string(from: modifiedDate)
       }
       else { guard let createdDate = ofObject.created else
                {  return " "
                    }
            dateString =  dateFormatter.string(from: createdDate )}
        guard let objectType = ofObject.type else
            { return dateString }
       return objectType + " " + dateString
       
    }



    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */

    // MARK: editing
    func configureNavigationItem() {
           navigationItem.title = filterOpenTitle
           let editingItem = UIBarButtonItem(title: tableView.isEditing ? "Delete" : "Edit", style: .plain, target: self, action: #selector(toggleEditing))
           navigationItem.rightBarButtonItems = [editingItem]

//             navigationController?.setToolbarHidden(false, animated: false)
           }

    @objc func toggleEditing() {

        if tableView.isEditing {
            // delete is pressed
            if ( tableView.indexPathsForSelectedRows?.count ?? 0 ) > 0 {
                // rows are selected for deletion
//                self.fetchedResultsController.fetchRequest.resultType = .managedObjectIDResultType
                var deleteIds = [NSManagedObjectID]()
                let rowsToDelete = tableView.indexPathsForSelectedRows!
                for aRowPath in rowsToDelete {

                    let theFetchedObject  = dataProvider.fetchedResultsController.object(at: aRowPath)
                     deleteIds.append(theFetchedObject.objectID)

                    // mark for batch delete

                }
                dataProvider.batchDelete(deleteIds: deleteIds)
                removeDeletedFromSnapshot(deletedRows:rowsToDelete )
            }
        }
        tableView.setEditing(!tableView.isEditing, animated: true)
       searchBar.isHidden = tableView.isEditing // no search bar when editing

       configureNavigationItem()

       }

    func removeDeletedFromSnapshot(deletedRows: [IndexPath]) {

        var diffableIdentifiers = [CDFilterStack]()
        for aRow in deletedRows {
            if let thisIdentifier = dataSource.itemIdentifier(for: aRow) {
                diffableIdentifiers.append(thisIdentifier)
            }
        }
        var currentSnapshot = dataSource.snapshot()
        currentSnapshot.deleteItems(diffableIdentifiers)
        dataSource.apply(currentSnapshot)


    }

     func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        Logger(subsystem: LogSubsystem, category: LogCategory).debug("PGLOpenStackViewController didSelectRowAt \(indexPath)")
         if !tableView.isEditing {
            dataSource.tableView(tableView, didSelectRowAt: indexPath)
                 // dataSource #didSelectRow updates the appStack and loads from coreData
                // do not update if editing rows
         }


         let deviceIdom = traitCollection.userInterfaceIdiom
         if deviceIdom == .phone {
             // test for compact fo
             // keep the prefferred display mode

    //              test for compact format here??
//                  trying to navigate to the stackController...
//                 splitViewController?.setViewController(PGLStackController(), for: .compact)
//                 splitViewController?.show(.secondary)
             // let user touch outside of the controller to dismiss
             // selected stack is loaded into the image controller behind the openStackViewController
             // ie. a little preview..
             dismiss(animated: true, completion: nil )
         }
         else {
             if !tableView.isEditing {
                 self.splitViewController?.preferredDisplayMode = UISplitViewController.DisplayMode.oneBesideSecondary
             }
         }

         }





     // Override to support editing the table view.
     func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        dataSource.tableView(tableView, commit: editingStyle, forRowAt: indexPath)
        // dataSource deletes from the UITableViewDiffableDataSource
        // then deletes from the database

     }

    class DataSource: UITableViewDiffableDataSource<Int, CDFilterStack> {


        var showHeaderText = true
        var dataProvider: PGLStackProvider?

        // MARK: Header
        override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            if showHeaderText {
                let firstSectionItem = itemIdentifier(for: IndexPath(item:0, section: section))
                let thisSectionTitle =  firstSectionItem?.type ?? ""
                return thisSectionTitle
            }
            else { return ""}
        }

        // MARK: editing support
        
        func insertStack(_ myController: PGLOpenStackViewController, theCDStack: CDFilterStack) {
            var currentSnapshot = snapshot()
            var sectionIndex = 0
                // now get the type for the section

            if let matchingSection = currentSnapshot.sectionIdentifier(containingItem: theCDStack)
            { sectionIndex = currentSnapshot.indexOfSection(matchingSection) ?? 0
                currentSnapshot.appendItems([theCDStack], toSection: sectionIndex)
                    // puts into the matching section..

                self.apply(currentSnapshot ,animatingDifferences: true)

            } else {
                    // read it all back in the correct section
//                try? dataProvider?.fetchedResultsController.performFetch()
//                let allStacks =  myController.initialSnapShot()
//                showHeaderText = true
//                    // show header titles
//                apply(allStacks, animatingDifferences: true)
                
            }
        }

        func delete(cdStack: CDFilterStack) {
            dataProvider?.delete(stack: cdStack, shouldSave: true, completionHandler: nil)
            let stackNotification = Notification(name:PGLUpdateLibraryMenu)
            NotificationCenter.default.post(stackNotification)
            
        }

        override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
                   return true
               }

        override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            if editingStyle == .delete {

                if let identifierToDelete = itemIdentifier(for: indexPath) {
                    var snapshot = self.snapshot()
                    snapshot.deleteItems([identifierToDelete])
                    apply(snapshot)
                    delete(cdStack: identifierToDelete) //need to remove from the datastore too
                        // is identifierToDelete a CDFilterStack?
                }
            }
        }

        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            // start with saved stack... later have it insert on the selected parm as new input
//            NSLog("DataSource didSelectRowAt \(indexPath)")

                // pick and show this row
                // even if in edit mode

                if let object = itemIdentifier(for: indexPath) {
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
    } // end internal class DataSource
}


extension PGLOpenStackViewController {
    // MARK: DiffableDataSource
    func configureHierarchy() {
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)
        searchBar.delegate = self
        searchBar.isHidden = false
        searchBar.searchTextField.autocapitalizationType = .none
               // autocapitalizationType = UITextAutocapitalizationType.nonesear

        tableView = UITableView(frame: .zero, style: .plain)
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(tableView)
        tableView.delegate = self
        // or make the dataSource the delegate??
        // the controller needs to pass message to the dataSource otherwise
        let nib = UINib(nibName: PGLOpenStackViewController.nibName, bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: PGLOpenStackViewController.tableViewCellIdentifier)



        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalToSystemSpacingBelow: view.safeAreaLayoutGuide.topAnchor, multiplier: 1.0),
            searchBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            searchBar.heightAnchor.constraint(equalToConstant: 40),

            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 10),
            // (equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50)
                // -50 allow room for the toolbar
        ])


    }
    func configureDataSource() {
        dataSource = DataSource(tableView: tableView) { (tableView, indexPath, cdFilterStack) -> UITableViewCell? in
                // see also configureCell(_ cell: UITableViewCell, withCDFilterStack: CDFilterStack?)


            var cell = tableView.dequeueReusableCell(withIdentifier: "stackCell")
            if cell == nil {
                cell = UITableViewCell(style: .subtitle, reuseIdentifier: "stackCell")
            }
//           NSLog("DataSource cdFilterStack =  \(cdFilterStack)")
            if let cell = cell {
                cell.textLabel?.text  = cdFilterStack.title
                cell.detailTextLabel?.text = self.detailTextString(ofObject: cdFilterStack)

                         if let cellThumbnail = cdFilterStack.thumbnail
                         {  cell.imageView?.image = UIImage(data: cellThumbnail) }
                           else { return cell}
                       // Configure the cell with data from the managed object.
                  return cell
            } else {
                Logger(subsystem: LogSubsystem, category: LogCategory).error("PGLOpenStackViewController configureDataSource fatalError-failed to create a new cell")
            }
            return cell
        }
    }

    func initialSnapShot() -> NSDiffableDataSourceSnapshot<Int, CDFilterStack> {

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
        return snapshot
    }
} // end extension scope

// MARK: NSFetchedResultsControllerDelegate

extension PGLOpenStackViewController: NSFetchedResultsControllerDelegate {
    // see example in RayWenderlich course 'cdt materials' CampgroundManager unit 07 unit testing
    // /Users/willloew/Developer/raywenderlich courses/cdt-materials/07-unit-testing/projects/final
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
      tableView.beginUpdates()
    }

//    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
//            // this causes filterManager to pop the view controller on every data change
//            // comment out 7/23/22
//
//      switch type {
//      case .insert:
////        tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
//
//              self.dataSource.postStackChange()
//      case .delete:
////        tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
//              self.dataSource.postStackChange()
//      default:
//        return
//      }
//    }

    // swiftlint:disable force_unwrapping
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
      switch type {
      case .insert:
//        tableView.insertRows(at: [newIndexPath!], with: .fade)
        guard let myNewStack = anObject as? CDFilterStack
              else { return }
        self.dataSource.insertStack(self, theCDStack: myNewStack)
      case .delete:
//        tableView.deleteRows(at: [indexPath!], with: .fade)
            guard let myDeletedRowPath = indexPath
              else { return}
            removeDeletedFromSnapshot(deletedRows: [myDeletedRowPath])
      case .update:
        guard let thisPath = indexPath
              else { return }
        guard let thisCell = tableView.cellForRow(at: thisPath)
              else { return }
        guard let myCDFilterStack = anObject as? CDFilterStack
              else { return }
        configureCell(thisCell,  withCDFilterStack: myCDFilterStack)
        case .move:
              return
        // a delete then insert
//          guard let myNewStack = anObject as? CDFilterStack
//                else { return }
//          guard let myDeletedRowPath = indexPath
//            else { return}
//          removeDeletedFromSnapshot(deletedRows: [myDeletedRowPath])
//          self.dataSource.insertStack(self, theCDStack: myNewStack)


//         self.dataSource.postStackChange()
              // this triggers popViewController to the filter or parm controllers
      @unknown default:
        return
      }
    }
    // swiftlint:enable force_unwrapping

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
      tableView.endUpdates()
    }

    func configureCell(_ cell: UITableViewCell, withCDFilterStack: CDFilterStack?) {
        // see also configureDataSource()
        if let cdStack = withCDFilterStack {
                // Configure the cell with data from the managed object.
            cell.textLabel?.text  = cdStack.title
            cell.detailTextLabel?.text = self.detailTextString(ofObject: cdStack)

             if let cellThumbnail = cdStack.thumbnail
                {  cell.imageView?.image = UIImage(data: cellThumbnail) }
      }

    }
} // end  extension NSFetchedResultsControllerDelegate

    // MARK: UISearchBarDelegate
extension PGLOpenStackViewController: UISearchBarDelegate {
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            if searchText.count == 0 {
               let allStacks =  initialSnapShot()
                dataSource.showHeaderText = true
                    // show header titles
                dataSource.apply(allStacks, animatingDifferences: true)
            } else {
                performTitleQuery(with: searchText)}
        }

         func performTitleQuery(with titletFilter: String) {
            let lowerCaseFilter = titletFilter.lowercased()
            if let matchingStacks = dataProvider.fetchedStacks?.filter({
                    if let lowerTitle =  $0.title?.lowercased() {
                        return lowerTitle.contains(lowerCaseFilter)
                    } else {return false }
                    })
                {
                var snapshot = NSDiffableDataSourceSnapshot<Int, CDFilterStack>()
                snapshot.appendSections([0])
                snapshot.appendItems(matchingStacks)
                dataSource.showHeaderText = false
                    // single header .. omit header title
                dataSource.apply(snapshot, animatingDifferences: true)
                }
        }
}  // end extension UISearchBarDelegate
