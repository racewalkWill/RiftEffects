//
//  PGLDynamicDragBehavior.swift
//  Glance
//
//  Created by Will on 12/3/17.
//  Copyright © 2017 Will. All rights reserved.
//

import UIKit

class PGLDynamicDragBehavior: UIDynamicBehavior {
    // MARK: DropIt
    // from Stanford CS193 sample App DropIt Paul Haggerty instructor
    // http://web.stanford.edu/class/cs193p/cgi-bin/drupal/system/files/sample_code/Dropit_0.zip
    // 12/5/17  an line from the origin to the new point during the drag does not seem to work
    // overriding the draw in the PGLView interfers with the glkView(draw:)
    // keeping PGLDynamicDragBehavior file in the project for possible later use

    lazy var dropBehavior: UIDynamicItemBehavior = {
        let lazyDrop = UIDynamicItemBehavior()
//        lazyDrop.allowsRotation = true
//        lazyDrop.elasticity = 0.60
        return lazyDrop

    }()

    override init() {
        super.init()
        addChildBehavior(dropBehavior)
    }

    func addParmControl(_ controlView: UIView) {
        dynamicAnimator?.referenceView?.addSubview(controlView)
        dropBehavior.addItem(controlView)
//        NSLog("PGLDynamicDragBehavior addParmControl control view  ")
    }

    func removeParmControl (_ controlView: UIView) {
        dropBehavior.removeItem(controlView)
        controlView.removeFromSuperview()
//          NSLog("PGLDynamicDragBehavior removeParmControl control view  ")
    }
}
