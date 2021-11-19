//
//  PGLStackController.swift
//  Glance
//
//  Created by Will on 5/22/19.
//  Copyright © 2019 Will. All rights reserved.
//

import UIKit
import Photos
import os


class PGLStackController: UITableViewController, UINavigationControllerDelegate {
    // tableview of the filters in the stack
    // opens on cell select the masterFilterController to pick new filter
    // on swipe cell "Parms" opens parmController to change filter parms
    // edit order by drag or delete a filter in the edit mode

    var appStack: PGLAppStack!
    var filterShiftBtn: UIBarButtonItem!
    var filterShiftImage: UIBarButtonItem!
    var upChevronBtn: UIBarButtonItem!
    var downChevronBtn: UIBarButtonItem!
    var toolBarSpacer: UIBarButtonItem!

    var longPressGesture: UILongPressGestureRecognizer!
    var longPressStart: IndexPath?
    var segueStarted = false  // set to true during prepareFor segue

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let myAppDelegate =  UIApplication.shared.delegate as? AppDelegate
            else {
            Logger(subsystem: LogSubsystem, category: LogCategory).fault ("PGLStackController viewDidLoad fatalError(AppDelegate not loaded")
            return
        }

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
            Logger(subsystem: LogSubsystem, category: LogCategory).notice("PGLSelectFilterController  notificationBlock PGLCurrentFilterChange")
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

        myCenter.addObserver(forName: PGLSelectActiveStackRow, object: nil , queue: queue) { [weak self]
            myUpdate in
            Logger(subsystem: LogSubsystem, category: LogCategory).info("PGLImageController  notificationBlock PGLSelectActiveStackRow")
            guard let self = self else { return } // a released object sometimes receives the notification
                          // the guard is based upon the apple sample app 'Conference-Diffable'
            self.selectActiveFilterRow()
        }

          configureNavigationItem()
        navigationController?.isToolbarHidden = false

        addToolBarButtons()
        updateNavigationBar()
        setLongPressGesture()
        if appStack.outputStack.isEmptyStack() {
            let verticalSize = traitCollection.verticalSizeClass
            if verticalSize != .compact {
                self.performSegue(withIdentifier: "showFilterController" , sender: nil) }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        appStack.postSelectActiveStackRow()
    }

    // MARK: appear/disappear
    override func viewDidDisappear(_ animated: Bool) {
        super .viewDidDisappear(animated)
//        NSLog("PGLSelectFilterController #viewDidDisappear removing notification observor")

        NotificationCenter.default.removeObserver(self, name: PGLCurrentFilterChange, object: self)
        NotificationCenter.default.removeObserver(self, name: PGLStackChange, object: self)
        NotificationCenter.default.removeObserver(self, name: PGLSelectActiveStackRow, object: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        Logger(subsystem: LogSubsystem, category: LogCategory).notice("PGLStackController viewDidAppear")
        appStack.resetViewStack()
        segueStarted = false  // reset flag
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
        setShiftBtnState()



    }

    // MARK: ToolBar
    fileprivate func addToolBarButtons() {


        let verticalSize = traitCollection.verticalSizeClass
        if verticalSize != .compact {
            var theButtons = navigationItem.leftBarButtonItems
            theButtons?.removeLast(1)  // removes the openImageController button
            navigationItem.setLeftBarButtonItems(theButtons, animated: false)

        }

        filterShiftBtn = UIBarButtonItem(title: "", style: .plain, target: self , action: #selector(singleFilterOutput))
        filterShiftImage = UIBarButtonItem(title: "", style: .plain, target: self , action: #selector(singleFilterOutput))
        // both use the same selector...

        filterShiftImage.image = UIImage(systemName: "chart.bar.doc.horizontal")
        filterShiftBtn.possibleTitles = [StackDisplayMode.Single.rawValue, StackDisplayMode.All.rawValue ]

        upChevronBtn = UIBarButtonItem(title: "", style: .plain, target: self , action: #selector(upChevronAction))
        upChevronBtn.image = UIImage(systemName:"chevron.up")
        downChevronBtn = UIBarButtonItem(title: "", style: .plain, target: self , action: #selector(downChevronAction))
        downChevronBtn.image = UIImage(systemName:"chevron.down")
        toolBarSpacer = UIBarButtonItem.flexibleSpace()
        setToolbarItems([filterShiftImage, filterShiftBtn,  toolBarSpacer, upChevronBtn, downChevronBtn], animated: true)
        setShiftBtnState()
        setChevronState()
    }

    @objc func singleFilterOutput() {
        appStack.toggleShowFilterImage()
        setShiftBtnState()
        if appStack.showFilterImage { appStack.postSelectActiveStackRow() }
        else { // deselect row

        }
        setChevronState()
//        postCurrentFilterChange()
    }

    func setShiftBtnState() {
        filterShiftBtn.isEnabled = (appStack.flatRowCount() > 1)
        filterShiftImage.isEnabled = filterShiftBtn.isEnabled
        setChevronState()
        if (appStack.showFilterImage) {
            filterShiftBtn.title  = StackDisplayMode.Single.rawValue
        } else {
            filterShiftBtn.title  = StackDisplayMode.All.rawValue
        }

    }

    @objc func upChevronAction(_ sender: UIBarButtonItem) {


            // if on a child stack (indented cell) then outputFilterStack is
            // not set right... how to handle this?
        appStack.moveActiveBack()
        setChevronState()
        postCurrentFilterChange()
        if appStack.showFilterImage {appStack.postSelectActiveStackRow()}

    }

    @objc func downChevronAction(_ sender: UIBarButtonItem) {

        appStack.moveActiveAhead() // changes to child if needed

        setChevronState()
        postCurrentFilterChange()
        if appStack.showFilterImage {appStack.postSelectActiveStackRow()}

    }

    func setChevronState() {
        if !appStack.showFilterImage {
            upChevronBtn.isEnabled = false
            downChevronBtn.isEnabled = false
            return
        }

        let rowCount = appStack.flatRowCount()

        if (rowCount <= 1) {
            // disable both chevrons
            upChevronBtn.isEnabled = false
            downChevronBtn.isEnabled = false
            return
        }
        let theSelectedRow = appStack.activeFilterCellRow()
            switch theSelectedRow {
                case 0 :
                    // on first.. can't go further
                    upChevronBtn.isEnabled = false
                    downChevronBtn.isEnabled = true
                case rowCount - 1 :
                    // on last filter can't go further
                    upChevronBtn.isEnabled = true
                    downChevronBtn.isEnabled = false
                default:
                    // in the middle enable both
                    upChevronBtn.isEnabled = true
                    downChevronBtn.isEnabled = true
            }
    }


    func selectActiveFilterRow() {
        // assumes only one section  section zero
        
        if tableView.numberOfRows(inSection: 0 ) == 0 {
            return
            // empty table.. trashed the stack.. nothing to show..
        }
        let activeRow = appStack.activeFilterCellRow()
        let rowPath = IndexPath(row: activeRow, section: 0)
        if appStack.showFilterImage {

            tableView.selectRow(at: rowPath, animated: true, scrollPosition: .middle)
        } else {
            // deselect - no rows should be selected
            tableView.deselectRow(at: rowPath, animated: true)
            updateDisplay()  // only update to remove row selection !
        }

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
        let rowCount = appStack.flatRowCount()
        return rowCount
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "filterRowCell", for: indexPath)
        let aFilterIndent = appStack.filterAt(indexPath: indexPath)



        cell.textLabel?.text = aFilterIndent.descriptorDisplayName  // same text as the filterController cell
        cell.indentationLevel = aFilterIndent.level

        switch aFilterIndent.level {
            case 0:
                cell.imageView?.image = PGLFilterAttribute.TopStackSymbol
            default:
                cell.imageView?.image = PGLFilterAttribute.ChildStackSymbol
            }



        if aFilterIndent.stack === appStack.viewerStack {
            if appStack.showFilterImage {
                // single filter mode
                cell.imageView?.image = PGLFilterAttribute.CurrentStackSymbol
            }
        }

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
// MARK: Bar Buttons

    func isLimitedPhotoLibAccess() -> Bool {
        let accessLevel: PHAccessLevel = .readWrite // or .addOnly
        let authorizationStatus = PHPhotoLibrary.authorizationStatus(for: accessLevel)

        switch authorizationStatus {
            case .limited :
            return true
        default:
            // all other authorizationStatus values
           return false
        }
    }



    @IBAction func addFilter(_ sender: UIBarButtonItem) {
        // hideParmControls()
        self.appStack.viewerStack.stackMode =  FilterChangeMode.add

        postFilterNavigationChange()
        performSegue(withIdentifier: "showFilterController", sender: self)
            // chooses new filter
    }

    @IBAction func showImageControllerAction(_ sender: UIBarButtonItem) {


        splitViewController?.show(.secondary)
        postCurrentFilterChange() // triggers PGLImageController to set view.isHidden to false
            // show the new results !


    }

//    func showStackControllerAction() {
//        // other part of split should navigate back to the stack controller
//        // after the Random button is clicked
//        let goToStack = Notification(name: PGLLoadedDataStack)
//        NotificationCenter.default.post(goToStack)
//
//    }

    // MARK: - LongPressGestures
    func setLongPressGesture() {

        longPressGesture = UILongPressGestureRecognizer(target: self , action: #selector(PGLFilterTableController.longPressAction(_:)))
          if longPressGesture != nil {

//                 " defaults to 0.5 sec 1 finger 10 points allowed movement"
              tableView.addGestureRecognizer(longPressGesture!)
              longPressGesture!.isEnabled = true
//            NSLog("PGLStackController setLongPressGesture \(String(describing: longPressGesture))")
          }
      }

    func removeGestureRecogniziers(targetView: UIView) {
       // not called in viewWillDissappear..
       // recognizier does not seem to get restored if removed...
        if longPressGesture != nil {
            tableView.removeGestureRecognizer(longPressGesture!)
            longPressGesture!.removeTarget(self, action: #selector(PGLFilterTableController.longPressAction(_:)))
            longPressGesture = nil
//           NSLog("PGLStackController removeGestureRecogniziers ")
       }

    }

    @objc func longPressAction(_ sender: UILongPressGestureRecognizer) {

        let point = sender.location(in: tableView)

        if sender.state == .began
        {   Logger(subsystem: LogSubsystem, category: LogCategory).debug("PGLStackController longPressAction begin")
            guard let longPressIndexPath = tableView.indexPathForRow(at: point) else {
                longPressStart = nil // assign to var
                return
            }
            longPressStart = longPressIndexPath // assign to var
        }
        if sender.state == .recognized {  // could also use .ended but there is slight delay
            // open popup with filter userDescription
            if longPressStart != nil {

                guard let tableCell = tableView.cellForRow(at: longPressStart!) else { return  }
                let aFilterIndent = appStack.filterAt(indexPath: longPressStart!)
                if let description = aFilterIndent.filter.filterUserDescription() {
                // now need the PGLFilterDescriptor from the filter..
                // filter should be able to get it's descriptor from
                // filter name and class
                    let myDisplayName = aFilterIndent.filter.descriptorDisplayName ?? "Filter"
                    popUpFilterDescription(filterName: myDisplayName, filterText: description, filterCell: tableCell)
                } else { return }
            }
        }



    }

    func popUpFilterDescription(filterName: String, filterText: String, filterCell: UITableViewCell) {
        if segueStarted { return }
            // don't open if the navigation is already triggered
        guard let helpController = storyboard?.instantiateViewController(withIdentifier: "PGLPopUpFilterInfo") as? PGLPopUpFilterInfo
        else {
            return
        }
        helpController.modalPresentationStyle = .popover
        helpController.preferredContentSize = CGSize(width: 200, height: 350.0)
        // specify anchor point?
        guard let popOverPresenter = helpController.popoverPresentationController
        else { return }
        popOverPresenter.canOverlapSourceViewRect = true // or barButtonItem
        // popOverPresenter.popoverLayoutMargins // default is 10 points inset from device edges
       popOverPresenter.sourceView = filterCell

        helpController.textInfo =  filterText
        helpController.filterName = filterName

        present(helpController, animated: true )

    }


// MARK: Navigation

    func updateNavigationBar() {
//        self.navigationItem.title = self.appStack.firstStack()?.stackName
        self.navigationItem.title = "Effects"
        setNeedsStatusBarAppearanceUpdate()
    }

    fileprivate func postFilterNavigationChange() {
        let updateFilterNotification = Notification(name:PGLCurrentFilterChange)
        NotificationCenter.default.post(updateFilterNotification)
    }

    func postCurrentFilterChange() {
        let updateFilterNotification = Notification(name: PGLCurrentFilterChange)
        NotificationCenter.default.post(updateFilterNotification)
    }

    //PGLSelectActiveStackRow

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // can check  if segue.identifier == "showCollection" and
        // segue.destination as? PGLImageCollectionMasterController ...
        // but currently only one segue so just set the model object for the cell

//        if let cellDetail = sender as? UITableViewCell  {
//
//            if let thePath = tableView.indexPath(for: cellDetail) {
//                let cellObject = appStack.cellFilters[thePath.row]
//                appStack.moveTo(filterIndent: cellObject)
//            }
//
//        }

        switch segue.identifier {
            case "showImageController":
                let controller = segue.destination as! PGLImageController

                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
            case "showParmSettings" :
                    // didSelectRowAt has set the appStack model
                return
            default:
                return
        }

//        if segue.identifier == "showParmSettings" {
//            // didSelectRowAt has set the appStack model
//            return //
//        }


    }

    // MARK: Swipe Actions

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // on swipe from the filter list open the parm controller
          var contextActions = [UIContextualAction]()

        let cellFilter: PGLFilterIndent =  appStack.cellFilters[indexPath.row]
        let thisSourceFilter = cellFilter.filter
        contextActions = thisSourceFilter.cellFilterAction(stackController: self, indexPath: indexPath)

         return UISwipeActionsConfiguration(actions: contextActions)
    }

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        Logger(subsystem: LogSubsystem, category: LogCategory).notice("shouldPerformSegue \(identifier)")
         segueStarted = true
        // don't open a popOverController seque is starting
        return true
    }
    func removeFilter(indexPath: IndexPath) {

        let cellIndent = appStack.cellFilters[indexPath.row]
        appStack.moveTo(filterIndent: cellIndent)
            // sets the activeFilterIndex of the childStack
            // makes the childStack the viewerStack

        let thisStack = appStack.getViewerStack()

        _ = thisStack.removeFilter(position: thisStack.activeFilterIndex)
        // needs work here... the parent of the child stack needs to
        // set the inputStack to nil and update the inputParmState to
        // missingInput

        // change back to the mainstck
        appStack.resetViewStack()


       self.updateDisplay()
        if appStack.showFilterImage {appStack.postSelectActiveStackRow()}
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

        appStack.moveFilter(fromSourceRow: sourceIndexPath, destinationRow: destinationIndexPath )
    }


    func configureNavigationItem() {
//        navigationItem.title = "UITableView: Editing"
        let editingItem = UIBarButtonItem(title: tableView.isEditing ? "Done" : "Edit", style: .plain, target: self, action: #selector(toggleEditing))
        navigationItem.rightBarButtonItems = [editingItem]

        navigationController?.isToolbarHidden = false


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
