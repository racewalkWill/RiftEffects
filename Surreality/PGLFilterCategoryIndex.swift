//
//  PGLFilterCategoryIndex.swift
//  Glance
//
//  Created by Will on 10/22/17.
//  Copyright © 2017 Will. All rights reserved.
//

import Foundation

class PGLFilterCategoryIndex {
    // provides link to UI arrays for buttons
    var categoryIndex: Int
    var filterIndex: Int
    var categoryCodeName: String  // not the localized Name
    var filterCodeName: String  // not the localized Name

    init(category: Int, filter: Int, catCodeName: String, filtCodeName: String) {
        categoryIndex = category
        filterIndex = filter
        categoryCodeName = catCodeName
        filterCodeName = filtCodeName
    }

    convenience init() {
        self.init(category: 0, filter: 0, catCodeName: "new", filtCodeName: "new")
    }

}
