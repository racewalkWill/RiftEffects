//
//  PGLCompactPresentationController.swift
//  RiftEffects
//
//  Created by Will on 2/2/22.
//  Copyright © 2022 Will Loew-Blosser. All rights reserved.
//

import UIKit

class PGLCompactPresentationController: UIPresentationController {
    // in  the compact width on the iPhone the presentations are changing to full width
    // and covering.. can not be dismissed if in  full screen mode.

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        NSLog("viewWillTransition...")

    }

    override var shouldPresentInFullscreen: Bool {
        return false
    }

//    var frameOfPresentedViewInContainerView: CGRect {
//
//    }

}
