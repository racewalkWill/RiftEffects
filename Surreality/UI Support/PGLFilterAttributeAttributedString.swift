//
//  PGLFilterAttributeAttributedString.swift
//  Glance
//
//  Created by Will on 6/18/20.
//  Copyright © 2020 Will. All rights reserved.
//

import Foundation

import UIKit
import Photos
import CoreImage

class PGLFilterAttributeAttributedString: PGLFilterAttribute {
    // AttributedString is NSAttributedString  or
    // see also Core Foundation counterpart, CFAttributedStringRef
    //object that combines a CFString object with a collection of attributes that specify how the characters in the string should be displayed. CFAttributedString is an opaque type

    required init?(pglFilter: PGLSourceFilter, attributeDict: [String:Any], inputKey: String ) {
           super.init(pglFilter: pglFilter, attributeDict: attributeDict, inputKey: inputKey)
            // init to default value of "inputText"
            let attributedString = NSAttributedString(string: "inputText")
            pglFilter.setAttributeStringValue(newValue: attributedString, keyName: inputKey)

       }

    override func set(_ value: Any) {
        if attributeName != nil {
                aSourceFilter.setAttributeStringValue(newValue: value as! NSAttributedString, keyName: attributeName!)
            }
        }

    // do not need to override valueString() implementation of superclass PGLFilterAttribute

}

class PGLFilterAttributeString: PGLFilterAttribute {

    required init?(pglFilter: PGLSourceFilter, attributeDict: [String:Any], inputKey: String ) {
           super.init(pglFilter: pglFilter, attributeDict: attributeDict, inputKey: inputKey)
            // init to default value of "inputText"
            let defaultString = NSString(string: "inputText")
            pglFilter.setStringValue(newValue: defaultString, keyName: inputKey)

       }

//    override func set(_ value: Any) {
//        if attributeName != nil {
//                aSourceFilter.setAttributeStringValue(newValue: value as! NSAttributedString, keyName: attributeName!)
//            }
//        }

    // do not need to override valueString() implementation of superclass PGLFilterAttribute

}

class PGLFilterAttributeData: PGLFilterAttribute {


    required init?(pglFilter: PGLSourceFilter, attributeDict: [String:Any], inputKey: String ) {
           super.init(pglFilter: pglFilter, attributeDict: attributeDict, inputKey: inputKey)
            // init to default value of "inputText"
        var defaultMsg  = "inputMessage"
        let defaultData = NSData(bytes: &defaultMsg, length: defaultMsg.count )
        pglFilter.setDataValue(newValue: defaultData, keyName: inputKey)

       }

    override func set(_ value: Any) {
        if attributeName != nil {
                aSourceFilter.setAttributeStringValue(newValue: value as! NSAttributedString, keyName: attributeName!)
            }
        }

    // do not need to override valueString() implementation of superclass PGLFilterAttribute

}
