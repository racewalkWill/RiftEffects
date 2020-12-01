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



    required init?(pglFilter: PGLSourceFilter, attributeDict: [String:Any], inputKey: String ) {
        super.init(pglFilter: pglFilter, attributeDict: attributeDict, inputKey: inputKey)


    }

    override func set(_ value: Any) {
         if attributeName != nil {
            aSourceFilter.setNumberValue(newValue: value as! NSNumber, keyName: attributeName!)
        }
    }

    override func incrementValueDelta() {
        if let curentNumericValue =  self.getNumberValue() as? Float {

            // now increment value
            if  (attributeValueDelta != nil ){
                let newValue = curentNumericValue + attributeValueDelta!
//                NSLog("PGLFilterAttributeNumber incrementValueDelta didSet to newValue = \(newValue)")
               
                aSourceFilter.setNumberValue(newValue: newValue as NSNumber, keyName: attributeName!)
                postUIChange(attribute: self)
            }
        }
    }
    override func valueString() -> String {
        let parmNumber = getValue() as! Double
        // could use getNumberValue() to avoid a generic..
//        NSLog("PGLFilterAttributeNumber #valueString has value \(parmNumber)")
        return String(format: "%.03f", parmNumber)
    }

    override  func setUICellDescription(_ uiCell: UITableViewCell) {
      var content = uiCell.defaultContentConfiguration()
      let newDescriptionString = self.attributeName ?? ""
      content.text = newDescriptionString
      content.imageProperties.tintColor = .secondaryLabel
        content.image = UIImage(systemName: "slider.horizontal.below.rectangle")

      uiCell.contentConfiguration = content

    }

}
class PGLFilterAttributeTime: PGLFilterAttribute {
    // this attribute needs to send the slider set message
    // to the filter addStepTime.. in contrast to the vary logic which
    // uses the a frameCounter and frames per second to control the change in a
    // numeric or vector attribute

    let timeDivisor: Float = 25.0

    required init?(pglFilter: PGLSourceFilter, attributeDict: [String:Any], inputKey: String ) {
        super.init(pglFilter: pglFilter, attributeDict: attributeDict, inputKey: inputKey)
        sliderMaxValue = 10 // seconds per image
        sliderMinValue = 0.001 // seconds per image - this is 100 images/second
        defaultValue = 0.1

    }

    override func set(_ value: Any) {
       let newRate = (value as! NSNumber).floatValue
            //simd_smoothstep is not called here
            // see addStepTime on the Transition filter
        aSourceFilter.setTimerDt(lengthSeconds: newRate )

    }

    override func valueString() -> String {
        // remove obsolete?
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

    override  func setUICellDescription(_ uiCell: UITableViewCell) {
      var content = uiCell.defaultContentConfiguration()
      let newDescriptionString = self.attributeName ?? ""
      content.text = newDescriptionString
      content.imageProperties.tintColor = .secondaryLabel
        content.image = UIImage(systemName: "slider.horizontal.below.rectangle")

      uiCell.contentConfiguration = content

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
    var incrementDirection = 1 // changes sign on end of variation range 1 or -1
    var startPoint: CIVector?
    var endPoint: CIVector? {
        didSet {  // setting the endpoint implies that startPoint is the current position
            if let newPoint = endPoint {

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

            // reset the attributeValueDelta for the vectorLength
            // other classes use attributeValueDelta based on range of the slider
            // which does not apply here
            if (varyTotalFrames > 0 ) // check for zero division nan

            {
                attributeValueDelta = vectorLength / Float(varyTotalFrames)
            }
        }
    }





    required init?(pglFilter: PGLSourceFilter, attributeDict: [String:Any], inputKey: String ) {
        super.init(pglFilter: pglFilter, attributeDict: attributeDict, inputKey: inputKey)
        if defaultValue == nil {

            var cornerPoint: CGPoint?
//            NSLog("PGLFilterAttributeVector does not have default")
            let insetRect = CGRect(x: 0, y: 0, width: TargetSize.width, height: TargetSize.height).insetBy(dx: 200.0, dy: 200.0)
            // assuming LLO here...
            // now trying ULO
            switch attributeName {
                case "inputTopLeft":
                   // cornerPoint = insetRect.origin  // ULO
                  cornerPoint = CGPoint(x: insetRect.origin.x, y: insetRect.maxY)  //LLO

                case "inputTopRight" :
//                    cornerPoint = CGPoint(x: insetRect.maxX, y: insetRect.origin.y) // ULO
                   cornerPoint = CGPoint(x: insetRect.maxX, y: insetRect.maxY)  //LLO

                case "inputBottomLeft":
//                    cornerPoint = CGPoint(x: insetRect.origin.x, y: insetRect.maxY) // ULO
                    cornerPoint = insetRect.origin //LLO

                case "inputBottomRight":
//                    cornerPoint = CGPoint(x: insetRect.maxX, y: insetRect.maxY) //ULO
                    cornerPoint = CGPoint(x: insetRect.maxX, y: insetRect.origin.y) //LLO 

                default:
                    break
            }
            if cornerPoint != nil {

                aSourceFilter.setVectorValue(newValue: CIVector(cgPoint: cornerPoint!), keyName: attributeName!)
//                let newValue = getVectorValue()
//                NSLog("PGLFilterAttributeVector set default of \(self) \(attributeName) to \(newValue)")
                
            }
        }


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

    override func performActionOff() {
        super.performActionOff()
        endVectorPan()
        attributeValueDelta = nil
            // stops animation

         varyState = .Initial
    }

    override  func setUICellDescription(_ uiCell: UITableViewCell) {
      var content = uiCell.defaultContentConfiguration()
      let newDescriptionString = self.attributeName ?? ""
      content.text = newDescriptionString
      content.imageProperties.tintColor = .secondaryLabel
        content.image = UIImage(systemName: "plus.circle")

      uiCell.contentConfiguration = content

    }

    // MARK: Swipe actions Vector
    fileprivate func addCancelAction(_ allActions: inout [PGLTableCellAction]) {
        // point 1 &/or point 2 set so allow Cancel
        let cancelVaryAction = PGLTableCellAction(action: "Cancel", newAttribute: nil, canPerformAction: true, targetAttribute: self)
        allActions.append(cancelVaryAction)

    }

    override  func addStepTime() {
        // called on every frame
        // if animationTime is nil then animation is not running
        // adds the delta value (currentDt) to the parm

        if !hasAnimation() { return }  // animationTime is Float

        if (varyStepCounter > varyTotalFrames) || (varyStepCounter < 0) {
//          NSLog("PGLFilterAttribute addStepTime resetting from varyStepCounter = \(varyStepCounter)")
            // attributeValueDelta is not used for the vector increment
            incrementDirection = incrementDirection * -1
            if attributeValueDelta != nil
                { attributeValueDelta = attributeValueDelta! * -1 }
            }
        // now add the step

        varyStepCounter += incrementDirection
            // variationSteo not nil see hasAnimation() guard above
        incrementValueDelta()


    }

    override func incrementValueDelta() {
        // animation time range 0.0 to 1.0
        if !hasAnimation() {return }

        if (endPoint != nil)  && (startPoint != nil ){
//            let currentPoint = getVectorValue()
            // old animationTime is a value moving from -1 to +1
            let changeRatio: Float = Float(varyStepCounter) / Float(varyTotalFrames)
            let distanceOfIncrement = vectorLength * changeRatio


            let newX = Float(startPoint!.x) + (xSign * (vectorCos * distanceOfIncrement))
            let newY = Float(startPoint!.y) + (vectorSin * distanceOfIncrement)
            let newVector = CIVector(x: CGFloat(newX), y: CGFloat(newY))
//            NSLog("PGLFilterAttributeVector #incrementValueDelta currentVector = \(String(describing: getVectorValue()))")
//            NSLog("PGLFilterAttributeVector #incrementValueDelta newVector = \(newVector)")
            aSourceFilter.setVectorValue(newValue: newVector, keyName: attributeName!)
            postUIChange(attribute: self)
        }

    }
    override func setTimerDt(lengthSeconds: Float){
         // user has moved the rate of change control
         // value is 0...30
         // real step timing varies from min to max  from 0 sec to 30 sec
         // see #addStepTime() in #outputImage()
         // set the variationStep value
         // set the attributeValueDelta for change in each stop

         if vectorLength <=  0 { return } // end point for vectorlength must be set first

         let framesPerSec: Float = 60.0 // later read actual framerate from UI
         varyTotalFrames = Int(framesPerSec * lengthSeconds)


     }
   

    override func cellAction() -> [PGLTableCellAction] {
        // Vary needs start point and end point set
        // state1 - Initial - actions are 'From' point 1 or run DissolveWrapper on 'Faces' points
        // state2 - point1 is set - actions are 'To' point 2 & 'Cancel' back to state1
        // state3 - point1 & point2 set - animation is running. action is 'Cancel' back to state1
        //          rateUI subcell appears and sets initial rate
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
                        let varyAction = PGLTableCellAction(action: "From", newAttribute: nil , canPerformAction: true, targetAttribute: self)
                                           allActions.append(varyAction)
                    }
            }
            case .VaryPt1:
                if  (endPoint == nil) {

                    // endPoint is nil
                    if let newVaryAttribute = varyTimerAttribute(){
                    let point2Action = PGLTableCellAction(action: "To", newAttribute: newVaryAttribute, canPerformAction: true, targetAttribute: self)
//                    point2Action.performAction2 = true  //  will setVectorEndPoint in the method performAction2
                    allActions.append(point2Action)
                    }
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
                    setVectorStartPoint()
                    varyState = .VaryPt1
//                    aSourceFilter.startAnimation(attributeTarget: self)


            case .VaryPt1:

                setVectorEndPoint()
                aSourceFilter.startAnimation(attributeTarget: self)

                varyState = .VaryPt1Pt2 // move to next state for both from and to points set
//                if hasAnimation() { Makes cancel work if animation is running
//                    endVectorPan()
//                    attributeValueDelta = nil
//                        // stops animation
//
//                     varyState = .Initial
//                } else {
                    // must be starting the vary in sender see performAction2
                   // varyState = .VaryPt1Pt2
                    // or is this setin performAction2?

//            }
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

    override func performAction2(_ controller: PGLSelectParmController?) {

        // a new subUI cell was not added by the actionCells method
//        setVectorEndPoint()
        if varyState == .VaryPt1 {
            varyState = .VaryPt1Pt2 // move to next state for both from and to points set
            // set UI vary values
            setTimerDt(lengthSeconds: 5.0)

        }
    }

    func removeWrapperFilter() {
        aSourceFilter.removeWrapperFilter()
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

    override func incrementValueDelta()  {
        // animation time range 0.0 to 1.0
        // must also set with a x,y,z vector
        // z component of the vector is not animated

            if (endPoint != nil)  && (startPoint != nil ){

                let distanceTime = vectorLength * attributeValueDelta!

                let newX = Float(startPoint!.x) + (xSign * (vectorCos * distanceTime))
                let newY = Float(startPoint!.y) + (vectorSin * distanceTime)
                let newVector = CIVector(x: CGFloat(newX), y: CGFloat(newY), z: zValue)
                aSourceFilter.setVectorValue(newValue: newVector, keyName: attributeName!)
                postUIChange(attribute: self)
            }
        }




}

