//
//  PGLResultsController.swift
//  Glance
//
//  Created by Will on 5/30/19.
//  Copyright © 2019 Will. All rights reserved.
//

import UIKit
import os
class PGLResultsController: PGLMainFilterController {

    var segueToParmController: UIStoryboardSegue!
    override func viewDidLoad() {
//        Logger(subsystem: LogSubsystem, category: LogNavigation).info("\( String(describing: self) + "-" + #function)")
        super .viewDidLoad()
  
    }
    
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
////         dump("PGLResultsController numberOfRowsInSection count = \(matchFilters.count)")
//        return matchFilters.count
//    }



//    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: PGLFilterTableController.tableViewCellIdentifier, for: indexPath)
//        let thisFilter = matchFilters[indexPath.row]
////        cell.accessoryType = .detailDisclosureButton or add detail disclosure in the TableCell.xib file
//        configureCell(cell, descriptor: thisFilter)
////        cell.forwardingTarget(for: <#T##Selector!#>)
//
//        return cell
//    }

//    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
//        var shouldHighlight = false
//        if let currentFilter = stackData()?.currentFilter() {
//            shouldHighlight =  currentFilter.filterName == (matchFilters[indexPath.row]).filterName
//        }
//        return shouldHighlight
//    }
}
