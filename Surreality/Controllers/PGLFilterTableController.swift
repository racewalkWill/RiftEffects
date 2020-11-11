//
//  PGLFilterTableController.swift
//  Glance
//
//  Created by Will on 5/26/19.
//  Copyright © 2019 Will Loew-Blosser. All rights reserved.
//  TableView implementation of PGLSelectFilterController

import UIKit



class PGLFilterTableController: UITableViewController,  UINavigationControllerDelegate, UISplitViewControllerDelegate {
        //UIDragInteractionDelegate, UIDropInteractionDelegate

    //MARK: - Properties
    var stackData: () -> PGLFilterStack?  = { PGLFilterStack() } // a function is assigned to this var that answers the filterStack

    var appStack: PGLAppStack!

    var categories = PGLFilterCategory.allFilterCategories()

    var filters = PGLFilterCategory.filterDescriptors

    var matchFilters = [PGLFilterDescriptor]()

    let frequentCategoryPath = IndexPath(row:0,section: 0)

    // MARK: - Constants
    static let tableViewCellIdentifier = "cellID"
    private static let nibName = "TableCell"

    // MARK: Filter Navigator Modes

    enum FilterNavigatorMode: String
    {
        case Grouped
        case Flat
    }

    var mode: FilterNavigatorMode = .Grouped  // default flat
    {
        didSet
        {
            tableView.reloadData()
        }
    }

    // MARK: View Load/unload
    override func viewDidLoad() {
        super.viewDidLoad()
        let nib = UINib(nibName: PGLFilterTableController.nibName, bundle: nil)

        // Required if our subclasses are to use `dequeueReusableCellWithIdentifier(_:forIndexPath:)`.
        tableView.register(nib, forCellReuseIdentifier: PGLFilterTableController.tableViewCellIdentifier)
        
        clearsSelectionOnViewWillAppear = false // keep the selection

        splitViewController?.delegate = self
        guard let myAppDelegate =  UIApplication.shared.delegate as? AppDelegate
            else { fatalError("AppDelegate not loaded")}
        appStack = myAppDelegate.appStack
        stackData = { self.appStack.viewerStack }
        // closure is evaluated when referenced
        //            updateSelectedButtons()

    tableView.register(UITableViewHeaderFooterView.self,
                           forHeaderFooterViewReuseIdentifier: "HeaderRenderer")
 
    }


override func viewDidDisappear(_ animated: Bool) {
    super .viewDidDisappear(animated)
    NSLog("PGLFilterTableController #viewDidDisappear removing notification observor")

//    NotificationCenter.default.removeObserver(self, name: PGLCurrentFilterChange, object: self)
//    NotificationCenter.default.removeObserver(self, name: PGLStackChange, object: self)
}

// MARK: SplitView
func targetDisplayModeForAction(in svc: UISplitViewController) -> UISplitViewController.DisplayMode {
    if svc.displayMode == UISplitViewController.DisplayMode.secondaryOnly {
        // don't let parms list overlay the picture...
        NSLog("PGLSelectFilterController #targetDisplayModeForAction answers allVisible ")
        return UISplitViewController.DisplayMode.oneBesideSecondary }
    else { NSLog("PGLSelectFilterController #targetDisplayModeForAction answers automatic ")
        return UISplitViewController.DisplayMode.automatic}
}

  

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // return the number of sections
        switch mode
        {
        case .Grouped:
            return categories.count
        case .Flat:
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // # return the number of rows
        switch mode
        {
        case .Grouped:
            return categories[section].filterDescriptors.count
        case .Flat:
            NSLog("PGLFilterTableController numberOfRowsInSection count = \(filters.count)")
            return filters.count
        }
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        switch mode
        {
        case .Grouped:
            return 40
        case .Flat:
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: "HeaderRenderer")

        switch mode
        {
        case .Grouped:
            cell?.textLabel?.text = categories[section].categoryName

        case .Flat:
            cell?.textLabel?.text = nil
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        NSLog("PGLFilterTableController cellForRowAt indexPath = \(indexPath)")
        let cell = tableView.dequeueReusableCell(withIdentifier: "filterBasic", for: indexPath)

        var descriptor: PGLFilterDescriptor
        switch mode {
            case .Grouped:
                descriptor = categories[indexPath.section].filterDescriptors[indexPath.row]
            case .Flat:
                descriptor = filters[indexPath.row]
        }
         cell.textLabel?.text = descriptor.displayName
        return cell
    }

    func configureCell(_ cell: UITableViewCell, descriptor: PGLFilterDescriptor) {
        // see overlap with the method updateFilterLabel()
        cell.textLabel?.text = descriptor.displayName
//        cell.detailTextLabel?.text =
    }

    func performFilterPick(descriptor: PGLFilterDescriptor) {
        // called by both subclasses from didSelectRow
        NSLog("PGLFilterTableController \(#function) ")
        if let selectedFilter = descriptor.pglSourceFilter() {
            stackData()?.replace(updatedFilter: selectedFilter)

            NSLog("filter set = \(String(describing: selectedFilter.filterName))")

            // post notification that filter is changed. The parmSettings manager should listen

            updateFilterLabel()
            postImageChange()
            postCurrentFilterChange()
            let replaceFilterEvent = Notification(name: PGLReplaceFilterEvent)
             NotificationCenter.default.post(replaceFilterEvent)

        }
    }

    func updateFilterLabel()  {
        // some overlap with the configureCell...
        if stackData() != nil {
        let thisStack = stackData()!
//        filterNumberLabel.text = thisStack.filterNumLabel()

//        categoryPicked = stackData()?.currentFilterPosition().categoryIndex ?? 0
//        filterPicked = stackData()?.currentFilterPosition().filterIndex ?? 0
        navigationItem.title = thisStack.stackName

        }
//        else { filterNumberLabel.text =  "No Filter" }

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

// MARK: Notification
 func postImageChange() {
    let updateFilterNotification = Notification(name:PGLOutputImageChange)
    NotificationCenter.default.post(updateFilterNotification)
}

 func postCurrentFilterChange() {
    let updateFilterNotification = Notification(name:PGLCurrentFilterChange)
    NotificationCenter.default.post(updateFilterNotification)
}

    // MARK: unwind segue code. Triggered from PGLSelectParm
    @IBAction func goToChildStack(segue: UIStoryboardSegue) {
        NSLog("PGLParmsFilterTabsController goToChildStack segue")

    }

    @IBAction func goToParentFilterStack(segue: UIStoryboardSegue) {
        NSLog("PGLParmsFilterTabsController goToParentFilterStack segue")

    }

}

