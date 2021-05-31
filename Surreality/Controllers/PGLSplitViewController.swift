//
//  PGLSplitViewController.swift
//  Glance
//
//  Created by Will on 10/13/17.
//  Copyright © 2017 Will. All rights reserved.
//

import UIKit
import os



class PGLSplitViewController: UISplitViewController {

    override func viewDidLoad() {

        super.viewDidLoad()
 //       navigationItem.leftBarButtonItem = self.displayModeButtonItem
       preferredDisplayMode = UISplitViewController.DisplayMode.oneBesideSecondary
       presentsWithGesture = true
        // register all of the CIFilter subclasses


    
        // Do any additional setup after loading the view.
       

    }

    @IBAction func goToSplitView(segue: UIStoryboardSegue) {
        Logger(subsystem: LogSubsystem, category: LogCategory).info("PGLParmsFilterTabsController goToSplitView segue")

    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
