//
//  PGLParmImageController.swift
//  RiftEffects
//
//  Created by Will on 5/6/22.
//  Copyright © 2022 Will Loew-Blosser. All rights reserved.
//

import UIKit
import os

class PGLParmImageController: UIViewController {
    // handles segues for iPad/iPhone segue paths
    // iPad does not use the two container view
    // iPhone shows parm and image controlls inside the two containers of the view

    var containerImageController: PGLImageController?
    var containerParmController: PGLSelectParmController?

    deinit {
//        releaseVars()
        Logger(subsystem: LogSubsystem, category: LogMemoryRelease).info("\( String(describing: self) + " - deinit" )")
    }
    
    override func viewDidLoad() {
        Logger(subsystem: LogSubsystem, category: LogNavigation).info("\( String(describing: self) + "-" + #function)")
        super.viewDidLoad()

        let storyboard = UIStoryboard(name: "Main", bundle: .main)

        containerParmController = storyboard.instantiateViewController(withIdentifier: "ParmSettingsViewController") as? PGLSelectParmController

        containerImageController = storyboard.instantiateViewController(withIdentifier: "PGLImageController") as? PGLCompactImageController
        if (containerImageController == nil) || (containerParmController == nil) {
            return // give up no controller
        }

        addChild(containerImageController!)
        addChild(containerParmController!)

        guard let parmContainerView = containerParmController!.view else
            {return     }
        guard let imageContainerView = containerImageController!.view else
            {return     }

        parmContainerView.translatesAutoresizingMaskIntoConstraints = false
        imageContainerView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(imageContainerView)
        view.addSubview(parmContainerView)


//        let spacer = -5.0
        NSLayoutConstraint.activate([
            imageContainerView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            imageContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            imageContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            imageContainerView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 4/3),
                // width to height 4:3 ratio
            parmContainerView.rightAnchor.constraint(equalTo:imageContainerView.leftAnchor, constant:  -30.0),
//            stackContainerView.rightAnchor.constraint(lessThanOrEqualTo: imageContainerView.leftAnchor, constant: -20.0 ),
            parmContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            parmContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            parmContainerView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
//            stackContainerView.widthAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 4/3)
            ] )

            // Notify the child view controller that the move is complete.
        containerParmController?.didMove(toParent: self)
        containerImageController?.didMove(toParent: self)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        containerImageController?.releaseVars()
        containerImageController?.removeFromParent()

        containerImageController = nil

        containerParmController?.removeFromParent()
        containerParmController = nil
    }


    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        let segueId = segue.identifier
        
        Logger(subsystem: LogSubsystem, category: LogNavigation).info("\( String(describing: self) + "-" + #function) + \(String(describing: segueId))")

        

    }


}
