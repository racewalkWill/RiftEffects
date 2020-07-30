//
//  PGLFilterChange.swift
//  PictureGlance
//
//  Created by Will on 4/27/17.
//  Copyright © 2017 Will. All rights reserved.
//

import Foundation
import CoreImage

class PGLFilterChange {
    var attributes = [String : Any]()

    func setAttributeDelta(keyName: String, deltaValue: Any)  {
        // what about min/max values for the attribute?
        // does the filter know this?

        attributes[keyName] = deltaValue
    }
}
