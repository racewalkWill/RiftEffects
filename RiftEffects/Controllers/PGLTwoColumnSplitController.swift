//
//  PGLTwoColumnSplitController.swift
//  RiftEffects
//
//  Created by Will on 2/14/24.
//  Copyright © 2024 Will Loew-Blosser. All rights reserved.
//
import UIKit
import os

class PGLTwoColumnSplitController: UIViewController {
    struct PGLColumns {
        var control: UIViewController
        var imageViewer: UIViewController
    }

    var columns: PGLColumns!

    func loadViewColumns(controller: UIViewController, imageViewer: UIViewController ) {

        columns = PGLColumns(control: controller, imageViewer: imageViewer)

        addChild(columns.imageViewer)
        addChild(columns.control)

        guard let controlView = controller.view else
            { return     }
        guard let imageView = imageViewer.view else
            { return     }

        controlView.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(imageView)
        view.addSubview(controlView)

    //        let spacer = -5.0
            // for iPad and iPhone Plus.. with three column split view

        let iPhoneCompact =  splitViewController?.isCollapsed ?? false
        var imageWidthFactor: Double = 5/3
        if iPhoneCompact {
            imageWidthFactor = 1.2
        }
        // imageWidthFactor adjustment needed for FilterImageContainerController?

        NSLayoutConstraint.activate([
            imageView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: imageWidthFactor),
            // width to height 4:3 ratio
            controlView.rightAnchor.constraint(equalTo: imageView.leftAnchor, constant:  -30.0),
            //            stackContainerView.rightAnchor.constraint(lessThanOrEqualTo: imageContainerView.leftAnchor, constant: -20.0 ),
            controlView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            controlView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            controlView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            //            stackContainerView.widthAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 4/3)
        ] )

            // Notify the child view controller that the move is complete.
        controller.didMove(toParent: self)
        imageViewer.didMove(toParent: self)

    }
}
