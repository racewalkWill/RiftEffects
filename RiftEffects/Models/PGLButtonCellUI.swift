//
//  PGLButtonCellUI.swift
//  RiftEffects
//
//  Created by Will on 1/1/23.
//  Copyright © 2023 Will Loew-Blosser. All rights reserved.
//

import Foundation
import UIKit

class PGLButtonCellUI: PGLFilterAttribute {

    override func uiCellIdentifier() -> String {
     // uncomment this to have the number slider appear in the parm cell
     // otherwise it appears in the image
            return  "ButtonTableCell"
        }

}
