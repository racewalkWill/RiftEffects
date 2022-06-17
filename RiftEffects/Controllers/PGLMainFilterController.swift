//
//  PGLMainFilterController.swift
//  Glance
//
//  Created by Will on 5/30/19.
//  Copyright © 2019 Will. All rights reserved.
//

import UIKit
import os

class PGLMainFilterController: PGLFilterTableController {

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
    private var resultsTableController: PGLResultsController!

    /// Restoration state for UISearchController
    private var restoredState = SearchControllerRestorableState()

    @IBAction func backButtonAction(_ sender: UIBarButtonItem) {
        self.navigationController?.popViewController(animated: true)

    }
    @IBOutlet weak var modeToolBarBtn: UIBarButtonItem!

    @IBOutlet weak var searchToolBarBtn: UIBarButtonItem!

    @IBAction func searchModeAction(_ sender: Any) {
        // set mode to flat and show search controller

        searchController.isActive = true
        mode = .Flat
        if let theSearchModeBtn = sender as? UIBarButtonItem {
            theSearchModeBtn.image = ABCSymbol
        }
        navigationItem.hidesSearchBarWhenScrolling = false
        didPresentSearchController( searchController)
    }

    fileprivate func hideSearchBar() {
        navigationItem.hidesSearchBarWhenScrolling = true
        searchController.isActive = false
        didDismissSearchController( searchController)
    }

    @IBAction func groupModeAction(_ sender: UIBarButtonItem) {
        // set mode to group and show index group tabs
        if mode == .Flat {
            mode = .Grouped
//            hideSearchBar()
            sender.image = GroupSymbol
        } else {
            // mode is Grouped so change
            mode = .Flat // change mode
            sender.image = ABCSymbol

        }

    }



    @IBAction func frequentBtnAction(_ sender: UIBarButtonItem) {
        // scroll filters to Frequent category
        if mode == .Flat {
            groupModeAction(modeToolBarBtn) // hides search
        }
        let frequentCategory = categories[0]
        if !frequentCategory.isEmpty() {
            tableView.selectRow(at: frequentCategoryPath, animated: true, scrollPosition: UITableView.ScrollPosition.top)
            setBookmarksGroupMode(indexSection: frequentCategoryPath.section)
        }


    }

    @IBAction func addToFrequentAction(_ sender: UIBarButtonItem) {
        // add selected filter to the frequent category
        // copy descriptor of the filter
        // add to the frequent category

        if let theDescriptor = selectedFilterDescriptor(inTable: tableView) {
            categories.first?.appendCopy(theDescriptor)
                // tableView.reloadRows(at: [frequentCategoryPath], with: .automatic)
                // frequent category is first
            tableView.reloadSections(IndexSet(integer: 0), with: UITableView.RowAnimation.automatic)
            frequentBtnAction(addToFrequentBtn) // so the frequent cateogry is shown

        }

    }
    @IBOutlet weak var addToFrequentBtn: UIBarButtonItem!


    @IBOutlet weak var bookmarkRemove: UIBarButtonItem!

    @IBAction func bookmarkRemoveAction(_ sender: Any) {
        if let theDescriptor = selectedFilterDescriptor(inTable: tableView) {
            categories.first?.removeDescriptor(theDescriptor)
                // tableView.reloadRows(at: [frequentCategoryPath], with: .automatic)
                // frequent category is first
             tableView.reloadSections(IndexSet(integer: 0), with: UITableView.RowAnimation.automatic)
            if let theFrequentBtn = sender as? UIBarButtonItem {
                frequentBtnAction(theFrequentBtn) // so the frequent cateogry is shown
            }
        }

    }

    @IBAction func showImageController(_ sender: UIBarButtonItem) {
        splitViewController?.show(.secondary)
        postCurrentFilterChange() // triggers PGLImageController to set view.isHidden to false
    }


    func selectedFilterDescriptor(inTable: UITableView)-> PGLFilterDescriptor? {
        var selectedDescriptor: PGLFilterDescriptor?

        if let thePath = inTable.indexPathForSelectedRow {

        switch mode {
            case .Grouped:
                selectedDescriptor = categories[thePath.section].filterDescriptors[thePath.row]
                Logger(subsystem: LogSubsystem, category: LogCategory).debug("PGLMainFilterController \(#function) mode = Grouped")
            case .Flat:
                selectedDescriptor = filters[thePath.row]
                Logger(subsystem: LogSubsystem, category: LogCategory).debug("PGLMainFilterController \(#function) mode = Flat")
            }

        }
        return selectedDescriptor
    }

    // MARK: - View Life Cycle
       override func viewDidLoad() {
           super.viewDidLoad()
           Logger(subsystem: LogSubsystem, category: LogNavigation).info("\( String(describing: self) + "-" + #function)")
           resultsTableController = PGLResultsController()

           resultsTableController.tableView.delegate = self

           searchController = UISearchController(searchResultsController: resultsTableController)
           searchController.searchResultsUpdater = self
           searchController.searchBar.autocapitalizationType = .none

//           searchController.searchBar.showsCancelButton = false
            searchController.automaticallyShowsCancelButton = true

//           navigationItem.searchController = searchController

        // using searchController in the nav item causes the width of the searchbar
        // to be twice as big. Leading edge is cut off.
        // there is a comment -- For iOS 11 and later, place the search bar in the navigation bar.
        // but it has this leading edge cut off issue.

        tableView.tableHeaderView = searchController.searchBar

//           navigationItem.hidesSearchBarWhenScrolling = (mode == .Grouped) // flat mode searches
           navigationController?.isToolbarHidden = false

           searchController.hidesNavigationBarDuringPresentation = false


           /** Specify that this view controller determines how the search controller is presented.
            The search controller should be presented modally and match the physical size of this view controller.
            */
           definesPresentationContext = true

           // Uncomment the following line to preserve selection between presentations
            self.clearsSelectionOnViewWillAppear = false

           // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
           // self.navigationItem.rightBarButtonItem = self.editButtonItem

            setLongPressGesture()
        switch mode {
            case .Grouped:
                modeToolBarBtn.image = GroupSymbol
            case .Flat :
                modeToolBarBtn.image = ABCSymbol
        }
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
        selectCurrentFilterRow()
        // subclass executes this also but there is no tableview at this time.
    }


    fileprivate func selectCurrentFilterRow() {
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

        tableView.selectRow(at: thePath, animated: false, scrollPosition: .middle)
        Logger(subsystem: LogSubsystem, category: LogCategory).debug("PGLMainFilterController selects row at \(thePath)")



    }

   func setBookmarksGroupMode(indexSection: Int) {
        if indexSection == 0 {
            // frequent bookmarks section is section 0
            bookmarkRemove.isEnabled = true
            addToFrequentBtn.isEnabled = false
        } else {
            bookmarkRemove.isEnabled = false
            addToFrequentBtn.isEnabled = true
        }
    }

    func setBookmarksFlatMode() {
        bookmarkRemove.isEnabled = false
        addToFrequentBtn.isEnabled = true
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var descriptor: PGLFilterDescriptor
        if searchController.isActive {
            if resultsTableController.matchFilters.count > indexPath.row {
                descriptor = resultsTableController.matchFilters[indexPath.row] }
            else { return }

        } else {
            if tableView === self.tableView {
                // not a results controller table
               descriptor = selectedFilterDescriptor(inTable: tableView)!
            } else {
                 // grouped mode does not exist in the resultTableController??
                switch mode {
                case .Grouped:
                    descriptor = resultsTableController.categories[indexPath.section].filterDescriptors[indexPath.row]
    //                NSLog("resultsTableController \(#function) mode = Grouped")
                case .Flat:
                    descriptor = resultsTableController.matchFilters[indexPath.row]
    //                NSLog("resultsTableController \(#function) mode = Flat")

                }
            }
            switch mode {
                case .Grouped:
                    setBookmarksGroupMode(indexSection: indexPath.section)
                case .Flat :
                    setBookmarksFlatMode()
            }
        }
         performFilterPick(descriptor: descriptor)

    }

    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        // manual segue to either the ParmSettings iPad layout or the TwoContainer  iPhone compact layout
        // assumes that didSelectRow has run to set the filterPick into the appStack
        //  therefore indexPath is not used.

        let iPhoneCompact =   (traitCollection.userInterfaceIdiom) == .phone
                                && (traitCollection.horizontalSizeClass == .compact)

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

//    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
    // this causes an index side list to be added
//       return categories.map({$0.categoryName})
//    }

//    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
//        return 0
//    }
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
            selectCurrentFilterRow()
            searchController.searchBar.becomeFirstResponder()
            Logger(subsystem: LogSubsystem, category: LogCategory).info("UISearchControllerDelegate invoked method: \(#function).")
        }

        func willDismissSearchController(_ searchController: UISearchController) {
            Logger(subsystem: LogSubsystem, category: LogCategory).debug("UISearchControllerDelegate invoked method: \(#function).")
        }

        func didDismissSearchController(_ searchController: UISearchController) {
             selectCurrentFilterRow()
            Logger(subsystem: LogSubsystem, category: LogCategory).debug("UISearchControllerDelegate invoked method: \(#function).")
        }

}
// MARK: - UISearchResultsUpdating

    extension PGLMainFilterController: UISearchResultsUpdating {

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
            if let resultsController = searchController.searchResultsController as? PGLResultsController {
               //  dump("updateSearchResults found count = \(filteredResults.count)")
                resultsController.matchFilters = filteredResults
                resultsController.tableView.reloadData()
            }
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
