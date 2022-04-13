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

    // the filter CIAttributedTextImageGenerator  is not very useful.. this keeps it from blowing up
    // the Blend Text filter is better for use - has text position, font & size parms.
    required init?(pglFilter: PGLSourceFilter, attributeDict: [String:Any], inputKey: String ) {
           super.init(pglFilter: pglFilter, attributeDict: attributeDict, inputKey: inputKey)
            // init to default value of "inputText"
            let attributedString = NSAttributedString(string: "inputText")
            pglFilter.setAttributeStringValue(newValue: attributedString, keyName: inputKey)

       }

    override func set(_ value: Any) {
        if attributeName != nil {
            // see
            //https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/AttributedStrings/Tasks/CreatingAttributedStrings.html
             // need font and size
            // create dict of font  then init attributedString with the string and the dict.
            if let myStringValue = value as? String {
              let attributedString = NSAttributedString(string: myStringValue)
                aSourceFilter.setAttributeStringValue(newValue: attributedString, keyName: attributeName!) }
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

    override  func setUICellDescription(_ uiCell: UITableViewCell) {
      var content = uiCell.defaultContentConfiguration()
      let newDescriptionString = self.attributeDisplayName ?? ""
      content.text = newDescriptionString
      content.imageProperties.tintColor = .secondaryLabel
    content.image = UIImage(systemName: "character.textbox")

      uiCell.contentConfiguration = content

    }

//    override func set(_ value: Any) {
//        if attributeName != nil {
//                aSourceFilter.setAttributeStringValue(newValue: value as! NSAttributedString, keyName: attributeName!)
//            }
//        }

    // do not need to override valueString() implementation of superclass PGLFilterAttribute

}

class PGLFilterAttributeData: PGLFilterAttribute {
    // The documentation for the string generator classes which have message as NSData
    // include this
    //  NSData object using the NSISOLatin1StringEncoding string encoding
    //  or  NSASCIIStringEncoding
    // not clear how this affects the NSData conversion..
    // affected classes
//    CIQRCodeGenerator convert it to an NSData object using the NSISOLatin1StringEncoding string encoding
//    CIPDF417BarcodeGenerator   NSISOLatin1StringEncoding string encoding.
//    CICode128BarcodeGenerator  NSASCIIStringEncoding string encoding.
//    CIAztecCodeGenerator  NSISOLatin1StringEncoding string encoding
// see https://developer.apple.com/documentation/foundation/nsstringencoding
// and https://developer.apple.com/library/archive/documentation/CoreFoundation/Conceptual/CFStrings/introCFStrings.html#//apple_ref/doc/uid/10000131i

    required init?(pglFilter: PGLSourceFilter, attributeDict: [String:Any], inputKey: String ) {
           super.init(pglFilter: pglFilter, attributeDict: attributeDict, inputKey: inputKey)
            // init to default value of "inputText"
        var defaultMsg  = "inputMessage"
        let defaultData = NSData(bytes: &defaultMsg, length: defaultMsg.count )
        pglFilter.setDataValue(newValue: defaultData, keyName: inputKey)

       }

    override func set(_ value: Any) {
        if attributeName != nil {
        var stringValue = value as? String
            if stringValue == nil { return }  // guard for nil
        let valueData =  NSData(bytes: &stringValue, length: stringValue?.count ?? 0 )
        aSourceFilter.setDataValue(newValue: valueData, keyName: attributeName!)
        }
    }

    // do not need to override valueString() implementation of superclass PGLFilterAttribute

}
