//
//  PGLFilterImageContainerController.swift
//  RiftEffects
//
//  Created by Will on 5/23/22.
//  Copyright © 2022 Will Loew-Blosser. All rights reserved.
//

import UIKit
import os

/// container for Filter and Image controllers side by side
class PGLFilterImageContainerController: UIViewController {
    
    override func viewDidLoad() {
        Logger(subsystem: LogSubsystem, category: LogNavigation).info("\( String(describing: self) + "-" + #function)")
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBAction func addFilterBtn(_ sender: UIBarButtonItem) {
        // Segue back to the stackController
    }

    @IBAction func showImageControllerBtn(_ sender: UIBarButtonItem) {
        // go full screen with the ImageController
        // segue to imageController
    }

    @IBAction func newStackBtn(_ sender: UIBarButtonItem) {
    }
    @IBAction func randomBtn(_ sender: UIBarButtonItem) {
    }
    @IBAction func moreBtn(_ sender: UIBarButtonItem) {
    }

    @IBAction func helpBtn(_ sender: UIBarButtonItem) {
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
