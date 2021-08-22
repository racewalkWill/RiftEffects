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

class PGLOpenStackViewController: UIViewController , UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate, UINavigationControllerDelegate {


    // this is the current controller to open stacks 7/15/20
    // See PGLImageController openStackActionBtn caller
    // PGLOpenStackViewController is a UITableView form working as the UITableViewDelegate


    static let tableViewCellIdentifier = "stackCell"
    private static let nibName = "StackCell"

    lazy var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult> = setFetchController()
    lazy var moContext: NSManagedObjectContext = PersistentContainer.viewContext

    lazy var fetchedStacks = fetchedResultsController.fetchedObjects?.map({ ($0 as! CDFilterStack ) })


    let filterOpenTitle = "Open Filter Stack"
     let dateFormatter = DateFormatter()



    // diffableDataSource
    var dataSource: DataSource!
    var tableView: UITableView!

     // assigned in configureHierarchy of viewDidLoad
    let searchBar = UISearchBar(frame: .zero)


    // MARK: View LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()

        do { try fetchedResultsController.performFetch() }
        catch { Logger(subsystem: LogSubsystem, category: LogCategory).fault ( "PGLOpenStackViewController viewDidLoad fatalError( #viewDidLoad performFetch() error = \(error.localizedDescription)") }
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
//         NSLog("PGLOpenStackViewControler viewDidLoad completed")

    }

    override func viewDidDisappear(_ animated: Bool) {
//          NSLog("PGLOpenStackViewControler viewDidDisappear set dataSource to nil")
        dataSource = nil

    }

    override func viewWillAppear(_ animated: Bool) {
        if dataSource == nil {
//             NSLog("PGLOpenStackViewControler viewWillAppear dataSource = nil ")
            configureDataSource()
        }
    }

    func setFetchController() -> NSFetchedResultsController<NSFetchRequestResult> {
            let myMOContext = moContext
            let stackRequest = NSFetchRequest<CDFilterStack>(entityName: "CDFilterStack")
            stackRequest.predicate = NSPredicate(format: "outputToParm = null")
            stackRequest.fetchBatchSize = 15  // usually 12 rows visible -
                // breaks up the full object fetch into view sized chunks

                // only CDFilterStacks with outputToParm = null.. ie it is not a child stack)
            var sortArray = [NSSortDescriptor]()
            sortArray.append(NSSortDescriptor(key: "type", ascending: true))
            sortArray.append(NSSortDescriptor(key: "created", ascending: false))


            stackRequest.sortDescriptors = sortArray

        fetchedResultsController = NSFetchedResultsController(fetchRequest: stackRequest, managedObjectContext: myMOContext, sectionNameKeyPath:"type" , cacheName: "StackType" ) as! NSFetchedResultsController<NSFetchRequestResult>
                // or cacheName = "GlanceStackCache" "StackType"

           fetchedResultsController.delegate = self
        // set delegate if change notifications are needed for insert, delete, etc in the manageobjects
            return fetchedResultsController


    }

    // MARK: NSFetchedResultsControllerDelegate


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
        // #warning Incomplete implementation, return the number of rows
//        guard let sections = self.fetchedResultsController.sections else {
//            fatalError("No sections in fetchedResultsController")
//        }
//        let sectionInfo = sections[section]
//        return sectionInfo.numberOfObjects
    }


//      func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        NSLog("PGLOpenStackViewController cellForRowAt \(indexPath)")
//        let cell = dataSource.tableView(tableView, cellForRowAt: indexPath)
        // passes to the dataSource implementation

//        let cell = tableView.dequeueReusableCell(withIdentifier: "stackCell", for: indexPath)
//        if let object = (self.fetchedResultsController.object(at: indexPath)) as? CDFilterStack {
//
//        cell.textLabel?.text  = object.title
//        cell.detailTextLabel?.text = detailTextString(ofObject: object)
//
//          if let cellThumbnail = object.thumbnail
//          {  cell.imageView?.image = UIImage(data: cellThumbnail) }
//            else { return cell}
//        // Configure the cell with data from the managed object.
//        } else { cell.textLabel?.text = "stack read error"}
//
//
//     return cell
//     }

    func detailTextString(ofObject: CDFilterStack) -> String {
        var dateString: String
       if let modifiedDate =  ofObject.modified {
            dateString = dateFormatter.string(from: modifiedDate)
       }
       else { dateString =  dateFormatter.string(from: ofObject.created!)}
       let detailText = ofObject.type! + " " + dateString
        return detailText
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
                for aRowPath in tableView.indexPathsForSelectedRows! {

                    let theFetchedObject  = fetchedResultsController.object(at: aRowPath)
                   if let theId: NSManagedObject = theFetchedObject as? NSManagedObject? ?? nil
                    { deleteIds.append(theId.objectID) }

                    // mark for batch delete

                }
                let batchDelete = NSBatchDeleteRequest(objectIDs: deleteIds)
                batchDelete.resultType = .resultTypeObjectIDs
                do {
                    let batchDeleteResult = try moContext.execute(batchDelete) as? NSBatchDeleteResult

                    if let deletedObjectIDs = batchDeleteResult?.result as? [NSManagedObjectID] {
                        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: [NSDeletedObjectsKey: deletedObjectIDs],
                        into: [moContext])
                    }
                } catch {
                    print("Error: \(error)\nCould not batch delete existing records.")
                    return
                }


            }
        }
        tableView.setEditing(!tableView.isEditing, animated: true)
           searchBar.isHidden = tableView.isEditing // no search bar when editing

           configureNavigationItem()
       }

     func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        Logger(subsystem: LogSubsystem, category: LogCategory).debug("PGLOpenStackViewController didSelectRowAt \(indexPath)")
        dataSource.tableView(tableView, didSelectRowAt: indexPath)
//        dismiss(animated: true, completion: nil )
        // let user touch outside of the controller to dismiss
        // selected stack is loaded into the image controller behind the openStackViewController
        // ie. a little preview..
    }



     // Override to support editing the table view.
     func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        dataSource.tableView(tableView, commit: editingStyle, forRowAt: indexPath)
        // dataSource deletes from the UITableViewDiffableDataSource
        if editingStyle == .delete {

     // Now Delete the row from the database

        if let deleteStack = (self.fetchedResultsController.object(at: indexPath)) as? CDFilterStack {
            moContext.delete(deleteStack)
           do { try moContext.save() }
           catch{ Logger(subsystem: LogSubsystem, category: LogCategory).error ("PGLOpenStackViewController tableView commit fatalError(moContext save error \(error.localizedDescription)")


           }
//            moContext.processPendingChanges()
            // refresh the view
//            do { try fetchedResultsController.performFetch() }
//            catch{ fatalError("fetchedResults error \(error)")}
//            tableView.reloadData()
        }
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
     }

    class DataSource: UITableViewDiffableDataSource<Int, CDFilterStack> {

        lazy var sourceMoContext: NSManagedObjectContext = PersistentContainer.viewContext
        var showHeaderText = true

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

        func delete(cdStack: CDFilterStack) {
            sourceMoContext.delete(cdStack)
            do { try sourceMoContext.save() }
            catch{
                Logger(subsystem: LogSubsystem, category: LogCategory).error("PGLOpenStackViewController delete cdStack fatalError(sourceMoContext save error \(error.localizedDescription)")}
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
                }
            }
        }

        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            // start with saved stack... later have it insert on the selected parm as new input
//            NSLog("DataSource didSelectRowAt \(indexPath)")

            if tableView.isEditing == false {
                // pick and show this row
                if let object = itemIdentifier(for: indexPath) {

                    if let theAppStack = (UIApplication.shared.delegate as? AppDelegate)!.appStack {

                        let userPickedStack = PGLFilterStack.init()
                        userPickedStack.on(cdStack: object)
                        theAppStack.resetToTopStack(newStack: userPickedStack)

                        postStackChange()
                    }
                }
            } // not editing mode
            else {
                let theRows = tableView.indexPathsForSelectedRows
            }

        }

        func postStackChange() {

            let stackNotification = Notification(name:PGLLoadedDataStack)
            NotificationCenter.default.post(stackNotification)
            let filterNotification = Notification(name: PGLCurrentFilterChange) // turns on the filter cell detailDisclosure button even on cancels
            NotificationCenter.default.post(filterNotification)
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


        if let sections = fetchedResultsController.sections {
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
            if let matchingStacks = fetchedStacks?.filter({
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

      



}
