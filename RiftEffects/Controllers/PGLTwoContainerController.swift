//
//  PGLTwoContainerController.swift
//  RiftEffects
//
//  Created by Will on 5/6/22.
//  Copyright © 2022 Will Loew-Blosser. All rights reserved.
//

import UIKit
import os

class PGLTwoContainerController: UIViewController {
    // handles segues for iPad/iPhone segue paths
    // iPad does not use the two container view
    // iPhone shows parm and image controlls inside the two containers of the view

    var containerImageController: PGLImageController?
    var containerParmController: PGLSelectParmController?

    override func viewDidLoad() {
        Logger(subsystem: LogSubsystem, category: LogNavigation).info("\( String(describing: self) + "-" + #function)")
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    


    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        let segueId = segue.identifier
        
        Logger(subsystem: LogSubsystem, category: LogNavigation).info("\( String(describing: self) + "-" + #function) + String(describing: segueId)")

        switch segueId {
            case "embedImageController" :

                guard let destination = segue.destination  as? PGLImageController
                    else { return  }
                containerImageController = destination

            case "embedParmController" :
                guard let parmDestination = segue.destination as? PGLSelectParmController
                    else { return }
                containerParmController = parmDestination

            default: return
        }

    }


}
