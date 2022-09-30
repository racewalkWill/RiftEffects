//
//  PGLFilterTableController.swift
//  Glance
//
//  Created by Will on 5/26/19.
//  Copyright © 2019 Will Loew-Blosser. All rights reserved.
//  TableView implementation of PGLSelectFilterController

import UIKit
import os

enum FilterChangeMode{
    case replace
    case add
}

let ABCSymbol = UIImage(systemName: "textformat.abc")
let GroupSymbol = UIImage(systemName: "rectangle.grid.1x2")

class PGLFilterTableController: UITableViewController,  UINavigationControllerDelegate, UISplitViewControllerDelegate, UIPopoverPresentationControllerDelegate {
        //UIDragInteractionDelegate, UIDropInteractionDelegate

    //MARK: - Properties
    var stackData: () -> PGLFilterStack?  = { PGLFilterStack() } // a function is assigned to this var that answers the filterStack

    var appStack: PGLAppStack!

    var categories = PGLFilterCategory.allFilterCategories()

    var filters = PGLFilterCategory.filterDescriptors

    var matchFilters = [PGLFilterDescriptor]()

    var notifications: [NSNotification.Name : Any] = [:] // an opaque type is returned from addObservor

    let frequentCategoryPath = IndexPath(row:0,section: 0)

    var longPressGesture: UILongPressGestureRecognizer!
    var longPressStart: IndexPath?

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


//        Logger(subsystem: LogSubsystem, category: LogNavigation).info("\( String(describing: self) + "-" + #function)")
        let nib = UINib(nibName: PGLFilterTableController.nibName, bundle: nil)

        // Required if our subclasses are to use `dequeueReusableCellWithIdentifier(_:forIndexPath:)`.
        tableView.register(nib, forCellReuseIdentifier: PGLFilterTableController.tableViewCellIdentifier)
        
        clearsSelectionOnViewWillAppear = false // keep the selection

        splitViewController?.delegate = self
        guard let myAppDelegate =  UIApplication.shared.delegate as? AppDelegate
            else { Logger(subsystem: LogSubsystem, category: LogCategory).fault ("PGLFilterTableController viewDidLoad fatalError AppDelegate not loaded")
                return
        }
        appStack = myAppDelegate.appStack
        stackData = { self.appStack.viewerStack }
        // closure is evaluated when referenced
        //            updateSelectedButtons()
        navigationItem.title = "Filters" //thisStack.stackName
        
        tableView.register(UITableViewHeaderFooterView.self,
                           forHeaderFooterViewReuseIdentifier: "HeaderRenderer")
        let myCenter =  NotificationCenter.default
        let queue = OperationQueue.main
      let aNotification =  myCenter.addObserver(forName: PGLLoadedDataStack, object: nil , queue: queue) {[weak self]
            myUpdate in
           Logger(subsystem: LogSubsystem, category: LogNavigation).info("PGLFilterTableController  notificationBlock PGLLoadedDataStack")
            guard let self = self else { return } // a released object sometimes receives the notification
                          // the guard is based upon the apple sample app 'Conference-Diffable'
            self.navigationController?.popViewController(animated: true)

        }
        notifications[PGLLoadedDataStack] = aNotification

 
    }


override func viewDidDisappear(_ animated: Bool) {
    super .viewDidDisappear(animated)
    Logger(subsystem: LogSubsystem, category: LogCategory).debug("PGLFilterTableController #viewDidDisappear removing notification observor")

    for (name , observer) in  notifications {
                   NotificationCenter.default.removeObserver(observer, name: name, object: nil)

               }
    notifications = [:] // reset
}

// MARK: SplitView
func targetDisplayModeForAction(in svc: UISplitViewController) -> UISplitViewController.DisplayMode {
    if svc.displayMode == UISplitViewController.DisplayMode.secondaryOnly {
        // don't let parms list overlay the picture...
        Logger(subsystem: LogSubsystem, category: LogCategory).info("PGLSelectFilterController #targetDisplayModeForAction answers allVisible ")
        return UISplitViewController.DisplayMode.oneBesideSecondary
    }
    else { Logger(subsystem: LogSubsystem, category: LogCategory).info("PGLSelectFilterController #targetDisplayModeForAction answers automatic ")
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
            Logger(subsystem: LogSubsystem, category: LogCategory).debug("PGLFilterTableController numberOfRowsInSection count = \(self.filters.count)")
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
        Logger(subsystem: LogSubsystem, category: LogCategory).info("PGLFilterTableController performFilterPick ")
        if let selectedFilter = descriptor.pglSourceFilter() {
            stackData()?.performFilterPick(selectedFilter: selectedFilter)
                // depending on mode will replace or add to the stack

            Logger(subsystem: LogSubsystem, category: LogCategory).notice("filter set = \(String(describing: selectedFilter.filterName))")

            // post notification that filter is changed. The parmSettings manager should listen

            updateFilterLabel()
            postImageChange()
            postCurrentFilterChange()
            appStack.resetCellFilters()
//            selectedFilter(addChild: appStack,)
                // tell the appStack to do the addChildSequence with this filter
            // use super class empty method
            // only implement on the PGLSequence Filter

            let replaceFilterEvent = Notification(name: PGLReplaceFilterEvent)
             NotificationCenter.default.post(replaceFilterEvent)

        }
    }

   override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
    if let theCell =  sender as? UITableViewCell {
        return theCell.isSelected
            // if the cell is not selected then don't go to parms..
            // this means there is no current filter
    } else
        { return false }
    }


    func updateFilterLabel()  {
        // some overlap with the configureCell...
        if stackData() != nil {
        _ = stackData()!
//        filterNumberLabel.text = thisStack.filterNumLabel()

//        categoryPicked = stackData()?.currentFilterPosition().categoryIndex ?? 0
//        filterPicked = stackData()?.currentFilterPosition().filterIndex ?? 0


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


    // MARK: - LongPressGestures
    func setLongPressGesture() {

        longPressGesture = UILongPressGestureRecognizer(target: self , action: #selector(PGLFilterTableController.longPressAction(_:)))
          if longPressGesture != nil {

//                 " defaults to 0.5 sec 1 finger 10 points allowed movement"
              tableView.addGestureRecognizer(longPressGesture!)
              longPressGesture!.isEnabled = true
//            Logger(subsystem: LogSubsystem, category: LogCategory).notice("PGLFilterTableController setLongPressGesture \(String(describing: self.longPressGesture))")
          }
      }

    func removeGestureRecogniziers(targetView: UIView) {
       // not called in viewWillDissappear..
       // recognizier does not seem to get restored if removed...
        if longPressGesture != nil {
            tableView.removeGestureRecognizer(longPressGesture!)
            longPressGesture!.removeTarget(self, action: #selector(PGLFilterTableController.longPressAction(_:)))
            longPressGesture = nil
//           NSLog("PGLFilterTableController removeGestureRecogniziers ")
       }

    }

    @objc func longPressAction(_ sender: UILongPressGestureRecognizer) {

        let point = sender.location(in: tableView)

        if sender.state == .began
        {
            Logger(subsystem: LogSubsystem, category: LogCategory).debug("PGLFilterTableController longPressAction begin")
            guard let longPressIndexPath = tableView.indexPathForRow(at: point) else {
                longPressStart = nil // assign to var
                return
            }
            longPressStart = longPressIndexPath // assign to var
        }
        if sender.state == .recognized {  // could also use .ended but there is slight delay
            // open popup with filter userDescription
            if longPressStart != nil {
                var descriptor: PGLFilterDescriptor

                guard let tableCell = tableView.cellForRow(at: longPressStart!) else { return  }
                switch mode {
                    case .Grouped:
                        descriptor = categories[longPressStart!.section].filterDescriptors[longPressStart!.row]
                    case .Flat:
                        descriptor = filters[longPressStart!.row]
                }

                popUpFilterDescription(filterName: descriptor.displayName, filterText: descriptor.userDescription, filterCell: tableCell)
            }
        }



    }

    func popUpFilterDescription(filterName: String, filterText: String, filterCell: UITableViewCell) {
        guard let helpController = storyboard?.instantiateViewController(withIdentifier: "PGLPopUpFilterInfo") as? PGLPopUpFilterInfo
        else {
            return
        }
        helpController.modalPresentationStyle = .popover
       helpController.preferredContentSize = CGSize(width: 200, height: 350.0)
        // specify anchor point?
        guard let popOverPresenter = helpController.popoverPresentationController
        else { return }
        popOverPresenter.sourceView = filterCell
        let sheet = popOverPresenter.adaptiveSheetPresentationController //adaptiveSheetPresentationController
        sheet.detents = [.medium(), .large()]
//        sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        sheet.prefersEdgeAttachedInCompactHeight = true
        sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true

        helpController.textInfo =  filterText
        helpController.filterName = filterName

        present(helpController, animated: true )

    }


// MARK: Notification
 func postImageChange() {
//    let updateFilterNotification = Notification(name:PGLOutputImageChange)
//    NotificationCenter.default.post(updateFilterNotification)
}

 func postCurrentFilterChange() {
    let updateFilterNotification = Notification(name:PGLCurrentFilterChange)

     NotificationCenter.default.post(name: updateFilterNotification.name, object: nil, userInfo: ["sender" : self as AnyObject])
}

    // MARK: unwind segue code. Triggered from PGLSelectParm
    @IBAction func goToChildStack(segue: UIStoryboardSegue) {
        Logger(subsystem: LogSubsystem, category: LogCategory).notice("PGLParmsFilterTabsController goToChildStack segue")

    }

    @IBAction func goToParentFilterStack(segue: UIStoryboardSegue) {
        Logger(subsystem: LogSubsystem, category: LogCategory).notice("PGLParmsFilterTabsController goToParentFilterStack segue")

    }


}



