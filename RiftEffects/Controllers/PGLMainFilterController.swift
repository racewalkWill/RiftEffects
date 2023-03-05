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

let ABCSymbol = UIImage(systemName: "textformat.abc")
let GroupSymbol = UIImage(systemName: "rectangle.grid.1x2")


let PGLFilterBookMarksModeChange = NSNotification.Name(rawValue: "PGLFilterBookMarksModeChange")

let PGLFilterBookMarksSetFlat = NSNotification.Name(rawValue: "PGLFilterBookMarksSetFlat")

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
        Logger(subsystem: LogSubsystem, category: LogNavigation).info( "\("#popViewController " + String(describing: self))")
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

        searchController = UISearchController(searchResultsController: resultsTableController)
        searchController.searchResultsUpdater = self
        searchController.searchBar.autocapitalizationType = .none


        searchController.automaticallyShowsCancelButton = true

            //           navigationItem.searchController = searchController

            // using searchController in the nav item causes the width of the searchbar
            // to be twice as big. Leading edge is cut off.
            // there is a comment -- For iOS 11 and later, place the search bar in the navigation bar.
            // but it has this leading edge cut off issue.

            //        tableView.tableHeaderView = searchController.searchBar

            //           navigationItem.hidesSearchBarWhenScrolling = (mode == .Grouped) // flat mode searches
        navigationController?.isToolbarHidden = false

        searchController.hidesNavigationBarDuringPresentation = false


        /** Specify that this view controller determines how the search controller is presented.
         The search controller should be presented modally and match the physical size of this view controller.
         */
        definesPresentationContext = true

            // Uncomment the following line to preserve selection between presentations
            //            self.clearsSelectionOnViewWillAppear = false

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
