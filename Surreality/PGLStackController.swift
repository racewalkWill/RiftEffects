//
//  PGLStackController.swift
//  Glance
//
//  Created by Will on 5/22/19.
//  Copyright © 2019 Will. All rights reserved.
//

import UIKit

class PGLStackController: UITableViewController {
    // tableview of the filters in the stack
    // opens on cell select the masterFilterController to pick new filter
    // on swipe cell "Parms" opens parmController to change filter parms
    // edit order by drag or delete a filter in the edit mode

    var appStack: PGLAppStack!
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let myAppDelegate =  UIApplication.shared.delegate as? AppDelegate
            else { fatalError("AppDelegate not loaded")}

        appStack = myAppDelegate.appStack

        // Uncomment the following line to preserve selection between presentations
         self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        self.navigationItem.rightBarButtonItem = self.editButtonItem

        let myCenter =  NotificationCenter.default
        let queue = OperationQueue.main
        myCenter.addObserver(forName: PGLCurrentFilterChange, object: nil , queue: queue) { [weak self]
            myUpdate in
            guard let self = self else { return } // a released object sometimes receives the notification
                          // the guard is based upon the apple sample app 'Conference-Diffable'
            NSLog("PGLSelectFilterController  notificationBlock PGLCurrentFilterChange")
            self.updateDisplay()

        }

        myCenter.addObserver(forName: PGLStackChange, object: nil , queue: queue) { [weak self]
            myUpdate in
            //            NSLog("PGLImageController  notificationBlock PGLStackChange")
            guard let self = self else { return } // a released object sometimes receives the notification
                          // the guard is based upon the apple sample app 'Conference-Diffable'
            self.appStack = myAppDelegate.appStack
            self.updateDisplay()
        }

          configureNavigationItem()

    }

    // MARK: appear/disappear
    override func viewDidDisappear(_ animated: Bool) {
        super .viewDidDisappear(animated)
        NSLog("PGLSelectFilterController #viewDidDisappear removing notification observor")

        NotificationCenter.default.removeObserver(self, name: PGLCurrentFilterChange, object: self)
        NotificationCenter.default.removeObserver(self, name: PGLStackChange, object: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        NSLog("PGLStackController viewDidAppear")
        appStack.resetViewStack()
    }

    fileprivate func updateDisplay() {
        // called by the action buttons

//        updateFilterLabel()
        // select category & filter buttons for the next page
//        updateSelectedButtons()
        // refresh view
//        postCurrentFilterChange()
        appStack.resetCellFilters() // updates the flattened cell filter array
        tableView.reloadData()



    }

    // MARK: - Table view delegate
    override func indexPathForPreferredFocusedView(in tableView: UITableView) -> IndexPath? {
        let targetRow = appStack.activeFilterCellRow()
        return IndexPath(row: targetRow, section: 0)
    }
    
    // MARK: Table Setup
    override func numberOfSections(in tableView: UITableView) -> Int {
        //  return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //  return the number of rows
        let rowCount = appStack.stackRowCount()
        return rowCount
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "filterRowCell", for: indexPath)
        let aFilterIndent = appStack.filterAt(indexPath: indexPath)
          cell.imageView?.image = aFilterIndent.filter.getThumbnail()

        cell.textLabel?.text = aFilterIndent.descriptorDisplayName  // same text as the filterController cell
        cell.indentationLevel = aFilterIndent.level
        // Configure the cell...
        if appStack.isImageControllerOpen {
            // disable the detail disclosure button until the image controller shows
            // other controllers in the detail are the PGLAssetGridController and the PGLAssetController
            // these select an image or imageList for image parms
//            cell.accessoryType = .detailDisclosureButton
        } else { cell.accessoryType = .none}

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        // go to Parms of the filter

        let cellIndent = appStack.cellFilters[indexPath.row]
        appStack.moveTo(filterIndent: cellIndent)
            // sets the appStack viewerStack and the current filter of the viewerStac,


    
    }


    @IBAction func addFilter(_ sender: UIBarButtonItem) {
        // hideParmControls()

       appStack.outputFilterStack().addFilterAfter()
        // puts new filter after current stack filter

        postFilterNavigationChange()
        performSegue(withIdentifier: "showFilterController", sender: self)
            // chooses new filter
    }

    fileprivate func postFilterNavigationChange() {
        let updateFilterNotification = Notification(name:PGLCurrentFilterChange)
        NotificationCenter.default.post(updateFilterNotification)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // can check  if segue.identifier == "showCollection" and
        // segue.destination as? PGLImageCollectionMasterController ...
        // but currently only one segue so just set the model object for the cell
        if segue.identifier == "showParmSettings" {
            // didSelectRowAt has set the appStack model
            return //
        }
        if let cellDetail = sender as? UITableViewCell {

            if let thePath = tableView.indexPath(for: cellDetail) {
                let cellObject = appStack.cellFilters[thePath.row]
                appStack.moveTo(filterIndent: cellObject)
            }

        }

    }

    // MARK: Swipe Actions

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // on swipe from the filter list open the parm controller
          var contextActions = [UIContextualAction]()

//        case .segue:
        var myAction = UIContextualAction(style: .normal, title: "Change") { [weak self] (_, _, completion) in
            guard let self = self
                else { return  }

            self.appStack.viewerStack.activeFilterIndex = indexPath.row
            NSLog("PGLStackController trailingSwipeActionsConfigurationForRowAt Change ")
            // set appStack and stack indexes to the selected filter
            let cellObject = self.appStack.cellFilters[indexPath.row]
            self.appStack.moveTo(filterIndent: cellObject)

            self.performSegue(withIdentifier: "showFilterController" , sender: nil)
                  // show segue showFilterController opens the PGLFilterTableController
                  // set the stack activeFilter


            completion(true)
        }
         contextActions.append(myAction)

        // delete filter
         myAction = UIContextualAction(style: .normal, title: "Delete") { [weak self] (_, _, completion) in
                    guard let self = self
                        else { return  }
                    NSLog("PGLStackController trailingSwipeActionsConfigurationForRowAt Delete")
                    self.removeFilter(indexPath: indexPath)

                    completion(true)
                }
         contextActions.append(myAction)

         return UISwipeActionsConfiguration(actions: contextActions)
    }

    func removeFilter(indexPath: IndexPath) {
        let thisStack = appStack.getViewerStack()
        thisStack.activeFilterIndex = indexPath.row

       thisStack.removeFilter(position: indexPath.row)
       self.updateDisplay()
        // other updates in PGLImageController
    //            updateNavigationBar()
//                postCurrentFilterChange()
//                postStackChange()

    }

    //

    // MARK: editing support

         override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
             return true
         }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
//            if let identifierToDelete = itemIdentifier(for: indexPath) {
//                var snapshot = self.snapshot()
//                snapshot.deleteItems([identifierToDelete])
//                apply(snapshot)
            }
        }
    // MARK: reordering support

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        // delete row at sourceIndexPath
        // insert row at destination
        // if moving up the stack then inserts before the existing destination
        // if moving down the stack then inserts after the existing destination
        let viewerStack = appStack.getViewerStack()
        let startingPoint = sourceIndexPath.row
        let endingPoint = destinationIndexPath.row

        if let startingPointFilter = viewerStack.removeFilter(position: startingPoint) {
            viewerStack.activeFilterIndex = endingPoint
            if startingPoint < endingPoint {
                viewerStack.addFilterAfter(newFilter: startingPointFilter)
            } else {
                viewerStack.addFilterBefore(newFilter: startingPointFilter)
            }
        }

       

    }


    func configureNavigationItem() {
//        navigationItem.title = "UITableView: Editing"
        let editingItem = UIBarButtonItem(title: tableView.isEditing ? "Done" : "Edit", style: .plain, target: self, action: #selector(toggleEditing))
        navigationItem.rightBarButtonItems = [editingItem]
    }

    @objc
    func toggleEditing() {
        tableView.setEditing(!tableView.isEditing, animated: true)
        configureNavigationItem()
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
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
