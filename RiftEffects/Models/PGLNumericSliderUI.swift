//
//  PGLNumericSliderUI.swift
//  RiftEffects
//
//  Created by Will on 12/27/22.
//  Copyright © 2022 Will Loew-Blosser. All rights reserved.
//

import Foundation

import UIKit
import os

class PGLNumericSliderUI: PGLFilterAttribute {
    // number slider in the parm list cell
    // used for Convolution numeric parms

    var row = 0
    var column = 0

    var convolutionWeights: PGLAttributeWeightsVector!

    init?(convolution: PGLAttributeWeightsVector, matrixRow: Int, matrixColumn: Int) {

        convolutionWeights = convolution
        row = matrixRow
        column = matrixColumn

        
        super.init(pglFilter: convolution.aSourceFilter, attributeDict: convolution.initDict, inputKey: convolution.attributeName!)

        if attributeClass == nil {
            Logger(subsystem: LogSubsystem, category: LogCategory).error ("\( String(describing: self) + "-" + #function) attributeClass is nil")
            fatalError()
        } else {
//            NSLog("\( String(describing: self) + "-" + #function) attributeClass \(attributeClass)")
        }
        attributeDisplayName = "\(row),\(column)"
        attributeName = attributeDisplayName! + "weight"
            // attributeName is index for parm controls must be unique

        attributeType = AttrType.Scalar.rawValue
            // Interface Builder slider max attribute controls these setting
        sliderMaxValue = 2.0
        sliderMinValue = -2.0
        defaultValue = 0.0
        identityValue = 0.0
        indentLevel = 1

    }

    required init?(pglFilter: PGLSourceFilter, attributeDict: [String : Any], inputKey: String) {
        super.init(pglFilter: pglFilter, attributeDict: attributeDict, inputKey: inputKey)
    }



    override  func getValue() -> Any? {
        return getWeightValue()
    }

    func getWeightValue() -> CGFloat? {
          return convolutionWeights.getValue(row: row, column: column)

    }

    override func set(_ value: Any) {
         let newWeight = CGFloat(value as? Float ?? 0.0)
        
        convolutionWeights.setWeight(newValue: newWeight, row: row, column: column)

    }

// MARK: UI sliders
    override func uiCellIdentifier() -> String {
     // uncomment this to have the number slider appear in the parm cell
     // otherwise it appears in the image
            return  "parmSliderInputCell"
        }

    override func setUICellDescription(_ uiCell: UITableViewCell) {
        guard let cell = (uiCell as? PGLTableCellSlider?)
            else { return super.setUICellDescription(uiCell) }
        cell!.textLabel?.text = attributeDisplayName


        guard let slider = cell?.sliderControl
            else { return super.setUICellDescription(uiCell)  }

        slider.minimumValue = sliderMinValue ?? -2.0
        slider.maximumValue = sliderMaxValue ?? +2.0

        slider.value = Float(getWeightValue() ?? 0.0 )
//        cell?.showTextValueInCell()


    }

    override    func isSliderUI() -> Bool {
        return true
    }

    override   func attributeUIType() -> AttrUIType {
        return AttrUIType.timerSliderUI
    }



}
