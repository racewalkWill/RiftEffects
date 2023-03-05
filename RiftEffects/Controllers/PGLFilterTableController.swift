//
//  PGLFilterTableController.swift
//  Glance
//
//  Created by Will on 5/26/19.
//  Copyright © 2019 Will Loew-Blosser. All rights reserved.
//  TableView implementation of PGLSelectFilterController

import UIKit
import os


class PGLFilterTableController: UIViewController,  UINavigationControllerDelegate, UISplitViewControllerDelegate, UIPopoverPresentationControllerDelegate, UICollectionViewDelegate {
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

    // MARK: ListView
     struct Item: Hashable {
        let title: String?
        let descriptor: PGLFilterDescriptor?
            // if nil then use the title for the category
    }

     var dataSource: UICollectionViewDiffableDataSource<Int, Item>! = nil
     var tableView: UICollectionView! = nil

        // MARK: from PGLMainFilterController
        @IBOutlet weak var addToFrequentBtn: UIBarButtonItem!


        @IBOutlet weak var bookmarkRemove: UIBarButtonItem!

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

        // MARK: List Setup
        configureHierarchy()
        configureDataSource()
        selectCurrentFilterRow()

//        tableView.tableHeaderView = searchController.searchBar

//        Logger(subsystem: LogSubsystem, category: LogNavigation).info("\( String(describing: self) + "-" + #function)")
        _ = UINib(nibName: PGLFilterTableController.nibName, bundle: nil)


        
//        clearsSelectionOnViewWillAppear = false // keep the selection

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


        let myCenter =  NotificationCenter.default
        let queue = OperationQueue.main
      let aNotification =  myCenter.addObserver(forName: PGLLoadedDataStack, object: nil , queue: queue) {[weak self]
            myUpdate in
           Logger(subsystem: LogSubsystem, category: LogNavigation).info("PGLFilterTableController  notificationBlock PGLLoadedDataStack")
            guard let self = self else { return } // a released object sometimes receives the notification
                          // the guard is based upon the apple sample app 'Conference-Diffable'
          Logger(subsystem: LogSubsystem, category: LogNavigation).info( "\("#popViewController " + String(describing: self))")
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





    func performFilterPick(descriptor: PGLFilterDescriptor) {
        // called by both subclasses from didSelectRow
        Logger(subsystem: LogSubsystem, category: LogCategory).info("PGLFilterTableController performFilterPick ")
        if let selectedFilter = descriptor.pglSourceFilter() {
            stackData()?.performFilterPick(selectedFilter: selectedFilter)
                // depending on mode will replace or add to the stack
            selectedFilter.addChildSequenceStack(appStack: appStack) // usually empty method except for the PGLSequencedFilters
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

        }
}


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

        _ = sender.location(in: tableView)

        if sender.state == .began
        {
            Logger(subsystem: LogSubsystem, category: LogCategory).debug("PGLFilterTableController longPressAction begin")
            guard let longPressIndexPath = tableView.indexPathsForSelectedItems else {
                longPressStart = nil // assign to var
                return
            }
            longPressStart = longPressIndexPath.first // assign to var
        }
        if sender.state == .recognized {  // could also use .ended but there is slight delay
            // open popup with filter userDescription
            if longPressStart != nil {
                var descriptor: PGLFilterDescriptor

                guard let tableCell = tableView.cellForItem(at: longPressStart!) else { return  }
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

    func popUpFilterDescription(filterName: String, filterText: String, filterCell: UICollectionViewCell) {
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

extension PGLFilterTableController {
    // MARK: List groups
    private func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { [unowned self] section, layoutEnvironment in
            var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
            config.headerMode = .firstItemInSection
            return NSCollectionLayoutSection.list(using: config, layoutEnvironment: layoutEnvironment)
        }
    }

    private func configureHierarchy() {
        tableView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(tableView)
        tableView.delegate = self
    }

    private func configureDataSource() {

        let headerRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, PGLFilterCategory> { (cell, indexPath, item) in
            var content = cell.defaultContentConfiguration()
            content.text = item.categoryName
            cell.contentConfiguration = content

            cell.accessories = [.outlineDisclosure()]
        }

        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, PGLFilterDescriptor> { [weak self] (cell, indexPath, item) in
            guard self != nil else { return }

            var content = cell.defaultContentConfiguration()
            content.text = item.filterName
            cell.contentConfiguration = content

            cell.accessories = [.disclosureIndicator()]

        }

        dataSource = UICollectionViewDiffableDataSource<Int, Item>(collectionView: tableView) {
            (collectionView: UICollectionView, indexPath: IndexPath, item: Item) -> UICollectionViewCell? in

            if item.descriptor == nil {
                let theCategory = self.categories[indexPath.section]
                return self.tableView.dequeueConfiguredReusableCell(using: headerRegistration, for: indexPath, item: theCategory)
            } else {
            return self.tableView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item.descriptor)
            }
        }

        // initial data
        var snapshot = NSDiffableDataSourceSnapshot<Int, Item>()
        let sections = Array(0..<categories.count)
        snapshot.appendSections(sections)
        dataSource.apply(snapshot, animatingDifferences: false)
        for section in sections {
            var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<Item>()
            // section header is a PGLFilterCategory
            // section item is PGLFilterDescriptor
            let categoryHeaderItem = Item(title: categories[section].categoryName, descriptor: nil)
            sectionSnapshot.append([categoryHeaderItem])
            let filterItems = categories[section].filterDescriptors.map {Item(title: $0.filterName, descriptor: $0)}
            sectionSnapshot.append(filterItems)
//            sectionSnapshot.expand([headerItem])
            dataSource.apply(sectionSnapshot, to: section)
        }
    }
}

extension PGLFilterTableController {
        // MARK: from PGLMainFilterController

    func setBookmarksGroupMode(indexSection: Int) {
        if (splitViewController?.isCollapsed ?? false) {
                // parent container PGLFilterImageContainerController has the toolbar with the mode buttons
            let bookmarkModeNotification = Notification(name:PGLFilterBookMarksModeChange)
            NotificationCenter.default.post(name: bookmarkModeNotification.name, object: nil, userInfo:  ["indexSectionValue": indexSection as Any])
            return
                // PGLFilterImageContainerController will set buttons on its toolbar
        }

        if indexSection == 0 {
                // frequent bookmarks section is section 0
            bookmarkRemove.isEnabled = true
            addToFrequentBtn.isEnabled = false
        } else {
            bookmarkRemove.isEnabled = false
            addToFrequentBtn.isEnabled = true
        }
    }

    @IBAction func frequentBtnAction(_ sender: UIBarButtonItem) {
            // scroll filters to Frequent category
            //        if mode == .Flat {
            //            groupModeAction(modeToolBarBtn) // hides search
            //        }
        let frequentCategory = categories[0]
        if !frequentCategory.isEmpty() {

            tableView.selectItem(at: frequentCategoryPath, animated: true, scrollPosition: .top)
            setBookmarksGroupMode(indexSection: frequentCategoryPath.section)
        }


    }

    @IBAction func addToFrequentAction(_ sender: UIBarButtonItem) {
            // add selected filter to the frequent category
            // copy descriptor of the filter
            // add to the frequent category

        if let theDescriptor = selectedFilterDescriptor(inTable: tableView) {
            categories.first?.appendCopy(theDescriptor)

                // frequent category is first
            tableView.reloadSections(IndexSet(integer: 0))
            frequentBtnAction(addToFrequentBtn) // so the frequent cateogry is shown

        }

    }

    @IBAction func bookmarkRemoveAction(_ sender: Any) {
        if let theDescriptor = selectedFilterDescriptor(inTable: tableView) {
            categories.first?.removeDescriptor(theDescriptor)

            tableView.reloadSections(IndexSet(integer: 0))
            if let theFrequentBtn = sender as? UIBarButtonItem {
                frequentBtnAction(theFrequentBtn) // so the frequent cateogry is shown
            }
        }

    }

    func selectedFilterDescriptor(inTable: UICollectionView)-> PGLFilterDescriptor? {
        var selectedDescriptor: PGLFilterDescriptor?

        if let thePath = inTable.indexPathsForSelectedItems?.first {

            switch mode {
                case .Grouped:
                    selectedDescriptor = categories[thePath.section].filterDescriptors[thePath.row]

                case .Flat:
                    selectedDescriptor = filters[thePath.row]

            }

        }
        return selectedDescriptor
    }

     func selectCurrentFilterRow() {
            // select and show the current initial filter
        if stackData()!.isEmptyStack() { return }
        let currentFilter = stackData()?.currentFilter()

        var thePath = IndexPath(row:0, section: 0)
        switch mode {
            case .Grouped:
                thePath.section = currentFilter?.uiPosition.categoryIndex ?? 0
                thePath.row = currentFilter?.uiPosition.filterIndex ?? 0
                setBookmarksGroupMode(indexSection: thePath.section)
                    //            NSLog("PGLMainFilterController \(#function) mode = Grouped")
            case .Flat:
                if let filterRow = filters.firstIndex(where: {$0.filterName == currentFilter?.filterName}) {
                    thePath.row = filterRow
                }
                    //            NSLog("PGLMainFilterController \(#function) mode = Flat")
                setBookmarksFlatMode()
        }

            //        tableView.selectRow(at: thePath, animated: false, scrollPosition: .middle)
        tableView.selectItem(at: thePath, animated: true, scrollPosition: .centeredVertically)
        Logger(subsystem: LogSubsystem, category: LogCategory).debug("PGLMainFilterController selects row at \(thePath)")



    }

    func setBookmarksFlatMode() {
        if (splitViewController?.isCollapsed ?? false) {
                // parent container PGLFilterImageContainerController has the toolbar with the mode buttons
            let bookmarkModeNotification = Notification(name:PGLFilterBookMarksSetFlat)
            NotificationCenter.default.post(bookmarkModeNotification)
            return
                // PGLFilterImageContainerController will set buttons on its toolbar
        }
        bookmarkRemove.isEnabled = false
        addToFrequentBtn.isEnabled = true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        var descriptor: PGLFilterDescriptor
       descriptor = selectedFilterDescriptor(inTable: tableView)!
        performFilterPick(descriptor: descriptor)
    }


    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        // ISSUE - call this in new path of
//         collectionView(UICollectionView, performPrimaryActionForItemAt: IndexPath)

        // manual segue to either the ParmSettings iPad layout or the TwoContainer  iPhone compact layout
        // assumes that didSelectRow has run to set the filterPick into the appStack
        //  therefore indexPath is not used.

        Logger(subsystem: LogSubsystem, category: LogNavigation).info("\( String(describing: self) + "-" + #function)")

        let iPhoneCompact =  splitViewController?.isCollapsed ?? false

        if iPhoneCompact {
           if let  twoContainerController = storyboard?.instantiateViewController(withIdentifier: "PGLParmImageController") as? PGLParmImageController
            {
               navigationController?.pushViewController(twoContainerController, animated: true)
           }
            else {
                return
            }
        } else {
            if let iPadParmController = storyboard?.instantiateViewController(withIdentifier: "ParmSettingsViewController") as? PGLSelectParmController
            {
                navigationController?.pushViewController(iPadParmController, animated: true)
            }
            else {
                return
            }

        }

        // present not needed with segue
    }



} // end PGLMainFilterController methods



