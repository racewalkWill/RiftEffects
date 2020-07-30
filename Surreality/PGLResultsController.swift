//
//  PGLResultsController.swift
//  Glance
//
//  Created by Will on 5/30/19.
//  Copyright © 2019 Will. All rights reserved.
//

import UIKit

class PGLResultsController: PGLFilterTableController {

    override func viewDidLoad() {
        super .viewDidLoad()
        mode = .Flat
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//         dump("PGLResultsController numberOfRowsInSection count = \(matchFilters.count)")
        return matchFilters.count
    }

//    override func numberOfSections(in tableView: UITableView) -> Int {
//        switch mode {
//        case .Flat:
//            return 1
//        case .Grouped
//            return categories.count
//        }
//    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PGLFilterTableController.tableViewCellIdentifier, for: indexPath)
        let thisFilter = matchFilters[indexPath.row]
        configureCell(cell, descriptor: thisFilter)

        return cell
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        var shouldHighlight = false
        if let currentFilter = stackData()?.currentFilter() {
            shouldHighlight =  currentFilter.filterName == (matchFilters[indexPath.row]).filterName
        }
        return shouldHighlight
    }
   
}
