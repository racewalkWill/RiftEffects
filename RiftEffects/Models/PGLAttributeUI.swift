//
//  PGLAttributeUI.swift
//  Glance
//
//  Created by Will on 4/8/19.
//  Copyright © 2019 Will Loew-Blosser. All rights reserved.
//

import Foundation
import UIKit


class PGLRotateAffineUI: PGLFilterAttributeNumber {
        // was subclass of PGLFilterAttributeNumbe

    var affineParent: PGLFilterAttributeAffine?
//    var rotation: Float = 0.0

    // MARK: PGLAttributeUI protocol

    required init?(pglFilter: PGLSourceFilter, attributeDict: [String : Any], inputKey: String) {

        super.init(pglFilter: pglFilter, attributeDict: attributeDict, inputKey: inputKey)
        attributeDisplayName = "Rotation"
        attributeName = attributeDisplayName! + attributeName!
        attributeType = AttrType.Scalar.rawValue
        // attributeName is index for parm controls must be unique

        sliderMaxValue = 2 * Float.pi
        sliderMinValue = 0.0
    }

    func affine(parent: PGLFilterAttributeAffine) {
        affineParent = parent
    }

    override func incrementValueDelta()  {
         affineParent?.incrementValueDelta()
              postUIChange(attribute: self)

    }
   override func set(_ value: Any) {
        if let rotation = value as? Float {
            affineParent?.setRotation(radians: rotation)
        }
    }

  override  func getValue() -> Any? {
      return affineParent?.rotation
    }

   override func okActionToSetValue() -> Bool {
        return false
    }

   override func restoreOldValue() {
        // empty for now
    }

   override func moveTo(startPoint: CGPoint, newPoint: CGPoint, inView: UIView) {
        // do nothing
    }

  override  func movingChange(startPoint: CGPoint, newPoint: CGPoint, inView: UIView) {
        // do nothing
    }

  override  func movingCorner(atCorner: Vertex, startPoint: CGPoint, newPoint: CGPoint) {
        // do nothing
    }

 override   func attributeUIType() -> AttrUIType {
        return AttrUIType.sliderUI
    }

 override    func isSliderUI() -> Bool {
        return true
    }

  override  func isPointUI() -> Bool {
        return false
    }

   override func isImageUI() -> Bool {
        return false
    }

    override func isRectUI() -> Bool {
        return false
    }

  override  func isImageInput() -> Bool {
        return false
    }

  override  func isBackgroundImageInput() -> Bool {
        return false
    }

  override  func updateFromInputStack() {
    affineParent?.updateFromInputStack()
    }

   override func isSingluar() -> Bool {
    return affineParent?.isSingluar() ?? true
    }


    // MARK: Affine Value set


}

class PGLTranslateAffineUI: PGLFilterAttributeVector {

    var scaler = CGAffineTransform(scaleX: 100.0, y: 100.0)

    var affineParent: PGLFilterAttributeAffine?

    // Vector Expand - same as PGLAttributeVectorExpand


    // MARK: PGLAttributeUI protocol




    required init?(pglFilter: PGLSourceFilter, attributeDict: [String : Any], inputKey: String) {

        super.init(pglFilter: pglFilter, attributeDict: attributeDict, inputKey: inputKey)
        attributeDisplayName = "Translate"
        attributeName = attributeDisplayName! + attributeName!
        attributeType = AttrType.Position.rawValue
            // attributeName is index for parm controls must be unique

    }

    func affine(parent: PGLFilterAttributeAffine) {
        affineParent = parent
    }

    override func incrementValueDelta() {
        affineParent?.incrementValueDelta()
              postUIChange(attribute: self)

    }
    override func set(_ value: Any) {
        if let newTranslationVector = value as? CIVector {

            let scaledValue = scaleVector(inputVector: newTranslationVector, scaleBy: scaler, divideScale: true)
                // divide by 1000 from the UI

            affineParent?.setTranslation(moveBy: scaledValue )  //newTranslationVector
        }
    }

    override  func getValue() -> Any? {

        let parentValue = affineParent?.translate ?? CIVector(cgPoint: CGPointZero)

        let uiVector = scaleVector(inputVector: parentValue, scaleBy: scaler, divideScale: false)
            // multiply by 1000 for the UI

       return uiVector

    }
    

    override func okActionToSetValue() -> Bool {
        return false
    }

    override func restoreOldValue() {
        // empty for now
    }

    override func moveTo(startPoint: CGPoint, newPoint: CGPoint, inView: UIView) {
        // map back to flipped vertical
        // this can be deleted.. moveTo... not called
        let flippedVertical = inView.bounds.height - newPoint.y
        let newVector = CIVector(x: newPoint.x, y: flippedVertical)
        self.set(newVector)
    }

    override  func movingChange(startPoint: CGPoint, newPoint: CGPoint, inView: UIView) {
//        NSLog("PGLTranslateAffineUI movingChange: startPoint = \(startPoint) newPoint = \(newPoint)")
        let flippedVertical = inView.bounds.height - newPoint.y
        let newVector = CIVector(x: newPoint.x, y: flippedVertical)
//         NSLog("PGLTranslateAffineUI movingChange set \(newVector)")
        self.set(newVector)
    }

    override  func movingCorner(atCorner: Vertex, startPoint: CGPoint, newPoint: CGPoint) {
        // do nothing
    }

    override   func attributeUIType() -> AttrUIType {
        return AttrUIType.pointUI
    }

    override    func isSliderUI() -> Bool {
        return false
    }

    override  func isPointUI() -> Bool {
        return true
    }

    override func isImageUI() -> Bool {
        return false
    }

    override func isRectUI() -> Bool {
        return false
    }

    override  func isImageInput() -> Bool {
        return false
    }

    override  func isBackgroundImageInput() -> Bool {
        return false
    }

    override  func updateFromInputStack() {
        affineParent?.updateFromInputStack()
    }

    override func isSingluar() -> Bool {
        return affineParent?.isSingluar() ?? true
    }


    // MARK: Affine Value set


}

class PGLScaleAffineUI: PGLFilterAttributeVector {

    var scaler = CGAffineTransform(scaleX: 100.0, y: 100.0)

    var affineParent: PGLFilterAttributeAffine?


    // MARK: PGLAttributeUI protocol

    required init?(pglFilter: PGLSourceFilter, attributeDict: [String : Any], inputKey: String) {

        super.init(pglFilter: pglFilter, attributeDict: attributeDict, inputKey: inputKey)
        attributeDisplayName = "Scale"
        attributeName = attributeDisplayName! + attributeName!
        attributeType = AttrType.Position.rawValue
        // attributeName is index for parm controls must be unique

    }

    func affine(parent: PGLFilterAttributeAffine) {
        affineParent = parent
    }

    override func incrementValueDelta()  {
         affineParent?.incrementValueDelta()
              postUIChange(attribute: self)

    }
    override func set(_ value: Any) {
        if let newVector = value as? CIVector {

        let scaledValue = scaleVector(inputVector: newVector, scaleBy: scaler, divideScale: true)
        // divide by 1000 from the UI

        affineParent?.setScale(vector: scaledValue)
        }
    }

    override  func getValue() -> Any? {
        let parentVector = affineParent?.translate ?? CIVector(cgPoint: CGPointZero)

        let uiVector = scaleVector(inputVector: parentVector, scaleBy: scaler, divideScale: false)
        // multiply by 1000 for the UI
        return uiVector
    }

//    override func getVectorValue() -> CIVector? {
//        return scale
//    }

    override func okActionToSetValue() -> Bool {
        return false
    }

    override func restoreOldValue() {
        // empty for now
    }

    override func moveTo(startPoint: CGPoint, newPoint: CGPoint, inView: UIView) {
        // map back to flipped vertical
        // this can be deleted.. moveTo... not called
        let flippedVertical = inView.bounds.height - newPoint.y
        let newVector = CIVector(x: newPoint.x, y: flippedVertical)
        self.set(newVector)
    }

    override  func movingChange(startPoint: CGPoint, newPoint: CGPoint, inView: UIView) {
//        NSLog("PGLTranslateAffineUI movingChange: startPoint = \(startPoint) newPoint = \(newPoint)")
        let flippedVertical = inView.bounds.height - newPoint.y
        let newVector = CIVector(x: newPoint.x, y: flippedVertical)
//        NSLog("PGLTranslateAffineUI movingChange set \(newVector)")
        self.set(newVector)
    }

    override  func movingCorner(atCorner: Vertex, startPoint: CGPoint, newPoint: CGPoint) {
        // do nothing
    }

    override   func attributeUIType() -> AttrUIType {
        return AttrUIType.pointUI
    }

    override    func isSliderUI() -> Bool {
        return false
    }

    override  func isPointUI() -> Bool {
        return true
    }

    override func isImageUI() -> Bool {
        return false
    }

    override func isRectUI() -> Bool {
        return false
    }

    override  func isImageInput() -> Bool {
        return false
    }

    override  func isBackgroundImageInput() -> Bool {
        return false
    }

    override  func updateFromInputStack() {
        affineParent?.updateFromInputStack()
    }

    override func isSingluar() -> Bool {
        return affineParent?.isSingluar() ?? true
    }


    // MARK: Affine Value set


}

class PGLTimerRateAttributeUI: PGLFilterAttribute {
    // provides control for the animation rate of change to parent var delta
    // support Vary, Cancel, OK swipeActions

    var timerParent: PGLFilterAttribute?  // maybe the parent should be the varying
    let defaultDt: Double = 2.000 // was 0.005

    // MARK: PGLAttributeUI protocol
    required init?(pglFilter: PGLSourceFilter, attributeDict: [String : Any], inputKey: String) {

        super.init(pglFilter: pglFilter, attributeDict: attributeDict, inputKey: inputKey)
        attributeDisplayName = "Rate"
        attributeName = attributeDisplayName! + attributeName!
        attributeType = AttrType.Scalar.rawValue
        // attributeName is index for parm controls must be unique

            // Interface Builder slider max attribute controls these setting
        sliderMaxValue = 30.0
        sliderMinValue = 0.0
        defaultValue = 2.0
        identityValue = 0.0
        indentLevel = 1
    }

    override func uiCellIdentifier() -> String {
     // uncomment this to have the number slider appear in the parm cell
     // otherwise it appears in the image
            return  "parmSliderInputCell"
        }

    func filterAttribute(parent: PGLFilterAttribute) {
        timerParent = parent
    }

    override func varyTimerAttribute() -> PGLFilterAttribute? {
        return nil // timer is implemention of vary does not directly vary..
    }

    override func set(_ value: Any) {
//        NSLog("PGLTimerRateAttributeUI #set value = \(value)")
        if let newRate = value as? Float {

            timerParent?.setAnimationTimerDt(lengthSeconds: newRate ) // was newRate / 100
        }
    }
    
//    override func valueString() -> String {
//        let parmNumber = getTimerDt() * 1000
//
//        return String(format: "%.02f", parmNumber)
//    }
    

    override  func getValue() -> Any? {
        // remove obsolete?
        return timerParent?.getTimerDt() ?? defaultDt
    }

    override func okActionToSetValue() -> Bool {
        return false
    }

    override func restoreOldValue() {
        // empty for now
    }

    override func moveTo(startPoint: CGPoint, newPoint: CGPoint, inView: UIView) {
        // do nothing
    }

    override  func movingChange(startPoint: CGPoint, newPoint: CGPoint, inView: UIView) {
        // do nothing
    }

    override  func movingCorner(atCorner: Vertex, startPoint: CGPoint, newPoint: CGPoint) {
        // do nothing
    }

    override   func attributeUIType() -> AttrUIType {
        return AttrUIType.timerSliderUI
    }

    override    func isSliderUI() -> Bool {
        return true
    }

    override  func isPointUI() -> Bool {
        return false
    }

    override func isImageUI() -> Bool {
        return false
    }

    override func isRectUI() -> Bool {
        return false
    }

    override  func isImageInput() -> Bool {
        return false
    }

    override  func isBackgroundImageInput() -> Bool {
        return false
    }

    override  func updateFromInputStack() {
      // do nothing
    }

    override func isSingluar() -> Bool {
       return true // but should not be relevant
    }

    // MARK: Affine Value set
}

class PGLNewFilterUI: PGLFilterAttribute {
    // provides cell to add new filter chain as input
    // not used delete replaced by the swipe command
    var inputParent: PGLFilterAttribute?  // maybe the parent should be the varying


    // MARK: PGLAttributeUI protocol
    required init?(pglFilter: PGLSourceFilter, attributeDict: [String : Any], inputKey: String) {

        super.init(pglFilter: pglFilter, attributeDict: attributeDict, inputKey: inputKey)
        attributeDisplayName = "Add-"
        attributeName = attributeDisplayName! + attributeName!
        attributeType = AttrType.Image.rawValue

        // attributeName is index for parm controls must be unique


    }

    func filterAttribute(parent: PGLFilterAttribute) {
        inputParent = parent
    }

    override func uiCellIdentifier() -> String {
        return  "ImageNewFilterInput"
    }


}

class PGLVectorNumeric3UI: PGLFilterAttribute {
    // provides control for the Number changes to zDim
    // support Vary, Cancel, OK swipeActions

    var zValueParent: PGLFilterAttributeVector3?
    let defaultZValue: Double = 0.0

    // MARK: PGLAttributeUI protocol
    required init?(pglFilter: PGLSourceFilter, attributeDict: [String : Any], inputKey: String) {

        super.init(pglFilter: pglFilter, attributeDict: attributeDict, inputKey: inputKey)
        attributeDisplayName = "zValue"
        attributeName = attributeDisplayName! + attributeName!
        attributeType = AttrType.Scalar.rawValue
        // attributeName is index for parm controls must be unique

        // Interface Builder slider max attribute controls these setting
        sliderMaxValue = 1000.0
        sliderMinValue = 0.0
        defaultValue = 0.0
        identityValue = 0.0
        indentLevel = 1
    }

//    override func uiCellIdentifier() -> String {
//        // implement this to have the number slider appear in the parm cell
//        // otherwise it appears in the image
//      return  "parmSliderInputCell"
//    }

    override  func setUICellDescription(_ uiCell: UITableViewCell) {
      var content = uiCell.defaultContentConfiguration()
      let newDescriptionString = self.attributeName ?? ""
      content.text = newDescriptionString
      content.imageProperties.tintColor = .secondaryLabel
        content.image = UIImage(systemName: "plus.circle")

      uiCell.contentConfiguration = content

    }

    func filterAttribute(parent: PGLFilterAttribute) {
        zValueParent = parent as? PGLFilterAttributeVector3
    }

//    override func varyTimerAttribute() -> PGLFilterAttribute? {
//        return nil // timer is implemention of vary does not directly vary..
//    }

    override func set(_ value: Any) {
        //        NSLog("PGLTimerRateAttributeUI #set value = \(value)")
        if let newZ = (value as? NSNumber)?.doubleValue {

            zValueParent?.zValue = CGFloat( newZ)
            zValueParent?.set3ValueVector(CGFloat(newZ))
        }
    }

    override  func getValue() -> Any? {
        let vector3 =  zValueParent?.getVectorValue()
        return vector3?.z
    }

    override func valueString() -> String {
        // sets format used by the cell.detailTextLabel.text
        if let parmNumber = (getValue() as? NSNumber)?.doubleValue
        {return String(format: "%.03f", parmNumber) }
        else { return ""}
    }

    override func okActionToSetValue() -> Bool {
        return false
    }

    override func restoreOldValue() {
        // empty for now
    }

    override func moveTo(startPoint: CGPoint, newPoint: CGPoint, inView: UIView) {
        // do nothing
    }

    override  func movingChange(startPoint: CGPoint, newPoint: CGPoint, inView: UIView) {
        // do nothing
    }

    override  func movingCorner(atCorner: Vertex, startPoint: CGPoint, newPoint: CGPoint) {
        // do nothing
    }

    override   func attributeUIType() -> AttrUIType {
        return AttrUIType.integerUI
    }

    override    func isSliderUI() -> Bool {
        return true
    }

    override  func isPointUI() -> Bool {
        return false
    }

    override func isImageUI() -> Bool {
        return false
    }

    override func isRectUI() -> Bool {
        return false
    }

    override  func isImageInput() -> Bool {
        return false
    }

    override  func isBackgroundImageInput() -> Bool {
        return false
    }

    override  func updateFromInputStack() {
        // do nothing
    }

    override func isSingluar() -> Bool {
        return true // but should not be relevant
    }

    // MARK: Affine Value set
}
