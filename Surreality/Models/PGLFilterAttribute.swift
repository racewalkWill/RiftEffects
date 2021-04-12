//
//  PGLFilterAttribute.swift
//  PictureGlance
//
//  Created by Will on 8/19/17.
//  Copyright © 2017 Will Loew-Blosser All rights reserved.
//

import Foundation
import UIKit
import Photos
import CoreImage
import Accelerate

enum AttrClass: String {
    case Color = "CIColor"
    case Number = "NSNumber"
    case Vector = "CIVector"
    case Image = "CIImage"
    case Data =  "NSData"
    case Value = "NSValue"
    case Object = "NSObject"
    case String = "NSString"
    case AttributedString = "NSAttributedString"
}

enum AttrType: String {
    case Rectangle = "CIAttributeTypeRectangle"
    case Image = "CIAttributeTypeImage"
    case Scalar = "CIAttributeTypeScalar"
    case Position = "CIAttributeTypePosition"
    case Distance = "CIAttributeTypeDistance"
    case Angle = "CIAttributeTypeAngle"
    case Color = "CIAttributeTypeColor"
    case Time = "CIAttributeTypeTime"
    case Offset = "CIAttributeTypeOffset"
    case OpaqueColor =  "CIAttributeTypeOpaqueColor"
    case Position3 = "CIAttributeTypePosition3"
    case TypeCount = "CIAttributeTypeCount"
    case Transform = "CIAttributeTypeTransform"
    case Boolean = "CIAttributeTypeBoolean"
    case Gradient = "CIAttributeTypeGradient"

}

enum AttrUIType {

    case pointUI
    case rectUI
    case sliderUI
    case imagePickUI
    case filterPickUI
    case integerUI
    case timerSliderUI
    case textInputUI
    case fontUI

}

enum VaryDissolveState {
    // state1 - Initial - actions are 'From' point 1 or run DissolveWrapper on 'Faces' points
    // state2 - VaryPt1 point1 is set - actions are 'To' point 2 & 'Cancel' back to state1
    // state3 - VaryPt1Pt2 point1 & point2 set - animation is running. action is 'Cancel' back to state1
    // state4 - DissolveWrapper is running - 'Cancel' back to state 1
    case Initial
    case VaryPt1
    case VaryPt1Pt2
    case DissolveWrapper
}


class PGLFilterAttribute {

    static let FlowChartSymbol = UIImage(systemName: "flowchart")
    static let PhotoSymbol = UIImage(systemName: "photo.on.rectangle")
    static let PhotoSymbolSingle = UIImage(systemName: "photo")
    static let PriorFilterSymbol = UIImage(systemName: "square.and.arrow.down.on.square")
    static let MissingPhotoInput = UIImage(systemName: "rectangle") // looks empty...
    static let CurrentStackSymbol = UIImage(systemName: "square.stack.3d.up.fill")
    static let ChildStackSymbol = UIImage(systemName: "bubble.middle.top")
    static let ParentStackSymbol = UIImage(systemName: "arrow.down.doc")
    static let TopStackSymbol = UIImage(systemName: "arrow.down.doc")
            // or
                //    doc.plaintext
                //    Arrow.up.doc
                //    Arrow.down.doc
                //    Bubble.middle.top
                //    Sidebar.squares.leading
                //    Square.stack.3d.up
                //    List.bullet.indent

   @objc var myFilter: CIFilter {
        didSet {
             self.aSourceFilter.localFilter = myFilter // keep the two refs to the filter aligned
        }
    }
    var attributeName: String?
    var attributeDisplayName: String?
    var attributeType: String?
    var attributeClass: String?
    var classForAttribute: AnyClass?
    var attributeDescription: String?
    var minValue: Float?
    var sliderMinValue: Float?
    var sliderMaxValue: Float?
    var defaultValue: Float?
    var identityValue: Float?
    var attributeStartValue: Float!
    var attributeValueDelta: Float? // usually nil, when nil parent filter timer controls the rate of change
//    var attributeFrameDelta: Float = 0.0
    var varyStepCounter = 0
    var varyTotalFrames = 600 // 10 secs @ 60 fps


    var uiIndexPath: IndexPath?

    var initDict = [String:Any]()

    var inputCollection: PGLImageList? {
    // more general either ImageList or FilterList  why not incrment a set of filters too?
        didSet {
            if oldValue != nil {
                // delete the old stored imageList
                aSourceFilter.removeOldImageList(imageParmName: attributeName!)
//                if let oldStoredList = aSourceFilter.getImageList(imageParmName: attributeName!) {
//                    aSourceFilter.storedFilter?.removeFromImages(oldStoredList)
//                NSLog("PGLFilterAttribute inputCollection changed.. old stored value removed") }


            }
        }
    }


     unowned var aSourceFilter: PGLSourceFilter
    // This holds the real ciFilter in via the var PGLSourceFilter.localFilter
    // but attribute also holds the real ciFilter in myFilter var

    //    var keyPathString = \PGLFilterAttribute.myFilter.inputSaturation
    //    ReferenceWritableKeyPath<PGLFilterAttribute, Any>
    // add attributeMin, Max and Identity? They are strings in the dict.. need conversion to floating Point

    var inputSourceMetadata: PGLAsset? // photo or filter name used as input data store

    var inputStack: PGLFilterStack? {
        didSet{
            // assign the output of the child to the input of this attribute
            if inputStack != nil {
                self.set( inputStack?.stackOutputImage(false) as Any)
                    // false means use the final image in the child stack... BUT
                    // the child is being created so it is the dynamic output at runtime that is the input
                    // to this attribute.
                    // this is a problem...

                inputSourceDescription = inputStack?.stackName ?? "filterStack"
            }
        }
    }
        // typically an image output from a stack is the input to the attribute

    var inputSource: (source: PGLFilterStack, at: Int)?  // usually the filter that feeds to this input

    var inputSourceDescription: String? // inputCollection or childStack or.... shows on the title of the parm cell

        // really should only be a var on the subclass PGLFilterAttributeImage..
        // but assignment methods are in this superclass


    var indentLevel = 0
    var indentWidth: CGFloat = 30.0

    // default rate is .005 
//    let timeRateMininium: Double = 0.00001 // not used 2020-11-22  Remove
    var uiIndexTag:Int = 0 // used by color and maybe others?
    var varyState: VaryDissolveState = .Initial
    var hasFilterInput: Bool?
        // flag for parm description
        // nil before any input is set by the UI
        // PGLUserAssetSelection sets to false when images are selected
        // PGLFilterStack sets to true when filter input is set


  required init?(pglFilter: PGLSourceFilter, attributeDict: [String:Any], inputKey: String ) {
        initDict = attributeDict // save for creating valueParms such as PGLRotateAffineUI
        myFilter = pglFilter.localFilter
        aSourceFilter = pglFilter
        attributeType = attributeDict[kCIAttributeType] as? String
        attributeClass = attributeDict[kCIAttributeClass] as? String
        attributeDisplayName = attributeDict[kCIAttributeDisplayName] as? String
        attributeDescription = attributeDict[kCIAttributeDescription] as? String
        attributeName = inputKey
        minValue = attributeDict[kCIAttributeMin] as? Float
        sliderMinValue = attributeDict[kCIAttributeSliderMin] as? Float
        sliderMaxValue = attributeDict[kCIAttributeSliderMax] as? Float
        defaultValue = attributeDict[kCIAttributeDefault] as? Float // this fails for affineTransform
        identityValue = attributeDict[kCIAttributeIdentity] as? Float // this fails for affineTransform

        if attributeClass != nil {
            classForAttribute = NSClassFromString(("Glance." + attributeClass!)) }
    
//        inputSourceDescription = attributeDisplayName ?? "blank"

//        keyPathString = \self.class + "." + "myFilter" + "." + attributeName
        }


    func movingCorner(atCorner: Vertex, startPoint: CGPoint, newPoint: CGPoint) {
           // implemented by rectangle subclass
       }

       // maybe subclassed if a attribute needs some special logic
       // knows the name of the attribute, the class and the type
       // hold ref to the filter, gets and sets the attribute values into the filter
       // this is the data object for a table cell row of filter attributes
       // PGLSourceFilter holds these.. subclass of  PGLSourceFilter if filter specific logic needed across multiple attributes
       // i.e. if constraints exist between attributes the PGLSourceFilter implements the filter as a subclass

       class func parmClass(parmDict: [String : Any ]) -> PGLFilterAttribute.Type {
           // based upon the attribute kCIAttributeClass value use this class
           // provides creation of correct subclass for the attribute

           let attributeTypeString = parmDict[kCIAttributeType] as? String
           let parmClassString = parmDict[kCIAttributeClass] as? String

           if parmClassString != nil {
                // many filter attributes do not have a value for the class string.. be careful with nil check!
               switch parmClassString!{
                   case AttrClass.Color.rawValue:
                       return PGLFilterAttributeColor.self

                   case  AttrClass.Number.rawValue :
                       switch attributeTypeString {
                           case AttrType.Angle.rawValue:
                               return PGLFilterAttributeAngle.self
                           case AttrType.Time.rawValue:
                               return PGLFilterAttributeTime.self
                           default:
                               return PGLFilterAttributeNumber.self
                       }

                   case AttrClass.Vector.rawValue  :
                       switch attributeTypeString {
                           case AttrType.Rectangle.rawValue:
                               return PGLAttributeRectangle.self
                       case AttrType.Position3.rawValue:
                               return PGLFilterAttributeVector3.self
                       default: return PGLFilterAttributeVector.self
                       }

                   case AttrClass.Image.rawValue :
                       return PGLFilterAttributeImage.self

                  case  AttrClass.Data.rawValue  :
                        return PGLFilterAttributeData.self

                   case AttrClass.Value.rawValue  :
                       if attributeTypeString == AttrType.Transform.rawValue
                           {  return PGLFilterAttributeAffine.self }
                       else { return PGLFilterAttribute.self }

                   case AttrClass.Object.rawValue  :
                       return PGLFilterAttribute.self

                   case  AttrClass.String.rawValue :
                       return PGLFilterAttributeString.self

                case AttrClass.AttributedString.rawValue :
                    return PGLFilterAttributeAttributedString.self

                   default: return PGLFilterAttribute.self
               }
           } else {return PGLFilterAttribute.self}
       }


    func postUIChange(attribute: PGLFilterAttribute) {
        let uiNotification = Notification(name:PGLAttributeAnimationChange, object: attribute,userInfo: nil)

        NotificationCenter.default.post(uiNotification)
    }

    func isTransitionFilter() -> Bool {
        // answer true if the filter is in the "CICategoryTransition" category
        return aSourceFilter.isTransitionFilter()
    }
    func setUICellDescription(_ uiCell: UITableViewCell) {
        uiCell.textLabel?.text = attributeDisplayName ?? ""

        if let cellSlider = uiCell as?  PGLTableCellSlider {
            cellSlider.showTextValueInCell()
        }
        else {
//            NSLog("PGLFilterAttribute #setUICellDescription \(uiCell.textLabel!.text)")
            uiCell.detailTextLabel?.text = valueString()
//            NSLog("PGLFilterAttribute #setUICellDescription detailTextLabel.text = \(uiCell.detailTextLabel?.text)")
        }
        uiCell.indentationLevel = indentLevel  // subclasses such as timer will indent parm
    }

    func descriptiveNameDetail() -> String {
        return (attributeDisplayName ?? "parm" ) //  + " " + (attributeDescription ?? "")
    }

    // MARK: image Collection input

    func setImageCollectionInput(cycleStack: PGLImageList) {
        let firstAsset = cycleStack.imageAssets.first
        setImageCollectionInput(cycleStack: cycleStack, firstAssetData: firstAsset)
        
    }

    func setImageCollectionInput(cycleStack: PGLImageList, firstAssetData: PGLAsset?) {
        inputCollection = cycleStack
        inputSourceMetadata = firstAssetData  // provides description titles - optional

        inputCollection?.inputStack = inputStack // keep these aligned
        inputSourceDescription = cycleStack.collectionTitle

        aSourceFilter.setImageValue(newValue: (cycleStack.first()!), keyName: attributeName!)
        aSourceFilter.setImageListClone(cycleStack: cycleStack, sourceKey: attributeName!)
                    // Filter implementation is empty..
        setImageParmState(newState: ImageParm.inputPhoto)

        aSourceFilter.postImageChange()
    }

    func setTargetAttributeOfUserAssetCollection() {
        // if an inputCollection has a userAssetCollection
        // set it's targetFilterAttribute to self
        inputCollection?.userSelection?.myTargetFilterAttribute = self
    }

    func updateFromInputStack() {
        // if there is a child stack then get the current output as the input to this attribute
        if inputStack != nil {
            self.set( inputStack?.stackOutputImage(false) as Any)
        }
    }

    func setImageParmState(newState: ImageParm) {
        // empty implementation in the superclass
        // see PGLFilterAttributeImage

    }

// MARK: flattened Filters
    func stackRowCount() -> Int {
       return inputStack?.stackRowCount() ?? 0
    }

    func addChildFilters(_ level: Int, into: inout Array<PGLFilterIndent>) {
       inputStack?.addChildFilters(level  , into: &into)
    }

    // MARK: description
    var description: String {
        get {
            var outputString =  "attributeName= " + String(describing: attributeName)
            outputString = outputString + " attributeDisplayName= " + String(describing: attributeDisplayName)

            outputString = outputString + " attributeType=" + String(describing: attributeType)
            outputString = outputString + " attributeClass= " + String(describing:  attributeClass)
            outputString = outputString + " classForAttribute= " + String(describing:  classForAttribute)
            outputString = outputString + " attributeDescription= " + String(describing:  attributeDescription)
            outputString = outputString + " minValue= " + String(describing:  minValue)
            outputString = outputString + " sliderMinValue= " + String(describing: sliderMinValue)
            outputString = outputString + " sliderMaxValue= " + String(describing: sliderMaxValue)
            outputString = outputString + " defaultValue= " + String(describing: defaultValue)
            outputString = outputString + " identityValue= " + String(describing: identityValue)
            return outputString
        }
    }

    func uiCellIdentifier() -> String {

        return  "parmNoDetailCell"
    }

    func getSourceDescription(imageType: ImageParm) -> String {
        return inputSourceDescription ?? ""

//        var answerDescription: String
//        switch imageType {
//        case .photo:
//             answerDescription = ParmInput.Photo.rawValue  // "Photo"
//        case .filter:
//            answerDescription = ParmInput.Filter.rawValue // "Filter"
//
//        }
//       answerDescription = answerDescription + " " + inputSourceDescription
//        return answerDescription
    }

    func hasImageInput() -> Bool? {
        // super class this is not defined
        // only imageAttribute should answer true/false
        return nil
    }

    func inputParmType() -> ImageParm {
        // superclass default
        // see PGLFilterAttributeImage for real implementation

        return ImageParm.notAnImageParm

    }

    func getInputThumbnail(dimension: CGFloat = 200.0 ) -> UIImage{
        if hasFilterStackInput() || isImageInput() {
            if  let ciInput = getImageValue() {

                // output image in thumbnail size
                let magicNum: CGFloat  = dimension  // 44.0 numerator for ratio to max dimension of the image

                let uiOutput = UIImage(ciImage: ciInput )

                let outputSize = uiOutput.size
                //        let outputFrame = outputImage.extent
                var ratio: CGFloat = 0
                ratio = magicNum / max(outputSize.width, outputSize.height)

                let smallSize = CGSize(width: (ratio * outputSize.width), height: (ratio * outputSize.height))
                let smallRect = CGRect(origin: CGPoint.zero, size: smallSize)

                UIGraphicsBeginImageContext(smallSize)
                uiOutput.draw(in: smallRect)
                let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                return thumbnail ?? UIImage()
                }
        }
        return UIImage()
    }

    func hasFilterStackInput() -> Bool {
        return inputStack != nil

    }

    func valueString() -> String {
        // subclasses such as number will restrict the number of decimial places
        return String(describing: (getValue() ?? "") )
    }

    // MARK: value change
    func set(_ value: Any ) {
        // use a system of double dispatch to address typing
        //
        if attributeName != nil {

            switch attributeClass! {
                //  moved to subclass ..Image               case  AttrClass.Image.rawValue : aSourceFilter.setImageValue(newValue: value as! CIImage, keyName: attributeName!)
                //                case  AttrClass.Number.rawValue : aSourceFilter.setNumberValue(newValue: value as! NSNumber, keyName: attributeName!)
                // Number case usually in subclass PGLFilterAttributeNumber method

            case AttrClass.Vector.rawValue : aSourceFilter.setVectorValue(newValue: value as! CIVector, keyName: attributeName!)
                // vector case usually in subclass PGLFilterAttributeVector but Flash uses rectangle extent
            //                case AttrClass.Color.rawValue : aSourceFilter.setColorValue(newValue: value as! CIColor, keyName: attributeName!)
            case  AttrClass.Data.rawValue : aSourceFilter.setDataValue(newValue: value as! NSData, keyName: attributeName!)
            case  AttrClass.Value.rawValue : aSourceFilter.setNSValue(newValue: value as! NSValue, keyName: attributeName!)
            case  AttrClass.Object.rawValue : aSourceFilter.setObjectValue(newValue: value as! NSObject, keyName: attributeName!)
            case  AttrClass.String.rawValue : aSourceFilter.setStringValue(newValue: value as! NSString, keyName: attributeName!)

            default: fatalError("Error- can not set value for unknown filter attribute class in \(String(describing: attributeName))") // raises error on a new attribute class
            }
        }
    }

    func getValue() -> Any? {
    // use a system of double dispatch to address typing?
        
    // return myFilter.value(forKey: attributeName!) as!
    // this is interesting .. the return type matters in Swift.. I was thinking smalltalk..
    // for a generic getValue setValue we actually need subclasses of this class
    // required subclass implementation with different return types..
    // think about this
    var generic: Any? = nil
    if attributeName != nil {
         generic = myFilter.value(forKey: attributeName!)
        }
//        NSLog("PGLFilterAttribute #getValue generic = \(generic)")
    return generic
    }
    
    func getImageValue() -> CIImage? {
        return getValue() as? CIImage
    }
    
    func getNumberValue() -> NSNumber? {
        let filterValue =  getValue() as? NSNumber
//        NSLog("PGLFilterAttribute #getValue filterValue = \(filterValue)")
       return filterValue

    }
    
    func getVectorValue() -> CIVector? {
        return getValue() as? CIVector
    }
    
    func getColorValue() -> CIColor? {
        return getValue() as? CIColor
    }
    
    func getDataValue() -> NSData? {
        return getValue() as? NSData
    }
    
    func getNSValue() -> NSValue? {
        return getValue() as? NSValue
    }
    func getObjectValue() -> NSObject? {
        return getValue() as? NSObject
    }
    func getStringValue() -> NSString? {
        return getValue() as? NSString
    }
  
    func isImageInput() -> Bool {
        return (attributeClass == "CIImage") || (attributeType == kCIAttributeTypeImage)
    }
    
    func isBackgroundImageInput() -> Bool {
       return (attributeType == kCIAttributeTypeImage) && (attributeName == kCIInputBackgroundImageKey)
      
    }

    func isTimeTransition() -> Bool {
        // answer true if the attribute is for input time of a transition such as Dissolve
        return (attributeType == kCIAttributeTypeTime)
    }

    func mapPoint2Vector(point: CGPoint, viewHeight: CGFloat, scale: CGFloat) -> CIVector {
        // Upper Left Origin coord ULO point
        // vector in Lower Left coord  LLO

        let flippedVertical = viewHeight - point.y
            // is this the inverse func for vector2Point??
        let newVector = CIVector(x: point.x * scale , y: flippedVertical * scale )
        return newVector
    }

    func mapVector2Point(vector: CIVector, viewHeight: CGFloat, scale: CGFloat) -> CGPoint {
        // Upper Left Origin coord ULO point
        // vector in Lower Left coord  LLO
        let yPoint = ((vector.y / scale) - viewHeight) * -1.0
        // UNDO the flip from ULO to LLO
        let newPoint = CGPoint(x: (vector.x/scale) , y: yPoint)
//        let newPoint = CGPoint(x: vector.x , y: yPoint)
        return newPoint
    }

    func okActionToSetValue() -> Bool {
        // subclass override to true if set value is deferred to the OK action of the parm cell
        return false
    }
    
    // MARK: animation values

    func hasAnimation() -> Bool {
        return attributeValueDelta  != nil
    }

    func addStepTime() {
        // called on every frame
        // if animationTime is nil then animation is not running
        // adds the delta value (currentDt) to the parm

        if !hasAnimation() { return }  // animationTime is Float


        // adjust animationTime by the current dt
        if (varyStepCounter > varyTotalFrames)  {
//            NSLog("PGLFilterAttribute addStepTime resetting from varyStepCounter = \(varyStepCounter)")
            varyStepCounter = 0

            if attributeValueDelta != nil
                { attributeValueDelta = attributeValueDelta! * -1 }
            }
        // now add the step

        varyStepCounter += 1
            // variationSteo not nil see hasAnimation() guard above
        incrementValueDelta()


    }
    

    func setTimerDt(lengthSeconds: Float){
        // user has moved the rate of change control
        // value is 0...30
        // real step timing varies from min to max  from 0 sec to 30 sec
        // see #addStepTime() in #outputImage()
        // set the variationStep value
        // set the attributeValueDelta for change in each stop
        let framesPerSec: Float = 60.0 // later read actual framerate from UI
        varyTotalFrames = Int(framesPerSec * lengthSeconds)

        let attributeValueRange = (sliderMaxValue ?? 100.0) - (sliderMinValue ?? 0.0)
            // some filters do not define max or min values..

            // for total frames to increment to value
        if (varyTotalFrames > 0 ) // check for zero division nan
        {
            attributeValueDelta = attributeValueRange / Float(varyTotalFrames)
            // hasAnimation is now true with value in attributeValueDelta
        }
        else { attributeValueDelta = 0.0
                // keeps animation logic going but no changes in the attribute values
        }

        NSLog( "#setTimerDT attributeValueDelta = \(String(describing: attributeValueDelta))")
    }


    func getTimerDt() -> Float {
        return attributeValueDelta ?? 0.0
    }

    func incrementValueDelta() {
        // subclasses should override
        // see PGLFilterAttributeNumber for the numeric vary rate
    }
    func hasInputCollection() -> Bool {
        // more than one input image exists
        if let theSize = inputCollection?.sizeCount() {
            return theSize > 1
        }
        return false
    }

//    func hasUserAssetSelection() -> Bool {
//        if !hasInputCollection() { return false}
//        if (inputCollection?.userSelection) != nil {
//            return true
//        }
//        else {return false}
//    }

    func getUserAssetSelection() -> PGLUserAssetSelection? {

            return inputCollection?.userSelection

    }



    func isSingluar() -> Bool {

        if hasInputCollection()
            // this answers false if only one image in the collection
            { return inputCollection!.isSingular()}
        else { return false }
    }

    func hasOnePhoto() -> Bool {
        if let myList = inputCollection {
             return myList.isSingular()}
        else { return false }
    }

    func setToIncrementEach() {
        if let myInput = inputCollection {
            // may not have an input collection
            myInput.nextType = NextElement.each
        }

    }

    func increment() {
        switch attributeClass! {
        case  AttrClass.Image.rawValue :  
            if hasInputCollection() {
                if let nextImage = inputCollection!.increment() {

                    aSourceFilter.setImageValue(newValue: nextImage, keyName: attributeName!)
                    }
                }


        case  AttrClass.Number.rawValue : if let numberValue = self.getNumberValue() {
                    let newValue = numberValue.doubleValue + 1.0
                    self.set(newValue) }
            
        case AttrClass.Vector.rawValue :  if let vectorValue = self.getVectorValue() {
                   let newVector = CIVector(x: vectorValue.x + 1.0, y: vectorValue.y + 1.0)
                   self.set(newVector)
                }
            
        case AttrClass.Color.rawValue : if let colorValue = self.getColorValue() {
                   let newColor = CIColor(red: colorValue.red + 0.1 , green: colorValue.green + 0.1, blue: colorValue.blue + 0.1)
                   self.set(newColor)
                    }
        case  AttrClass.Data.rawValue :  let dataValue = getDataValue()
                        set(dataValue as Any)  // increment semenatics do not work for a data object
                        NSLog("PGLFilterAttribute increment on NSData ")
        case  AttrClass.Value.rawValue : let aNSValue = getNSValue()
                        set(aNSValue as Any) // increment semenatics do not work for a data object
                        NSLog("PGLFilterAttribute increment on NSValue ")
        case  AttrClass.Object.rawValue : let objectValue = getObjectValue()
                         set(objectValue as Any)
        case  AttrClass.String.rawValue :  let stringValue = getStringValue()
                        set(stringValue! as String + "increment")
            
        default: assert(true == false)  // raises error on a new attribute class
        }
    }

    // MARK: child attributes
    func valueInterface() -> [PGLFilterAttribute] {
        // subclasses such as PGLFilterAttributeAffine implement a attributeUI collection
        // single affine parm attribute needs three independent settings rotate, scale, translate
        // also use color as collection of valueUI cells
        return [self]
    }

    // MARK: Swipe support

    func varyTimerAttribute() -> PGLFilterAttribute? {
            // override to answer nil in some subclasses (image etc)

        if let newTimerRow = PGLTimerRateAttributeUI(pglFilter: (self.aSourceFilter), attributeDict: self.initDict, inputKey: self.attributeName!) {
            newTimerRow.timerParent = self
            return newTimerRow}
        else { return nil }
    }

    func performAction(_ controller: PGLSelectParmController?) {
        //override
        // could also use a closure to invoke various appropriate actions
        // this example from StackOverFlow
        // https://stackoverflow.com/questions/24158427/alternative-to-performselector-in-swift
//        class A {
//            var selectorClosure: (() -> Void)?
//            func invoke() {
//                self.selectorClosure?()
//            }
//        }
//        var a = A()
//        a.selectorClosure = { println("Selector called") }
//        a.invoke()

        aSourceFilter.animate(attributeTarget: self)
    }
    func performActionOff() {
        aSourceFilter.attribute(removeAnimationTarget: self)
    }

    func cellAction() -> [PGLTableCellAction] {
        //[(action:String,newCell:PGLFilterAttribute?) ]
        // subclasses override
        var allActions = [PGLTableCellAction]()
            // [(action:String,newCell:PGLFilterAttribute?) ]()
        if let newVaryAttribute = varyTimerAttribute() {
            if !hasAnimation() { // add Vary
                let varyAction = PGLTableCellAction(action: "Vary", newAttribute: newVaryAttribute, canPerformAction: true, targetAttribute: self)
                allActions.append(varyAction) }
            else { // add Cancel
                let cancelVaryAction = PGLTableCellAction(action: "Cancel", newAttribute: nil, canPerformAction: true, targetAttribute: self)
                allActions.append(cancelVaryAction) }

            // the Vary cell needs to have it's own swipe actions of  Cancel, OK
            // the Vary cell controls the rate of change with it's own slider
            // the timerParent actually does the start / stop of the animation change to the parm value
            // it signals the filter
            //  currentFilter?.attribute(animateTarget: tappedAttribute)
            // or
            // currentFilter?attribute(removeAnimationTarget: PGLFilterAttribute)
            // the timer method is the #addStepTime
        }

        return allActions
    }

    func segueName() -> String? {
          // subclasses override in the case where only a segue
        return nil
    }
    
    func performAction2(_ controller: PGLSelectParmController?) {
        // subclasses override in the case where only a segue or command is needed
        // a new subUI cell was not added by the actionCells method
     
    }

    func restoreOldValue() {
        // implement in subclasses for the various setValue types
        // each type should have a var for the last value to restore
        // future may be an array of changes.

    }

    // MARK: MoveTo Point
    func moveTo(startPoint: CGPoint, newPoint: CGPoint, inView: UIView) {
        // move is ended..
        switch attributeClass! {
        case AttrClass.Vector.rawValue :
            // map back to flipped vertical
            // this can be deleted.. moveTo... not called
            let flippedVertical = inView.bounds.height - newPoint.y
            let newVector = CIVector(x: newPoint.x, y: flippedVertical)
            self.set(newVector)
        case AttrClass.Color.rawValue: break
        case  AttrClass.Image.rawValue : break
        case  AttrClass.Number.rawValue :  break
        case  AttrClass.Data.rawValue :  break
        case  AttrClass.Value.rawValue : break
        case  AttrClass.Object.rawValue : break
        case  AttrClass.String.rawValue :  break
        case  AttrClass.AttributedString.rawValue : break

        default: assert(true == false)  // raises error on a new attribute class
        }
    }
    
    func movingChange(startPoint: CGPoint, newPoint: CGPoint, inView: UIView) {
        // pan move in progress.. update as needed
        switch attributeClass! {
        case AttrClass.Vector.rawValue :
            // map back to flipped vertical
             // this can be deleted for the ordinary point.. movingChange...
            // the rectangle subclass still uses this protocol

            let flippedVertical = inView.bounds.height - newPoint.y
            let newVector = CIVector(x: newPoint.x, y: flippedVertical)
            self.set(newVector)
        case AttrClass.Color.rawValue: break
        case  AttrClass.Image.rawValue : break
        case  AttrClass.Number.rawValue :  break
        case  AttrClass.Data.rawValue :  break
        case  AttrClass.Value.rawValue : break
        case  AttrClass.Object.rawValue : break
        case  AttrClass.String.rawValue :  break
         case  AttrClass.AttributedString.rawValue : break
            
        default: assert(true == false)  // raises error on a new attribute class
        }
    }

    // MARK: Subclass type
    // these will be moved to subclass as they are created

    func attributeUIType() -> AttrUIType {
        // assumes these types do not overlap
        if isPointUI() { return AttrUIType.pointUI}

        if isSliderUI() {  return AttrUIType.sliderUI}
        if isImageUI() {  return AttrUIType.imagePickUI}
        if isRectUI()  { return AttrUIType.rectUI}
        if isTextInputUI() {return AttrUIType.textInputUI}
        if isFontUI() { return  AttrUIType.fontUI}
        // else
        return AttrUIType.filterPickUI
    }
    func isRectUI()->Bool {

        return false // subclass PGLFilterAttributeRectangle answers true
        // where attributeType= "CIAttributeTypeRectangle"
        //  & attributeClass= AttrClass.Vector.rawValue
    }

    func isSliderUI()-> Bool {
         let isNumberScalar = ( attributeType == AttrType.Scalar.rawValue  )
         let isNumberDistance = ( attributeType == AttrType.Distance.rawValue  )
         let isNumberAngle = ( attributeType == AttrType.Angle.rawValue )
         let hasSliderValue = ( sliderMinValue != nil ) && (sliderMaxValue != nil)
         let isColorSlider = (attributeClass == AttrClass.Color.rawValue)  // and should be a PGLFilterAttributeColor instance
         let isTransform = (attributeType == AttrType.Transform.rawValue)
        let isNumberClass = (attributeClass == AttrClass.Number.rawValue)
         let answer = ( isNumberScalar || isNumberDistance || isNumberAngle  || hasSliderValue || isColorSlider  || isTransform || isNumberClass )
//            NSLog("attribute \(attributeName) isSliderUI = \(answer)")
        return answer
    }

    func isPointUI() -> Bool {
        let isVectorPosition = (attributeClass == AttrClass.Vector.rawValue )
        if attributeType != nil {
            // who needs this additional check on attributeType?
            return ((attributeType == AttrType.Position.rawValue) || (attributeType == AttrType.Position3.rawValue) || (attributeType == AttrType.Offset.rawValue ) )
        }
        else { return isVectorPosition }
            // where attributeType is not defined then use the attributeClass only
    }

    func isTextInputUI() -> Bool {
        // CIAttributedTextImageGenerator inputText,
        // CIAztecCodeGenerator inputMessage
        // CICode128BarcodeGenerator  inputMessage
        // CIPDF417BarcodeGenerator  inputMessage
        // CIQRCodeGenerator  inputMessage inputCorrectionLevel
        // CITextImageGenerator inputText inputFontName

        if attributeName == "inputFontName" {
            return false}
        if attributeClass == AttrClass.String.rawValue {
            return true }
        if (attributeName == "inputText") || (attributeName == "inputMessage")
            { return true }

        return false // default value
    }
    func isFontUI() -> Bool {
        // attribute will use UIFontPickerViewController
        return (attributeName == "inputFontName")
    }

    func isImageUI() -> Bool {
        let isImage = (attributeClass ==  AttrClass.Image.rawValue  )
//            && attributeType == "CIAttributeTypeImage" )
        return isImage
    }

    // MARK: controlImageView






}

class PGLFilterAttributeImage: PGLFilterAttribute {
    // attributeClass ==  AttrClass.Image.rawValue
    // || (attributeType == kCIAttributeTypeImage)?


    var imageParmState = ImageParm.missingInput

    var specialFilterIsAssigned = false
    // indicates that myFilter was assigned by a special constructor method
    // prevents the special specialConstructor from being assigned on every frame

    var storedParmImage: CDParmImage?

    override func uiCellIdentifier() -> String {
        return  "Image"
    }

    override func set(_ value: Any ) {
        // use a system of double dispatch to address typing
        //
        if attributeName != nil {
                aSourceFilter.setImageValue(newValue: value as! CIImage, keyName: attributeName!) }
    }
    // answer a filter type subUI parm cell

  override func hasImageInput() -> Bool? {
    
    // answer true if there is an inputCollection and it is not empty

    switch imageParmState {
        case ImageParm.inputPhoto :
            return !imageInputIsEmpty()
        default:
            return false
    }
}
    override func setImageParmState(newState: ImageParm) {

        // see PGLFilterAttributeImage
        imageParmState = newState

    }

    override func inputParmType() -> ImageParm {

        return imageParmState
    }
    
  override  func setUICellDescription(_ uiCell: UITableViewCell) {
    var content = uiCell.defaultContentConfiguration()
    let newDescriptionString = self.attributeDisplayName ?? ""
    content.text = newDescriptionString
    content.imageProperties.tintColor = .secondaryLabel

    let parmInputType = inputParmType()
    switch parmInputType {
        case ImageParm.inputChildStack:
            content.image = PGLFilterAttribute.FlowChartSymbol
        case ImageParm.inputPhoto:
            if self.hasOnePhoto() {
                content.image = PGLFilterAttribute.PhotoSymbolSingle }
             else {
                content.image = PGLFilterAttribute.PhotoSymbol }
        case ImageParm.inputPriorFilter :
            content.image = PGLFilterAttribute.PriorFilterSymbol
        case ImageParm.missingInput :
            content.image = PGLFilterAttribute.MissingPhotoInput
        case ImageParm.notAnImageParm :
            content.image = nil // other symbols are set???
    }

    uiCell.contentConfiguration = content

  }

    func imageInputIsEmpty() -> Bool {
        if inputCollection == nil { return true }
        return inputCollection!.isEmpty()
    }

    func filterInputActionCell() -> PGLFilterAttribute? {
        // override to answer nil in some subclasses (image etc)

        return nil
    }

 override func cellAction() -> [PGLTableCellAction ] {
        // Image cell does not add subUI cells
        // just provides the contextAction
        // nil filterInputActionCell will trigger a segue
        var allActions = [PGLTableCellAction]()
        if imageParmState == ImageParm.inputPriorFilter {
            return allActions
            // empty no actions
            //can't change input from prior filter so no cell action swipe cells
        }
        let newPickAction = PGLTableCellAction(action: "Pick", newAttribute: filterInputActionCell(), canPerformAction: true, targetAttribute: self)
        allActions.append(newPickAction)
    
        if hasFilterStackInput() {
            let changeAction = PGLTableCellAction(action: "Change", newAttribute: filterInputActionCell(), canPerformAction: false, targetAttribute: self)
            // this should change to the child stack... but
            allActions.append(changeAction)
        }
        else {
            let newAction = PGLTableCellAction(action: "More", newAttribute: filterInputActionCell(), canPerformAction: false, targetAttribute: self)
            // this will segue to filterBranch.. opens the filterController
            allActions.append(newAction) }

        return allActions
    }

    override func performAction(_ controller: PGLSelectParmController?) {
        controller?.pickImage(self)



    }

    override func segueName() -> String? {
        // answer the  segue action
        // a new subUI cell was not added by the actionCells method
        
         return "goToFilterViewBranchStack"
        // this segue is attached to a different cell in IB
        // namely the ImageNewFilterInput prototype cell
        // a single prototype cell does not support  having two segues..
        // but the other cells segue can be called with perform(segue..)

    }

    func sourceImageAlbums() -> [String]? {

        if let sources = inputCollection?.sourceImageAlbums() {
            return sources
        }
        else { return nil }
    }

    // MARK: Depth/Disparity PGLFilterAttributeImage

    func disparityMap()  {
        // only a portrait mode photo from iPhone 7 or greater has the depth/disparity images
          inputCollection?.currentDisparityMap(target: self)
    }

    func requestDisparityMap(asset: PHAsset, image: CIImage) {
            // may not have depthData in many cases
            // process timing.. run in background for callback.
            // suggested to downSample the image to improve performance
            // should end with disparity and image matching...
            var auxImage: CIImage?
            var scaledDisparityImage: CIImage?

            let options = PHContentEditingInputRequestOptions()


            asset.requestContentEditingInput(with: options, completionHandler: { input, info in
                guard let input = input
                    else { NSLog ("contentEditingInput not loaded")
                         return
                    }
             // the completion handler can run after the requestDisparityMap function returns
            //  the completion handler has to assign a value not return a value

                if !info.isEmpty {
                    // is PHContentEditingInputErrorKey in the info
                    NSLog("PGLImageList #requestDisparityMap has info returned \(info)")
                }
             auxImage = CIImage(contentsOf: input.fullSizeImageURL!, options: [CIImageOption.auxiliaryDisparity: true])
//                auxImage = CIImage(contentsOf: input.fullSizeImageURL!, options: [CIImageOption.auxiliaryDepth: true])
                NSLog("PGLImageList #requestDisparityMap completionHandler auxImage = \(String(describing: auxImage))")

            if auxImage != nil {
                (self.aSourceFilter as? PGLDisparityFilter)?.hasDisparity = true
                var depthData = auxImage!.depthData

//                depthData?.depthDataMap.setUpNormalize()

                // depthData?.depthDataMap.normalizeDSP() // normalize before conversion to half float16
            if depthData?.depthDataType != kCVPixelFormatType_DisparityFloat32 {
                // convert to half-float16 but the normalize seems to expect float32..
                depthData = depthData?.converting(toDepthDataType: kCVPixelFormatType_DisparityFloat32) }

                _ = depthData?.depthDataMap.normalizeDisparity(pixelFormat:depthData!.depthDataType)  // vector processing method in Accelerate framework
//                depthData?.depthDataMap.normalize()
                // or

                //should depthDataByReplacingDepthDataMapWithPixelBuffer:error be used?
                //this is creating a derivative depth map reflecting whatever edits you make to the corresponding image

                if depthData?.depthDataType != kCVPixelFormatType_DisparityFloat16 {
                    // convert to half-float16
                    depthData = depthData?.converting(toDepthDataType: kCVPixelFormatType_DisparityFloat16) }
                // depthData needs to scale too...
                let doScaleDown = false

                if doScaleDown {
                    let scaledDownInput = image.applyingFilter("CILanczosScaleTransform", parameters: ["inputScale": 0.5])
                    scaledDisparityImage = auxImage?.applyingFilter("CIEdgePreserveUpsampleFilter",
                                                        parameters: ["inputImage": scaledDownInput ,"inputSmallImage":  auxImage as Any])
                    if !self.specialFilterIsAssigned {
                        self.myFilter = self.specialConstructor(inputImage: scaledDownInput, disparityImage: scaledDisparityImage!)
                        self.specialFilterIsAssigned = true
                    } else {
                        // assign directly
                        self.myFilter.setValue(scaledDownInput, forKey: kCIInputImageKey)
                        self.myFilter.setValue(scaledDisparityImage, forKey: "inputDisparityImage")
                    }
                }
                else {
                    // not scaling down
                    if !self.specialFilterIsAssigned {
                        self.myFilter = self.specialConstructor(inputImage: image, disparityImage: auxImage!)
                        self.specialFilterIsAssigned = true
                    } else {
                        // assign directly
                        self.myFilter.setValue(image, forKey: kCIInputImageKey)
                        self.myFilter.setValue(auxImage, forKey: "inputDisparityImage")
                    }
                }
                self.postImageChange()
                }
            } )




        }

func specialConstructor(inputImage: CIImage, disparityImage: CIImage) -> CIFilter {
    let ciContext = Renderer.ciContext // global context

    let filter = ciContext!.depthBlurEffectFilter(for: inputImage,
                                                 disparityImage: disparityImage,
                                                 portraitEffectsMatte: nil,
                                                 // the orientation of you input image
                                                 orientation: CGImagePropertyOrientation.up,
                                                 options: nil)!
//    filter.setValue(4, forKey: "inputAperture")
    filter.setValue(0.5, forKey: "inputScaleFactor")
//    filter.setValue(CIVector(x: 0, y: 100, z: 100, w: 100), forKey: "inputFocusRect")
    return filter

}

func postImageChange() {
           let outputImageUpdate = Notification(name:PGLOutputImageChange)
           NotificationCenter.default.post(outputImageUpdate)
       }
} // end PGLFilterAttributeImage


class PGLFilterAttributeAngle: PGLFilterAttribute {
    // attributeType = CIAttributeTypeAngle
    // attributeClass = NSNumber
    //  an angle in radians  presuming maxValue is 2Pi radians

    required init?(pglFilter: PGLSourceFilter, attributeDict: [String:Any], inputKey: String ) {
        super.init(pglFilter: pglFilter, attributeDict: attributeDict, inputKey: inputKey)
        minValue = 0.0
        sliderMinValue = minValue
        sliderMaxValue = 2 * Float.pi  //assuming a rangle limit.. the attributes do not supply this
//        if let thisFilterAngle = getNumberValue() {
//
//        }

    }

    override  func setUICellDescription(_ uiCell: UITableViewCell) {
      var content = uiCell.defaultContentConfiguration()
      let newDescriptionString = self.attributeDisplayName ?? ""
      content.text = newDescriptionString
      content.imageProperties.tintColor = .secondaryLabel
        content.image = UIImage(systemName: "slider.horizontal.below.rectangle")

      uiCell.contentConfiguration = content

    }
    
    override func set(_ value: Any) {
        if attributeName != nil {
            aSourceFilter.setNumberValue(newValue: value as! NSNumber, keyName: attributeName!)
        }
    }
    
  func hasSwipeAction() -> Bool {
        return true // subclasses override if they support timer or filter input actions

    }
}
class PGLFilterAttributeAffine: PGLFilterAttribute {
    var affine = CGAffineTransform.identity
    var rotation: Float = 0.0
    var oldRotation: Float = 0.0
    var scale = CIVector(x: 1.0, y: 1.0)
    var translate = CIVector(x: 0.0, y: 0.0)
    var valueParms = [PGLFilterAttribute]()

    required init?(pglFilter: PGLSourceFilter, attributeDict: [String:Any], inputKey: String ) {
        super.init(pglFilter: pglFilter, attributeDict: attributeDict, inputKey: inputKey)

    }

    override func valueInterface() -> [PGLFilterAttribute] {
        // subclasses such as PGLFilterAttributeAffine implement a attributeUI collection
        // single affine parm attribute needs three independent settings rotate, scale, translate

        if let rotateParm = PGLRotateAffineUI(pglFilter: aSourceFilter, attributeDict: initDict, inputKey: attributeName!)
        {   rotateParm.affine(parent: self)
            valueParms.append(rotateParm) // add translate & scale here
        }
        // for reasons that are not clear the translate and scale operations on the affine do not seem to change the image

//        if let translateParm = PGLTranslateAffineUI(pglFilter: aSourceFilter, attributeDict: initDict, inputKey: attributeName!)
//        {   translateParm.affine(parent: self)
//            valueParms.append(translateParm) // add translate & scale here
//        }
//
//        if let scaleParm = PGLScaleAffineUI(pglFilter: aSourceFilter, attributeDict: initDict, inputKey: attributeName!)
//        {   scaleParm.affine(parent: self)
//            valueParms.append(scaleParm) // add translate & scale here
//        }

        return valueParms
    }

    func setAffine() {
//      NSLog("setAffine = \(affine)")
        let nsTransform = NSValue(cgAffineTransform: affine)
        aSourceFilter.setNSValue(newValue: nsTransform, keyName: attributeName!)
    }

    func setScale(vector: CIVector) {
//        NSLog("PGLFilterAttributeAffine setScale affine = \(affine), vector = \(vector)")
        affine = affine.scaledBy(x: CGFloat(vector.x), y: CGFloat(vector.y))
        setAffine()
//        NSLog("PGLFilterAttributeAffine setScale NOW affine = \(affine)")
    }

    func setRotation(radians: Float) {
        let rotationChange = radians - oldRotation
//        NSLog("setRotation by \(rotationChange)")
        affine = affine.rotated(by: CGFloat(rotationChange))
        setAffine()
        oldRotation = radians
    }



    func setTranslation(moveBy: CIVector) {
//        NSLog ("setTranslation by: \(moveBy)")
        affine = affine.translatedBy(x: CGFloat(moveBy.x), y: CGFloat(moveBy.y))
        setAffine()
    }

    override func set(_ value: Any ) {
        if let newValue = value as? Float {
            setRotation(radians: newValue)
        } else { fatalError("PGLFilterAttributeAffine set value not converted")}
    }
    override func incrementValueDelta() {
        // animation time range 0.0 to 1.0


            setRotation(radians: oldRotation + attributeValueDelta! )
            postUIChange(attribute: self)

    }

   override func varyTimerAttribute() -> PGLFilterAttribute? {
        return nil // affine does not directly vary.. UI attributes attached can vary
    }

}

class PGLFilterAttributeColor: PGLFilterAttribute {
    var colorSpace = CGColorSpace.genericRGBLinear
        //        kCGColorSpaceDeviceRGB or  CGColorSpace.displayP3

    var red: CGFloat = 0.0
    var green: CGFloat = 0.0
    var blue: CGFloat = 0.0
    var alpha: CGFloat = 0.0

    required init?(pglFilter: PGLSourceFilter, attributeDict: [String:Any], inputKey: String ) {
        super.init(pglFilter: pglFilter, attributeDict: attributeDict, inputKey: inputKey)
        if let thisFilterColor = getColorValue() {
            // how to determine the colorSpace of the filter color??
            // if it is different then the conversion to displayP3 or genericRGBLinear etc.. is needed
            red = thisFilterColor.red
            green = thisFilterColor.green
            blue = thisFilterColor.blue
            alpha = thisFilterColor.alpha
        }

    }


    override  func setUICellDescription(_ uiCell: UITableViewCell) {
      var content = uiCell.defaultContentConfiguration()
      let newDescriptionString = self.attributeDisplayName ?? ""
      content.text = newDescriptionString
      content.imageProperties.tintColor = .secondaryLabel
        content.image = UIImage(systemName: "slider.horizontal.3")

      uiCell.contentConfiguration = content

    }
    override func set(_ value: Any) {
            if let aColor = SliderColor(rawValue: uiIndexTag) {
                 let floatColor = CGFloat((value as? Float ?? 0.0))       //value as? CGFloat {
                setColor(color: aColor , newValue: floatColor )

            }

    }
    
    func setColor(color: SliderColor, newValue: CGFloat) {
        let changedColor: CIColor
        if let oldColor = getColorValue() {
            switch color {
            case SliderColor.Red:
                changedColor = CIColor(red: newValue, green: oldColor.green, blue: oldColor.blue, alpha: oldColor.alpha, colorSpace: oldColor.colorSpace)!
            case SliderColor.Green:
                changedColor = CIColor(red: oldColor.red, green: newValue, blue: oldColor.blue, alpha: oldColor.alpha, colorSpace: oldColor.colorSpace)!
            case SliderColor.Blue:
                changedColor = CIColor(red: oldColor.red, green: oldColor.green, blue: newValue, alpha: oldColor.alpha, colorSpace: oldColor.colorSpace)!
            case SliderColor.Alpha:
                changedColor = CIColor(red: oldColor.red, green: oldColor.green, blue: oldColor.blue, alpha: newValue, colorSpace: oldColor.colorSpace)!
            }
            aSourceFilter.setColorValue(newValue: changedColor, keyName: attributeName!)
            NSLog("PGLFilterAttribute setColor to \(changedColor)")
        }
    }

}

class PGLAttributeRectangle: PGLFilterAttribute {
    // where attributeType= "CIAttributeTypeRectangle"
    //  & attributeClass= AttrClass.Vector.rawValue

    var filterRect: CGRect =  CGRect(x: 0, y: 0, width: 300, height: 300)
//    {didSet {
////        NSLog("PGLAttributeRectangle didSet filterRect = \(filterRect)")
//      //  filterRect = (0.0, 0.0, 1583.0, 1668.0)
//        if (filterRect.height >= 1660){
//            NSLog("PGLAttributeRectangle full size filterRect = \(filterRect)")
//        }
//        // this is called to much in the inputImage code.. WHY?
//        }}
   
    var oldVector: CIVector?
    var isCropped = false


    required init?(pglFilter: PGLSourceFilter, attributeDict: [String:Any], inputKey: String ) {
        super.init(pglFilter: pglFilter, attributeDict: attributeDict, inputKey: inputKey)
        if let myVector = self.getVectorValue(){
//            NSLog("PGLFilterAttributeRectangle init vectorValue = x:\(myVector.x) y:\(myVector.y)  width: \( myVector.z) height: \(myVector.w)")
            if (myVector.x < 1.0 && myVector.y < 1.0 && myVector.z < 1.0 && myVector.w < 1.0) {
                filterRect = CGRect(x: myVector.x, y: myVector.y, width: myVector.z, height: myVector.w)
            }  // else keep the default rect of 300
        }
        if let rectangleFilter = pglFilter as? PGLRectangleFilter {
            rectangleFilter.cropAttribute = self
        }
//        NSLog("PGLFilterAttributeRectangle init filterRect = \(filterRect)")
        // the rect should actually be the frame of the rectangle controller view..
        // raises question about why the filterRect is on this object..
    }

    override func valueString() -> String {
        if isCropped {
             return String(describing: (getValue() ?? "") )
        }
        else { // no meaningful value
                return ""}
    }

    override  func setUICellDescription(_ uiCell: UITableViewCell) {
      var content = uiCell.defaultContentConfiguration()
      let newDescriptionString = self.attributeDisplayName ?? ""
      content.text = newDescriptionString
      content.imageProperties.tintColor = .secondaryLabel
    content.image = UIImage(systemName: "crop")

      uiCell.contentConfiguration = content

    }
    // MARK: change values

    override func cellAction() -> [PGLTableCellAction] {
        var allActions = [PGLTableCellAction]()

        if isCropped {
            let cancelAction = PGLTableCellAction(action: "Cancel", newAttribute: nil, canPerformAction: true, targetAttribute: self)
            cancelAction.performAction2 = true  // runs performAction2
            allActions.append(cancelAction)
        }
        else {
            let okAction = PGLTableCellAction(action: "OK", newAttribute: nil, canPerformAction: true, targetAttribute: self)
            allActions.append(okAction)
        }
        return allActions

    }

    override func performAction(_ controller: PGLSelectParmController?) {
//        NSLog("PGLFilterAttributeRectangle #performAction ")
       controller?.cropAction(rectAttribute: self)
        controller?.hideRectController()
        isCropped = true
    }

    override func performAction2(_ controller: PGLSelectParmController?) {
        // Cancel action from the swipe cell

        restoreOldValue()
        controller?.hideRectController()
         isCropped = false
    }
    override func varyTimerAttribute() -> PGLFilterAttribute? {
        return nil // rectangle does not directly vary.. UI attributes attached can vary
    }

   override func okActionToSetValue() -> Bool {
        // subclass override to true if set value is deferred to the OK action of the parm cell
        return true
    }

    override func restoreOldValue() {
        // implement in subclasses for the various setValue types
        // each type should have a var for the last value to restore
        // future may be an array of changes.
//        set(oldVector)  // the form of set() does some typecasting to any and back again.. in this subclass set directly
        if oldVector != nil {
            aSourceFilter.setVectorValue(newValue: oldVector!, keyName: attributeName!)
        }
    }


    //MARK: movement

    override func moveTo(startPoint: CGPoint, newPoint: CGPoint, inView: UIView) {
        // there is  the case of drag of the same size rect to a new position.
        // also case of new rectangle based on adjusting the rect vertex closest to the start point to the new point.


        let newOriginX = filterRect.origin.x + (newPoint.x - startPoint.x)
        let newOriginY = filterRect.origin.y + (newPoint.y - startPoint.y)

        filterRect.origin.x = newOriginX
        filterRect.origin.y = newOriginY

        // let the parent filter do the work in CIImage.methods  see PGLCropFilter outputImage()
    }

    override func set(_ value: Any) {
        // this parm should use the applyCropRect.. bypass the set call
        // empty implementation
    }
    func applyCropRect(mappedCropRect: CGRect) {
        // assumes mappedCropRect is the new frame as transformed into the CIImage size and LLO coordinates
        // generate the vector
        // save the old vector
        // apply to the filter

        let newVector = CIVector(x: mappedCropRect.origin.x, y: mappedCropRect.origin.y, z: mappedCropRect.size.width, w: mappedCropRect.size.height)

        oldVector = self.getVectorValue()  // save old value for cancel action
        aSourceFilter.setVectorValue(newValue: newVector, keyName: attributeName!)
        // let the parent filter do the work in CIImage.methods  see PGLRectangleFilter outputImage()

    }


    override func movingChange(startPoint: CGPoint, newPoint: CGPoint, inView: UIView) {
        // pan move in progress.. update as needed
        // does not change the filter just changes the rect of the parm
//        let logMovingChange = false

        let actualStartPoint: CGPoint

        if startPoint == CGPoint.zero {actualStartPoint = newPoint} else {actualStartPoint = startPoint}
         // the first call of pan change does not know the start point.. later calls during the pan have the value.

        switch attributeClass! {
        case AttrClass.Vector.rawValue :

//            if logMovingChange {   NSLog("PGLFilterAttributeRectangle #movingChange startPoint = \(startPoint) newPoint = \(newPoint)")

//                NSLog("PGLFilterAttributeRectangle #movingChange in view.frame = \(inView.frame)") }
            // this is the view.frame of PGLParmTableViewController.


            let deltaX = newPoint.x - actualStartPoint.x
            let deltaY = newPoint.y - actualStartPoint.y


            let newOriginX = filterRect.origin.x + deltaX
            let newOriginY = filterRect.origin.y + deltaY
//            if logMovingChange {           NSLog("PGLFilterAttributeRectangle #movingChange filterRect = \(filterRect)") }
//            if newOriginX == 0 { fatalError(" going to zero origin in filterRect.origin" )}
            filterRect.origin = CGPoint(x:newOriginX, y: newOriginY)
//            if logMovingChange { NSLog("PGLFilterAttributeRectangle #movingChange orgin moved filterRect = \(filterRect)")}


        case AttrClass.Color.rawValue: break
        case  AttrClass.Image.rawValue : break
        case  AttrClass.Number.rawValue :  break
        case  AttrClass.Data.rawValue :  break
        case  AttrClass.Value.rawValue : break
        case  AttrClass.Object.rawValue : break
        case  AttrClass.String.rawValue :  break
            
        default: assert(true == false)  // raises error on a new attribute class
        }


    }

    override func movingCorner(atCorner: Vertex, startPoint: CGPoint, newPoint: CGPoint) {
        // changes the corner but does not apply the change to the filter..
        // the visual rectangle is moving but the filter is not updated until the OK button
        let actualStartPoint: CGPoint
        var deltaX: CGFloat = 0.0
        var deltaY: CGFloat = 0.0
        if startPoint == CGPoint.zero {actualStartPoint = newPoint} else {actualStartPoint = startPoint}
        // the first call of pan change does not know the start point.. later calls during the pan have the value.
//        NSLog("PGLFilterAttributeRectangle #movingCorner filterRect = \(filterRect)")
//        NSLog("PGLFilterAttributeRectangle #movingCorner atCorner = \(atCorner) startPoint = \(startPoint) newPoint = \(newPoint)")
        switch atCorner {
            case Vertex.upperLeft:
                deltaX = newPoint.x - actualStartPoint.x
                deltaY = newPoint.y - actualStartPoint.y

            case Vertex.lowerRight:
                 deltaX =  actualStartPoint.x - newPoint.x
                 deltaY =  actualStartPoint.y - newPoint.y

            case Vertex.lowerLeft:
                 deltaX =   newPoint.x - actualStartPoint.x
                 deltaY =   actualStartPoint.y - newPoint.y

            case Vertex.upperRight:
                deltaX =  actualStartPoint.x - newPoint.x
                deltaY = newPoint.y - actualStartPoint.y

            }
         filterRect = filterRect.insetBy(dx: deltaX, dy: deltaY)
//         NSLog("PGLFilterAttributeRectangle #movingCorner filterRect NOW = \(filterRect)")

    }

  

    override func isRectUI() -> Bool {
        return true // super class answers false
        // where attributeType= "CIAttributeTypeRectangle"
        //  & attributeClass= AttrClass.Vector.rawValue
    }

    // MARK: controlImageView

}
