//
//  PGLStackImageContainerController.swift
//  RiftEffects
//
//  Created by Will on 5/16/22.
//  Copyright © 2022 Will Loew-Blosser. All rights reserved.
//

import UIKit
import os
class PGLStackImageContainerController: UIViewController {

    var containerImageController: PGLCompactImageController?
    var containerStackController: PGLStackController?

    override func viewDidLoad() {
        super.viewDidLoad()
        Logger(subsystem: LogSubsystem, category: LogNavigation).info("\( String(describing: self) + "-" + #function)")
        // Do any additional setup after loading the view.

        Logger(subsystem: LogSubsystem, category: LogNavigation).info("\( String(describing: self) + "-" + #function)")
        super.viewDidLoad()
        if let indexImage = self.children.firstIndex(where: { $0 is PGLCompactImageController }) {
            containerImageController = self.children[indexImage] as? PGLCompactImageController
        }
        if let indexFilter = self.children.firstIndex(where: { $0 is PGLStackController }) {
            containerStackController = self.children[indexFilter] as? PGLStackController
        }

    }
    
    @IBAction func containerAddFilter(_ sender: UIBarButtonItem) {

        containerStackController?.addFilter(sender)


    }
//    func addFilter() {
//            // hideParmControls()
//            self.appStack.viewerStack.stackMode =  FilterChangeMode.add
//
//            postFilterNavigationChange()
//            performSegue(withIdentifier: "showFilterController", sender: self)
//                // chooses new filter
//    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
