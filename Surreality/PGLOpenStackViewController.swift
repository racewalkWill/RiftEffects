//
//  PGLOpenStackViewController.swift
//  Glance
//
//  Created by Will on 12/13/18.
//  Copyright © 2018 Will. All rights reserved.
//

import UIKit
import CoreData

class PGLOpenStackViewController: UIViewController , UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate, UINavigationControllerDelegate {


    // this is the current controller to open stacks 7/15/20
    // See PGLImageController openStackActionBtn which can open
    // either PGLSelectStackController or PGLOpenStackViewController
    // PGLOpenStackViewController is the UITableViewController version
    // PGLSelectStackController is the CollectionView version

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
        catch { fatalError("PGLOpenStackViewController #viewDidLoad performFetch() error = \(error)") }
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
         NSLog("PGLOpenStackViewControler viewDidLoad completed")

    }

    override func viewDidDisappear(_ animated: Bool) {
          NSLog("PGLOpenStackViewControler viewDidDisappear set dataSource to nil")
        dataSource = nil

    }

    override func viewWillAppear(_ animated: Bool) {
        if dataSource == nil {
             NSLog("PGLOpenStackViewControler viewWillAppear dataSource = nil ")
            configureDataSource()
        }
    }

    func setFetchController() -> NSFetchedResultsController<NSFetchRequestResult> {
            let myMOContext = moContext
            let stackRequest = NSFetchRequest<CDFilterStack>(entityName: "CDFilterStack")
            stackRequest.predicate = NSPredicate(format: "inputToFilter = null")

                // only CDFilterStacks with outputToParm = null.. ie it is not a child stack)
            var sortArray = [NSSortDescriptor]()

            sortArray.append(NSSortDescriptor(key: "title", ascending: true))
    //        sortArray.append(NSSortDescriptor(key: "type", ascending: true))

            stackRequest.sortDescriptors = sortArray

        fetchedResultsController = NSFetchedResultsController(fetchRequest: stackRequest, managedObjectContext: myMOContext, sectionNameKeyPath: "title", cacheName: nil ) as! NSFetchedResultsController<NSFetchRequestResult>
                // or cacheName = "GlanceStackCache"

           fetchedResultsController.delegate = self
        // set delegate if change notifications are needed for insert, delete, etc in the manageobjects
            return fetchedResultsController


    }

    // MARK: toolbar

    @IBAction func typeFilterBtn(_ sender: UIBarButtonItem) {
        // open picker view for stack type filter choices
//        let userStackTypes = AppUserDefaults.array(forKey: StackTypeKey)
        NSLog("PGLOpenStackViewController typeFilterBtn action")
        sortData(by: SortStacks.StackType)

    }

    @IBAction func sortAscendngBtn(_ sender: UIBarButtonItem) {
        NSLog("PGLOpenStackViewController sortAscendngBtn action")
        sortData(by: SortStacks.AscendingTitle)
    }

    @IBAction func sortDescendingBtn(_ sender: UIBarButtonItem) {
         NSLog("PGLOpenStackViewController sortDescendingBtn action")
        sortData(by: SortStacks.DescendingTitle)
    }

    @IBAction func sortDateCreated(_ sender: UIBarButtonItem) {
        NSLog("PGLOpenStackViewController sortDateCreated action")
        sortData(by: SortStacks.ModifiedDate)
            // uses the created date if modified date not defined
    }

    // MARK: - Table view data source

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {     NSLog("PGLOpenStackViewController cellForRowAt \(indexPath)")
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
               let editingItem = UIBarButtonItem(title: tableView.isEditing ? "Done" : "Edit", style: .plain, target: self, action: #selector(toggleEditing))
               navigationItem.rightBarButtonItems = [editingItem]

//             navigationController?.setToolbarHidden(false, animated: false)
           }

    @objc func toggleEditing() {
               tableView.setEditing(!tableView.isEditing, animated: true)
               searchBar.isHidden = tableView.isEditing // no search bar when editing

               configureNavigationItem()
           }

     func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        NSLog("PGLOpenStackViewController didSelectRowAt \(indexPath)")
        dataSource.tableView(tableView, didSelectRowAt: indexPath)
        dismiss(animated: true, completion: nil )
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
           catch{ fatalError("moContext save error \(error)")}
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

        // MARK: editing support

        func delete(cdStack: CDFilterStack) {
            sourceMoContext.delete(cdStack)
            do { try sourceMoContext.save() }
            catch{ fatalError("sourceMoContext save error \(error)")}
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
            NSLog("DataSource didSelectRowAt \(indexPath)")
            if let object = itemIdentifier(for: indexPath) {

                if let theAppStack = (UIApplication.shared.delegate as? AppDelegate)!.appStack {

                    let storedPGLStack = PGLFilterStack(readName: object.title!)
                    theAppStack.resetToTopStack(newStack: storedPGLStack)
                    postStackChange()
                }

            }

        }

        func postStackChange() {

            let stackNotification = Notification(name:PGLStackChange)
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
                fatalError("failed to create a new cell")
            }
            return cell
        }
    }

    func initialSnapShot() -> NSDiffableDataSourceSnapshot<Int, CDFilterStack> {

        var snapshot = NSDiffableDataSourceSnapshot<Int, CDFilterStack>()
        snapshot.appendSections([0])

        if let stacks = fetchedStacks
          { NSLog("PGLOpenStackViewController #initialSnapShot count = \(stacks.count)")
            snapshot.appendItems(stacks) }
        else { snapshot.appendItems([CDFilterStack]())
             // show empty snapshot
             }
        return snapshot
//        if let fetchedStacks = fetchedResultsController.fetchedObjects?.map({ ($0 as! CDFilterStack ) })
//        {
//            snapshot.appendItems(fetchedStacks)
//        }
//
//        return snapshot
    }
}


    extension PGLOpenStackViewController: UISearchBarDelegate {
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            if searchText.count == 0 {
               let allStacks =  initialSnapShot()
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
                dataSource.apply(snapshot, animatingDifferences: true)
                }
        }

        enum SortStacks {
            case AscendingTitle
            case DescendingTitle
            case StackType
            case CreatedDate
            case ModifiedDate

        }

        func sortData(by: SortStacks) {
            var newSortItems =  [CDFilterStack]()
            NSLog("PGLOpenStackViewControler #sortData start")
            var updatedSnapshot = dataSource.snapshot()
            updatedSnapshot.sectionIdentifiers.forEach {
                let section = $0
                NSLog("PGLOpenStackViewControler #sortData section = \(section)")
                let items = updatedSnapshot.itemIdentifiers(inSection: section)
                switch by {
                    case .AscendingTitle:
                        newSortItems = items.sorted {
                            $0.title! < $1.title!
                        }
                    case .DescendingTitle:
                        newSortItems = items.sorted {
                                                   $0.title! > $1.title!
                                               }
                    case .StackType:
                        newSortItems = items.sorted {
                            $0.type! > $1.type!
                        }
                    case .ModifiedDate:
                        newSortItems = items.sorted {
                            ($0.modified ?? $0.created!) > ($1.modified ?? $1.created!)
                                               }
                    case .CreatedDate:
                        newSortItems = items.sorted {
                            $0.created! > $1.created!
                        }



                }
                updatedSnapshot.deleteItems(items)
                updatedSnapshot.appendItems(newSortItems, toSection: section)

            }
            dataSource.apply(updatedSnapshot, animatingDifferences: true)
        }

}
