//
//  PGLParmsFilterTabsController.swift
//  PictureGlance
//
//  Created by Will L-B on 9/6/17.
//  Copyright © 2017 Will. All rights reserved.
//

import UIKit
import os

class PGLTabsController: UITabBarController {
    // coordinates the parm settings controller and the filter view manager
    // provides the current filter to the parms view.
    // the current filter is a working filter; may not be applied to the stack
    // or it is from the stack..

let filterViewMgrIndex = 0
let parmsViewMgrIndex = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Logger(subsystem: LogSubsystem, category: LogNavigation).info("\( String(describing: self) + "-" + #function)")
        // set the viewFilter
        // pass the filter object into the two tabs
//        NSLog("PGLParmsFilterTabsController->viewDidLoad has viewControllers = \(String(describing: viewControllers))")
        // viewControllers now has navigationControllers that contain the FilterViewManager and ParmTableViewController
//        let filterViewMgr = viewControllers?[filterViewMgrIndex] as! PGLFilterViewManager
//        let parmViewMgr = viewControllers?[parmsViewMgrIndex] as! PGLParmTableViewController

//        parmViewMgr.currentFilter = filterViewMgr.myFilter
            // when change to filterViewMgr.myFilter occurs then notification is needed..
            // or they should be sharing a common accessor method to the property??

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    



    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        NSLog("PGLParmsFilterTabsController prepare for segue \(String(describing: segue.identifier)) ")
//         Get the new view controller using segue.destinationViewController.
//         Pass the selected object to the new view controller.
        let segueId = segue.identifier
        Logger(subsystem: LogSubsystem, category: LogNavigation).info("\( String(describing: self) + "-" + #function) + String(describing: segueId)")

    }





}
