//
//  PGLMainFilterController.swift
//  Glance
//
//  Created by Will on 5/30/19.
//  Copyright © 2019 Will. All rights reserved.
//

import UIKit
import os

enum FilterChangeMode{
    case replace
    case add
}


let PGLFilterBookMarksSetFlat = NSNotification.Name(rawValue: "PGLFilterBookMarksSetFlat")

class PGLMainFilterController:  UIViewController,
                                    UINavigationControllerDelegate, UISplitViewControllerDelegate,UIPopoverPresentationControllerDelegate,
                                    UICollectionViewDelegate {
        //UIDragInteractionDelegate, UIDropInteractionDelegate


        // MARK: ListView
     struct Item: Hashable {
        let title: String?
        let descriptor: PGLFilterDescriptor?
            // if nil then use the title for the category
    }

     var dataSource: UICollectionViewDiffableDataSource<Int, Item>! = nil
     var filterCollectionView: UICollectionView! = nil

    private let appearance = UICollectionLayoutListConfiguration.Appearance.insetGrouped
    // assigned in configureHierarchy of viewDidLoad
    var searchBar: UISearchBar!

    // MARK: model vars
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
            filterCollectionView.reloadData()
        }
    }
        // MARK: - Types

        /// State restoration values.
    private enum RestorationKeys: String {
        case viewControllerTitle
        case searchControllerIsActive
        case searchBarText
        case searchBarIsFirstResponder
    }

        /// NSPredicate expression keys.
    private enum ExpressionKeys: String {
        case displayName
            //        case yearIntroduced
            //        case introPrice
    }

    private struct SearchControllerRestorableState {
        var wasActive = false
        var wasFirstResponder = false
    }

    /** The following 2 properties are set in viewDidLoad(),
     They are implicitly unwrapped optionals because they are used in many other places
     throughout this view controller.
     */

        /// Search controller to help us with filtering.
    private var searchController: UISearchController!
        //    var filterGroupSymbol = UIImage(systemName: "chart.bar.doc.horizontal")
        //    var filterFlatSymbol = UIImage(systemName: "crectangle.grid.1x2")
        /// Secondary search results table view.
//    private var resultsTableController: PGLResultsController!

        /// Restoration state for UISearchController
    private var restoredState = SearchControllerRestorableState()

    @IBAction func backButtonAction(_ sender: UIBarButtonItem) {
        Logger(subsystem: LogSubsystem, category: LogNavigation).info( "\("#popViewController " + String(describing: self))")
        self.navigationController?.popViewController(animated: true)

    }

    @IBAction func showImageController(_ sender: UIBarButtonItem) {
        splitViewController?.show(.secondary)
        postCurrentFilterChange() // triggers PGLImageController to set view.isHidden to false
    }


        // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // MARK: List Setup

        configureHierarchy()
        configureDataSource()
        loadSearchController()
        selectCurrentFilterRow()

    //        Logger(subsystem: LogSubsystem, category: LogNavigation).info("\( String(describing: self) + "-" + #function)")
        _ = UINib(nibName: PGLMainFilterController.nibName, bundle: nil)

        splitViewController?.delegate = self
        guard let myAppDelegate =  UIApplication.shared.delegate as? AppDelegate
            else { Logger(subsystem: LogSubsystem, category: LogCategory).fault ("PGLFilterTableController viewDidLoad fatalError AppDelegate not loaded")
                return
        }
        appStack = myAppDelegate.appStack
        stackData = { self.appStack.viewerStack }
        // closure is evaluated when referenced
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


        setLongPressGesture()

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

            // Restore the searchController's active state.
        if restoredState.wasActive {
            searchController.isActive = restoredState.wasActive
            restoredState.wasActive = false

            if restoredState.wasFirstResponder {
                searchController.searchBar.becomeFirstResponder()
                restoredState.wasFirstResponder = false
            }
        }

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

        Logger(subsystem: LogSubsystem, category: LogCategory).info("PGLFilterTableController performFilterPick \(descriptor)")
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

        longPressGesture = UILongPressGestureRecognizer(target: self , action: #selector(PGLMainFilterController.longPressAction(_:)))
          if longPressGesture != nil {

//                 " defaults to 0.5 sec 1 finger 10 points allowed movement"
              filterCollectionView.addGestureRecognizer(longPressGesture!)
              longPressGesture!.isEnabled = true
//            Logger(subsystem: LogSubsystem, category: LogCategory).notice("PGLFilterTableController setLongPressGesture \(String(describing: self.longPressGesture))")
          }
      }

    func removeGestureRecogniziers(targetView: UIView) {
       // not called in viewWillDissappear..
       // recognizier does not seem to get restored if removed...
        if longPressGesture != nil {
            filterCollectionView.removeGestureRecognizer(longPressGesture!)
            longPressGesture!.removeTarget(self, action: #selector(PGLMainFilterController.longPressAction(_:)))
            longPressGesture = nil
//           NSLog("PGLFilterTableController removeGestureRecogniziers ")
       }

    }

    @objc func longPressAction(_ sender: UILongPressGestureRecognizer) {

//        let pressLocation = sender.location(in: filterCollectionView)
        var longPressIndexPath: [IndexPath]?

        if sender.state == .began
        {
            Logger(subsystem: LogSubsystem, category: LogCategory).debug("PGLFilterTableController longPressAction begin")
            longPressIndexPath = filterCollectionView.indexPathsForSelectedItems
            if longPressIndexPath == nil {
                longPressStart = nil // assign to var
                return
            }
            longPressStart = longPressIndexPath!.first // assign to var
        }
        if sender.state == .recognized || sender.state == .ended {
            if longPressStart != nil {
                guard let tableCell = filterCollectionView.cellForItem(at: longPressStart!) else { return  }

                if let thisDescriptor = dataSource.itemIdentifier(for: longPressStart!)?.descriptor {
                    popUpFilterDescription(filterName: thisDescriptor.displayName, filterText: thisDescriptor.userDescription, filterCell: tableCell)
                }
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
    // MARK: - Navigation


    extension PGLMainFilterController: UISearchBarDelegate {

        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            Logger(subsystem: LogSubsystem, category: LogCategory).debug("PGLMainFilterController searchBarSearchButtonClicked")
            searchBar.resignFirstResponder()
        }

    }

    // MARK: - UISearchControllerDelegate

    // Use these delegate functions for additional control over the search controller.

extension PGLMainFilterController: UISearchControllerDelegate {

        func presentSearchController(_ searchController: UISearchController) {
            Logger(subsystem: LogSubsystem, category: LogCategory).info("UISearchControllerDelegate invoked method: \(#function).")
        }

        func willPresentSearchController(_ searchController: UISearchController) {
            Logger(subsystem: LogSubsystem, category: LogCategory).info("UISearchControllerDelegate invoked method: \(#function).")
        }

        func didPresentSearchController(_ searchController: UISearchController) {
//            selectCurrentFilterRow()
            searchController.searchBar.becomeFirstResponder()
            Logger(subsystem: LogSubsystem, category: LogCategory).info("UISearchControllerDelegate invoked method: \(#function).")
        }

//        func willDismissSearchController(_ searchController: UISearchController) {
//            Logger(subsystem: LogSubsystem, category: LogCategory).debug("UISearchControllerDelegate invoked method: \(#function).")
//        }

        func didDismissSearchController(_ searchController: UISearchController) {
            initalFilterList()
            Logger(subsystem: LogSubsystem, category: LogCategory).debug("UISearchControllerDelegate invoked method: \(#function).")
        }

}


    extension PGLMainFilterController: UISearchResultsUpdating {
            //MARK: SearchController setup
        fileprivate func loadSearchController() {

            // called by viewDidLoad()
            searchController = UISearchController(searchResultsController: nil)


            searchController.searchResultsUpdater = self
            searchController.delegate = self

            searchController.automaticallyShowsCancelButton = true

                // IF iPhone then PGLNavStackImageController has the navigation item

            navigationItem.searchController = searchController

            searchController.searchBar.delegate = self
            navigationController?.isToolbarHidden = false
            searchController.hidesNavigationBarDuringPresentation = false


            /** Specify that this view controller determines how the search controller is presented.
             The search controller should be presented modally and match the physical size of this view controller.
             */
            definesPresentationContext = false

//            let iPhoneCompact =   (traitCollection.userInterfaceIdiom) == .phone
//                                    && (traitCollection.horizontalSizeClass == .compact)
//            if iPhoneCompact {
//                searchBar =  searchController.searchBar  //
//                searchBar.translatesAutoresizingMaskIntoConstraints = false
//    //            searchBar.translatesAutoresizingMaskIntoConstraints = true
//                view.addSubview(searchBar)
//                searchBar.delegate = self
//                searchBar.isHidden = false
//                searchBar.searchTextField.autocapitalizationType = .none
//
//
//
//                    NSLayoutConstraint.activate([
//                        searchBar.topAnchor.constraint(equalToSystemSpacingBelow: view.safeAreaLayoutGuide.topAnchor, multiplier: 1.0),
//                        searchBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
//                        searchBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
//                        searchBar.heightAnchor.constraint(equalToConstant: 40),
//
//                        filterCollectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 10),
//                        // (equalTo: view.safeAreaLayoutGuide.topAnchor),
//                        filterCollectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
//                        filterCollectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
//                        filterCollectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50)
//                        // -50 allow room for the toolbar
//                    ])
//
//
//            }

        }


        private func findMatches(searchString: String) -> NSCompoundPredicate {
            /** Each searchString creates an OR predicate for: name, yearIntroduced, introPrice.
             Example if searchItems contains "Gladiolus 51.99 2001":
             name CONTAINS[c] "gladiolus"
             name CONTAINS[c] "gladiolus", yearIntroduced ==[c] 2001, introPrice ==[c] 51.99
             name CONTAINS[c] "ginger", yearIntroduced ==[c] 2007, introPrice ==[c] 49.98
             */
            var searchItemsPredicate = [NSPredicate]()

            /** Below we use NSExpression represent expressions in our predicates.
             NSPredicate is made up of smaller, atomic parts:
             two NSExpressions (a left-hand value and a right-hand value).
             */

            // Name field matching.
            let titleExpression = NSExpression(forKeyPath: ExpressionKeys.displayName.rawValue)
            let searchStringExpression = NSExpression(forConstantValue: searchString)

            let titleSearchComparisonPredicate =
                NSComparisonPredicate(leftExpression: titleExpression,
                                      rightExpression: searchStringExpression,
                                      modifier: .direct,
                                      type: .contains,
                                      options: [.caseInsensitive, .diacriticInsensitive])

            searchItemsPredicate.append(titleSearchComparisonPredicate)



            let orMatchPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: searchItemsPredicate)

            Logger(subsystem: LogSubsystem, category: LogCategory).debug("PGLMainFilterController \(#function) orMatchPredicate = \(orMatchPredicate)")
            return orMatchPredicate
        }

        func updateSearchResults(for searchController: UISearchController) {
            // Update the filtered array based on the search text.
            let searchResults = filters
//            mode = .Flat // change later to support search in the grouped mode

            // Strip out all the leading and trailing spaces.
            let whitespaceCharacterSet = CharacterSet.whitespaces
            let strippedString =
                searchController.searchBar.text!.trimmingCharacters(in: whitespaceCharacterSet)
            if !strippedString.isEmpty {
                let searchItems = strippedString.components(separatedBy: " ") as [String]

                    // Build all the "AND" expressions for each value in searchString.
                let andMatchPredicates: [NSPredicate] = searchItems.map { searchString in
                    findMatches(searchString: searchString)
                }

                    // Match up the fields of the Product object.
                let finalCompoundPredicate =
                NSCompoundPredicate(andPredicateWithSubpredicates: andMatchPredicates)

                let resultSet = Set(searchResults.filter { finalCompoundPredicate.evaluate(with: $0) } )
                let filteredResults = Array(resultSet)
                    // Apply the filtered results to the search results table.
                displaySearchResults(matchingFilters: filteredResults)
            } else
            {  // empty search string.. show everything
                displaySearchResults(matchingFilters: searchResults)
            }

        }

        func displaySearchResults(matchingFilters: [PGLFilterDescriptor]) {
            var filterItems = matchingFilters.map { Item(title: $0.displayName, descriptor: $0)}

            // get dataSource snapshot
            var snapshot = NSDiffableDataSourceSnapshot<Int, Item>()

            snapshot.appendSections([0])
//            snapshot.insertSections([0], beforeSection: 0)

            let categoryHeaderItem = Item(title: "Matches", descriptor: nil)
            filterItems.insert(categoryHeaderItem, at: 0)

            snapshot.appendItems(filterItems, toSection: 0)
            dataSource.apply(snapshot, animatingDifferences: true)
        }

}
// MARK: - UIStateRestoration

extension PGLMainFilterController {
    override func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)

        // Encode the view state so it can be restored later.

        // Encode the title.
        coder.encode(navigationItem.title!, forKey: RestorationKeys.viewControllerTitle.rawValue)

        // Encode the search controller's active state.
        coder.encode(searchController.isActive, forKey: RestorationKeys.searchControllerIsActive.rawValue)

        // Encode the first responser status.
        coder.encode(searchController.searchBar.isFirstResponder, forKey: RestorationKeys.searchBarIsFirstResponder.rawValue)

        // Encode the search bar text.
        coder.encode(searchController.searchBar.text, forKey: RestorationKeys.searchBarText.rawValue)
    }

    override func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)

        // Restore the title.
        guard let decodedTitle = coder.decodeObject(forKey: RestorationKeys.viewControllerTitle.rawValue) as? String else {
            Logger(subsystem: LogSubsystem, category: LogCategory).error ("PGLMainFilterController decodeRestorableState fatalError( A title did not exist. ")
            return 
        }
        navigationItem.title! = decodedTitle

        /** Restore the active state:
         We can't make the searchController active here since it's not part of the view
         hierarchy yet, instead we do it in viewWillAppear.
         */
        restoredState.wasActive = coder.decodeBool(forKey: RestorationKeys.searchControllerIsActive.rawValue)

        /** Restore the first responder status:
         Like above, we can't make the searchController first responder here since it's not part of the view
         hierarchy yet, instead we do it in viewWillAppear.
         */
        restoredState.wasFirstResponder = coder.decodeBool(forKey: RestorationKeys.searchBarIsFirstResponder.rawValue)

        // Restore the text in the search field.
        searchController.searchBar.text = coder.decodeObject(forKey: RestorationKeys.searchBarText.rawValue) as? String
    }

}

extension PGLMainFilterController {
    private func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { [unowned self] section, layoutEnvironment in
            var config = UICollectionLayoutListConfiguration(appearance: appearance)
            config.headerMode = .firstItemInSection  // or .supplementary
            return NSCollectionLayoutSection.list(using: config, layoutEnvironment: layoutEnvironment)
        }
    }
}

extension PGLMainFilterController {
    // MARK: List groups

    private func configureHierarchy() {
        // called by viewDidLoad



        filterCollectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        filterCollectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        filterCollectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(filterCollectionView)
        filterCollectionView.delegate = self


        
    }

    private func configureDataSource() {

        let headerRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Item> { (cell, indexPath, item) in
//            var content = cell.defaultContentConfiguration()
            var content = UIListContentConfiguration.extraProminentInsetGroupedHeader()
            content.text = item.title
            cell.contentConfiguration = content
            let disclosureOptions = UICellAccessory.outlineDisclosure(
                displayed: .always,
                options: UICellAccessory.OutlineDisclosureOptions() ) {
                    self.displaySearchResults(matchingFilters: self.filters )
                }

            cell.accessories = [disclosureOptions]


        }

        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Item> { [weak self] (cell, indexPath, item) in
            guard self != nil else { return }

            var content = cell.defaultContentConfiguration()
            content.text = item.title
            cell.contentConfiguration = content

            let disclosureOptions = UICellAccessory.OutlineDisclosureOptions(style: .cell)
            cell.accessories = [.outlineDisclosure(options: disclosureOptions)]



        }

        dataSource = UICollectionViewDiffableDataSource<Int, Item>(collectionView: filterCollectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, item: Item) -> UICollectionViewCell? in
            if indexPath.section == 0 {
                // filters header
                return collectionView.dequeueConfiguredReusableCell(using: headerRegistration, for: indexPath, item: item)
            }
            if indexPath.item == 0 {
                return collectionView.dequeueConfiguredReusableCell(using: headerRegistration, for: indexPath, item: item)
            } else {
                return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
            }

        }
        initalFilterList()



    }

    func initalFilterList() {
            // initial data
            /// add a Filter category that expands all

        var snapshot = NSDiffableDataSourceSnapshot<Int, Item>()

        let headerAll = 0
        let sections = Array(1...categories.count)
        snapshot.appendSections([headerAll])
        snapshot.appendSections(sections)
        dataSource.apply(snapshot, animatingDifferences: false)
        var headerSnapShot = NSDiffableDataSourceSectionSnapshot<Item>()
        let headerItem = Item(title: "All Filters", descriptor: nil)
        headerSnapShot.append([headerItem])
        dataSource.apply(headerSnapShot, to: 0)
        for section in sections {
            var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<Item>()
            let categoryHeaderItem = Item(title: categories[section - 1].categoryName, descriptor: nil)
            sectionSnapshot.append([categoryHeaderItem])
            let filterItems = categories[section - 1 ].filterDescriptors.map {Item(title: $0.displayName, descriptor: $0)}
            sectionSnapshot.append(filterItems, to: categoryHeaderItem)
//            sectionSnapshot.collapse(filterItems)
            dataSource.apply(sectionSnapshot, to: section )
        }

//        dataSource.sectionSnapshotHandlers.snapshotForExpandingParent = {
//            parent, currentChildSnapshot -> NSDiffableDataSourceSectionSnapshot<String> in
//
//        }
    }
}

extension PGLMainFilterController {

        /// add selected filter to the frequent category





    func selectedFilterDescriptor(inTable: UICollectionView)-> PGLFilterDescriptor? {
        var selectedDescriptor: PGLFilterDescriptor?

        if let thePath = inTable.indexPathsForSelectedItems?.first {

            let selectedItem = dataSource.itemIdentifier(for: thePath)
            selectedDescriptor = selectedItem?.descriptor

            }
        return selectedDescriptor
    }

    func selectCurrentFilterRow() {
            // select and show the current initial filter
        if stackData()!.isEmptyStack() { return }
        let currentFilter = stackData()?.currentFilter()

        var thePath = IndexPath(row:0, section: 0)

        thePath.section = currentFilter?.uiPosition.categoryIndex ?? 0
        thePath.row = currentFilter?.uiPosition.filterIndex ?? 0

        filterCollectionView.selectItem(at: thePath, animated: true, scrollPosition: .centeredVertically)
        Logger(subsystem: LogSubsystem, category: LogCategory).debug("PGLMainFilterController selects row at \(thePath)")

    }

    func selectedFilterDescriptor(inTable: UITableView)-> PGLFilterDescriptor? {
        var selectedDescriptor: PGLFilterDescriptor?

        if let thePath = inTable.indexPathForSelectedRow {

            selectedDescriptor = categories[thePath.section].filterDescriptors[thePath.row]
            Logger(subsystem: LogSubsystem, category: LogCategory).debug("PGLMainFilterController \(#function) mode = Grouped path = \(thePath)")

        }
        return selectedDescriptor
    }



    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        var descriptor: PGLFilterDescriptor
        descriptor = selectedFilterDescriptor(inTable: filterCollectionView)!

        performFilterPick(descriptor: descriptor)
        navigateToParmController()
    }


    func navigateToParmController() {
        // was     func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {

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
