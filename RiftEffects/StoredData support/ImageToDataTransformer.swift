//
//  ImageToDataTransformer.swift
//  Glance
//
//  Created by Will on 12/12/18.
//  Copyright © 2018 Will. All rights reserved.
//

import Foundation
import UIKit

class ImageToDataTransformer: ValueTransformer {

    func allowsReverseTransformation() -> Bool {
        return true
    }

//    override class func transformedValueClass() -> AnyClass  {
//        return  Data.self
//    }
//
//    override func transformedValue(_ value: Any?) -> Any? {
//        return UIImage.pngData(value)
//    }


}
