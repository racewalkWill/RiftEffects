//
//  PGLFilterAttributeNumber.swift
//  Glance
//
//  Created by Will on 4/1/19.
//  Copyright © 2019 Will. All rights reserved.
//

import Foundation

import UIKit
import Photos
import CoreImage

class PGLFilterAttributeNumber: PGLFilterAttribute {
    override var animationTime: Float?  {
        didSet {
            if let animatedNumericValue =  self.getNumberValue() as? Float //
            { if oldValue == nil {
                initialAnimationValue = animatedNumericValue // this assumes NSNumber type attribute
                }
                // now increment value
                if animationTime != nil {

                    let animatedDelta = initialAnimationValue * animationTime! // makes delta a ratio of the initialValue
                    let newValue = initialAnimationValue + animatedDelta
//                    newValue = min(sliderMaxValue ?? 500.0, newValue)
//                    newValue = max(sliderMinValue ?? -500.0, newValue)
//                             NSLog("animationTime = \(animationTime), initialAnimationValue = \(initialAnimationValue), animatedDelta = \(animatedDelta), newValue = \(newValue)")
                   

                    aSourceFilter.setNumberValue(newValue: newValue as NSNumber, keyName: attributeName!)
                    postUIChange(attribute: self)
                }
            }
        }
    }

    required init?(pglFilter: PGLSourceFilter, attributeDict: [String:Any], inputKey: String ) {
        super.init(pglFilter: pglFilter, attributeDict: attributeDict, inputKey: inputKey)


    }

    override func set(_ value: Any) {
         if attributeName != nil {
            aSourceFilter.setNumberValue(newValue: value as! NSNumber, keyName: attributeName!)
        }
    }

    override func valueString() -> String {
        let parmNumber = getValue() as! Double
        // could use getNumberValue() to avoid a generic..
//        NSLog("PGLFilterAttributeNumber #valueString has value \(parmNumber)")
        return String(format: "%.03f", parmNumber)
    }


}
class PGLFilterAttributeTime: PGLFilterAttribute {

    let timeDivisor:Double = 100.0

    required init?(pglFilter: PGLSourceFilter, attributeDict: [String:Any], inputKey: String ) {
        super.init(pglFilter: pglFilter, attributeDict: attributeDict, inputKey: inputKey)
        sliderMaxValue = 10 // seconds per image
        sliderMinValue = 0.001 // seconds per image - this is 100 images/second
        defaultValue = 0.005

    }

    override func set(_ value: Any) {
        let newRate = (value as! NSNumber).doubleValue
        setTimerDt(rate: newRate / timeDivisor )
    }

    override func valueString() -> String {
        let parmNumber = getTimerDt() * timeDivisor

        return String(format: "%.03f", parmNumber)
    }

    override func cellAction() -> [PGLTableCellAction ] {
        return [PGLTableCellAction ]()  // no action on time
    }

    override func uiCellIdentifier() -> String {
        // change back to superclass answer if vary is needed
        // super class uses "parmNoDetailCell"
        return "parmNoDisclosureCell"
    }


}

class PGLFilterAttributeVector: PGLFilterAttribute {
    // value of the vector attribute is the current point of the filter
    // three vars must be set to do vector panning
    // animationTime, startPoint & endPoint
    var vectorLength:Float = 0.0
    var vectorAngle:Float = 0.0  //radians
    var vectorSin: Float = 0.0
    var vectorCos: Float = 0.0
    var xSign: Float = 1.0
    var xDelta: Float = 0.0
    var startPoint: CIVector?
    var endPoint: CIVector? {
        didSet {  // setting the endpoint implies that startPoint is the current position
            if let newPoint = endPoint {
//            startPoint = getVectorValue()
            let xSqr = pow((newPoint.x - startPoint!.x), 2.0)
            let ySqr = pow ((newPoint.y - startPoint!.y), 2.0)
            vectorLength =  sqrtf( Float(xSqr + ySqr) )
            vectorAngle = asin(Float((newPoint.y - startPoint!.y))/vectorLength )
            vectorCos = cos(vectorAngle)
            vectorSin = sin(vectorAngle)
            xDelta = Float(newPoint.x - startPoint!.x)
            if xDelta < 0.0 { xSign = -1.0 } // avoid NAN error from sign function if xDelta is zero
            }
            else { startPoint = nil}
        }
    }



    override var animationTime: Float?  {
        // animation time range 0.0 to 1.0
        didSet {
            if (endPoint != nil) && (animationTime != nil) && (startPoint != nil ){

                let distanceTime = abs(vectorLength * animationTime!)
                    // for this change the animation time must be 0..1.0 range positive
                    // sender has -1.0...+1.0 range

                let newX = Float(startPoint!.x) + (xSign * (vectorCos * distanceTime))
                let newY = Float(startPoint!.y) + (vectorSin * distanceTime)
                let newVector = CIVector(x: CGFloat(newX), y: CGFloat(newY))
                aSourceFilter.setVectorValue(newValue: newVector, keyName: attributeName!)
                postUIChange(attribute: self)
            }
        }
    }

    required init?(pglFilter: PGLSourceFilter, attributeDict: [String:Any], inputKey: String ) {
        super.init(pglFilter: pglFilter, attributeDict: attributeDict, inputKey: inputKey)


    }

    func setVectorEndPoint() {
        if startPoint != nil
           {endPoint = getVectorValue() }
    }
    func setVectorStartPoint(){
        startPoint = getVectorValue()
    }
    // Vary action on UI.. set the vector move start point

    func endVectorPan() {
        startPoint = nil
        endPoint = nil
    }
    override func set(_ value: Any) {
        if attributeName != nil {
            aSourceFilter.setVectorValue(newValue: value as! CIVector, keyName: attributeName!)
        }
    }

    // MARK: Swipe actions Vector
    fileprivate func addCancelAction(_ allActions: inout [PGLTableCellAction]) {
        // point 1 &/or point 2 set so allow Cancel
        let cancelVaryAction = PGLTableCellAction(action: "Cancel", newAttribute: nil, canPerformAction: true, targetAttribute: self)
        allActions.append(cancelVaryAction)

    }

    override func cellAction() -> [PGLTableCellAction] {
        // Vary needs start point and end point set
        // state1 - Initial - actions are 'From' point 1 or run DissolveWrapper on 'Faces' points
        // state2 - point1 is set - actions are 'To' point 2 & 'Cancel' back to state1
        // state3 - point1 & point2 set - animation is running. action is 'Cancel' back to state1
        // state4 - DissolveWrapper is running - 'Cancel' back to state 1
        var allActions = [PGLTableCellAction]()
        switch varyState {
            // calling method trailingSwipeAction... will change the varyState - user may not complete the swipe
            // varyState updated in the completion blocks in trailingSwipeAction of PGLSelectParmController
            case .Initial:
                if let newVaryAttribute = varyTimerAttribute() {
                    if !hasAnimation() { // add Point 1

                        let facesAction = PGLTableCellAction(action: "Faces", newAttribute: newVaryAttribute, canPerformAction: true, targetAttribute: self)
                        facesAction.performDissolveWrapper = true
                        allActions.append(facesAction)
                        let varyAction = PGLTableCellAction(action: "From", newAttribute: newVaryAttribute, canPerformAction: true, targetAttribute: self)
                                           allActions.append(varyAction)
                    }
            }
            case .VaryPt1:
                if hasAnimation() && (endPoint == nil) {
                    // animation timer is running for start point -
                    // endPoint is nil

                    let point2Action = PGLTableCellAction(action: "To", newAttribute: nil, canPerformAction: true, targetAttribute: self)
                    point2Action.performAction2 = true  //  will setVectorEndPoint in the method performAction2
                    allActions.append(point2Action)
                }
                addCancelAction(&allActions)


            case .VaryPt1Pt2:

                 addCancelAction(&allActions)
            case .DissolveWrapper:

                addCancelAction(&allActions)

        }

        return allActions
    }

    override  func performAction(_ controller: PGLSelectParmController?) {
//        if hasAnimation() { // animation is running so STOP
//            endVectorPan() }
//        else {
//            NSLog("PGLFilterAttributeVector #performAction does setVectorStartPoint")
//            setVectorStartPoint()
//            if varyState == .Initial {
//                varyState = .VaryPt1 // From point is set
//            }
//        }
//        super.performAction(controller)
//            // sends aSourceFilter.attribute(animateTarget: self)
        switch varyState {
            case .Initial:
                if !hasAnimation() {
                    setVectorStartPoint()
                    varyState = .VaryPt1
                    aSourceFilter.startAnimation(attributeTarget: self)
            }

            case .VaryPt1:
                if hasAnimation() {
                    endVectorPan()
                     varyState = .Initial
                } else {
                    // must be starting the vary in sender see performAction2
                   // varyState = .VaryPt1Pt2
                    // or is this setin performAction2?

            }
            case .VaryPt1Pt2:
                aSourceFilter.stopAnimation(attributeTarget: self)
                 varyState = .Initial


            case .DissolveWrapper:

//                aSourceFilter.stopAnimation(attributeTarget: self)
                // attribute targets for dissolve should be the dissolve wrapper input and target images??
                removeWrapperFilter()
                varyState = .Initial
        }

    }

    func removeWrapperFilter() {
        aSourceFilter.removeWrapperFilter()
    }

    override func performAction2(_ controller: PGLSelectParmController?) {

        // a new subUI cell was not added by the actionCells method
        setVectorEndPoint()
        if varyState == .VaryPt1 {
            varyState = .VaryPt1Pt2 // move to next state for both from and to points set
        }
    }
}

class PGLFilterAttributeVector3: PGLFilterAttributeVector {
    // has a 3d position of three points..
    // use the existing superclass for 2 points
    // add a slider for the third point in a subUI cell

    var zValue: CGFloat = 0.0

    required init?(pglFilter: PGLSourceFilter, attributeDict: [String:Any], inputKey: String ) {
        super.init(pglFilter: pglFilter, attributeDict: attributeDict, inputKey: inputKey)
        if let defaultVector = getVectorValue() {
            zValue = defaultVector.z
        }

    }
    override func valueInterface() -> [PGLFilterAttribute] {
        // subclasses such as PGLFilterAttributeAffine implement a attributeUI collection
        // single affine parm attribute needs three independent settings rotate, scale, translate

        var vectorUICells = super.valueInterface()
        if let parm3 = PGLVectorNumeric3UI(pglFilter: aSourceFilter, attributeDict: initDict, inputKey: attributeName!)
        {   parm3.zValueParent = self
            vectorUICells.append(parm3)
            return vectorUICells
        } else { return vectorUICells }

}
    override func set(_ value: Any) {

        if attributeName != nil {
            if let newVector = value as? CIVector {
                set3ValueVector(newVector, newZValue: zValue) }

            }
        }

    func set3ValueVector(_ newXYvector: CIVector, newZValue: CGFloat) {
        // the XYvector is dragged to a new point.

            let newVector = CIVector(x: newXYvector.x, y: newXYvector.y, z: newZValue)
            aSourceFilter.setVectorValue(newValue: newVector, keyName: attributeName!)
    }

    func set3ValueVector(_ newZValue: CGFloat) {
        // when the zValue is the only change
        if let oldVector = getVectorValue() {
            let newVector = CIVector(x: oldVector.x, y: oldVector.y, z: newZValue)
             aSourceFilter.setVectorValue(newValue: newVector, keyName: attributeName!)
        }

        func getZValue() -> CGFloat {
            return getVectorValue()?.z ?? zValue
        }
        
    }

    override var animationTime: Float?  {
        // animation time range 0.0 to 1.0
        // must also set with a x,y,z vector
        // z component of the vector is not animated
        didSet {
            if (endPoint != nil) && (animationTime != nil) && (startPoint != nil ){

                let distanceTime = vectorLength * animationTime!

                let newX = Float(startPoint!.x) + (xSign * (vectorCos * distanceTime))
                let newY = Float(startPoint!.y) + (vectorSin * distanceTime)
                let newVector = CIVector(x: CGFloat(newX), y: CGFloat(newY), z: zValue)
                aSourceFilter.setVectorValue(newValue: newVector, keyName: attributeName!)
                postUIChange(attribute: self)
            }
        }
    }



}

