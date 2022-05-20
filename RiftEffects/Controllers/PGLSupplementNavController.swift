//
//  PGLSupplementNavController.swift
//  RiftEffects
//
//  Created by Will on 5/16/22.
//  Copyright © 2022 Will Loew-Blosser. All rights reserved.
//

import UIKit

class PGLSupplementNavController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
//        setRoot()
        // Do any additional setup after loading the view.
    }

    func setRoot() {
        //  root view will be Stack controller
        // OR the StackImageController in the iPhone compact mode
        let iPhoneCompact =   (traitCollection.userInterfaceIdiom) == .phone
                                && (traitCollection.horizontalSizeClass == .compact)

        if iPhoneCompact {
            if let  stackImageController = storyboard?.instantiateViewController(withIdentifier: "StackImageContainer") as? PGLStackImageContainerController {
                pushViewController(stackImageController, animated: true)
            } else
            {
                if let  stackController = storyboard?.instantiateViewController(withIdentifier: "StackController") as? PGLStackController {
                    pushViewController(stackController, animated: true)
                }
            }
        //else don't change root relation if iPad
        }
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
