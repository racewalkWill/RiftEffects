//
//  PGLFilterStackDemo.swift
//  RiftEffects
//
//  Created by Will on 4/23/23.
//  Copyright © 2023 Will Loew-Blosser. All rights reserved.
//

import Foundation
import CoreImage
import UIKit
import Photos
import PhotosUI
import os


extension PGLFilterStack {



    func createDemoStack(appStack: PGLAppStack) {
            // load images in Assets.xcassets folder 'DemoImages'
            // load filters into stack with demoImages

        let topFilterName = "CIBlendWithRedMask"
        let maskInputName = "CIPersonSegmentation"   
            // blend mask child input
            //  let backgroundInput = "Sequenced Filters"  // blend background input
        stackName = "Demo"

        let sequenceFilters = [
            "CIBlendWithRedMask", // sequenceStack child
            "CIToneCurve",
            "CIKaleidoscope",
            "CIDifferenceBlendMode",
            "CIPerspectiveTransform"
        ]


        let demoInput = PGLImageList(imageFileNames: [
            "Eagle Mtn",
            "FarmSunrise",
            "foggyPath"])
        let demoBackgrdInput = PGLImageList(imageFileNames: [
            "LakeOverlook",
            "LakeHarbor" ] )
        let demoMaskInput = PGLImageList(imageFileNames: [
            "morningMeadow",
            "winterScene" ] )
        let demoPersonSegmentImage = PGLImageList(imageFileNames: [
            "WL-B" ] )


//        if let startingFilter =  demoLoadFilter(ciFilterString: topFilterName) {
//            append(startingFilter)

//            let imageAttribute = startingFilter.getInputImageAttribute()
//            imageAttribute?.setImageCollectionInput(cycleStack: demoPersonSegmentImage)
//
//                /// set up mask
//
//            _ = startingFilter.addChildFilter(toAttributeName: kCIInputMaskImageKey, childFilterName: maskInputName, childImageInputs: demoPersonSegmentImage)
//
//                /// set up background sequence
//            let backgrdInputAttribute = startingFilter.attribute(nameKey: kCIInputBackgroundImageKey)

//            let backgrdChildStack = PGLFilterStack()
//            backgrdChildStack.stackName = "Mask"
//            backgrdChildStack.stackType = "input"
//            backgrdChildStack.parentAttribute = backgrdInputAttribute
//
//            backgrdInputAttribute?.inputStack = backgrdChildStack
//            backgrdInputAttribute?.setImageParmState(newState: .inputChildStack)

            let theDescriptor = PGLFilterDescriptor(kPSequencedFilter, PGLSequencedFilters.self)

            guard let seqFilter = theDescriptor?.pglSourceFilter() as? PGLSequencedFilters
            else {   fatalError("Did not create SequencedFilters" ) }
//            backgrdChildStack.append(seqFilter)
            append(seqFilter)

            seqFilter.addChildSequenceStack(appStack: appStack)
                /// setup sequence input images
            seqFilter.getInputImageAttribute()?.setImageCollectionInput(cycleStack: demoInput)
            seqFilter.attribute(nameKey: kCIInputBackgroundImageKey)?.setImageCollectionInput(cycleStack: demoBackgrdInput)
            seqFilter.attribute(nameKey: kCIInputMaskImageKey)?.setImageCollectionInput(cycleStack: demoMaskInput)

                /// add filters to the sequence
            for aFilterString in sequenceFilters {

                guard let thisFilter = demoLoadFilter(ciFilterString: aFilterString)
                else { continue }
                thisFilter.setDemoParms()
                seqFilter.filterSequence()?.appendFilter(thisFilter)

            }
                // postFilterChangeRedraw()
            postStackChange()
            postTransitionFilterAdd() // makes the redraws run
            postCurrentFilterChange() // makes DoNotDraw = false..
//        }

    }

    func loadStartup(userStartupImageList: PGLImageList) {
        if let startingFilter = demoLoadFilter(ciFilterString: "Images") {
            append(startingFilter)
            let imageAttribute = startingFilter.getInputImageAttribute()
            guard let myAppDelegate =  UIApplication.shared.delegate as? AppDelegate
                else { Logger(subsystem: LogSubsystem, category: LogCategory).fault("PGLSplitViewController viewDidLoad fatalError(AppDelegate not loaded")
                fatalError("PGLSplitViewController could not access the AppDelegate")
            }

            myAppDelegate.appStack.targetAttribute = imageAttribute
            imageAttribute?.setImageCollectionInput(cycleStack:userStartupImageList)
            postStackChange()
            postTransitionFilterAdd() // makes the redraws run
            postCurrentFilterChange() // makes DoNotDraw = false..
        }
    }


    func demoLoadFilter(ciFilterString: String) -> PGLSourceFilter? {
            // an Fatal Error if filter is not created
        let aMappedClass = CIFilterToPGLFilter.Map[ciFilterString]
        if (aMappedClass?.count ?? 0) > 1
        { fatalError("This demo filter has multiple descriptors - coding error")}                    // normally will be nil - then PGLFilterDescriptor defaults to PGLSourceFilter.self
        guard let thisDescriptor = PGLFilterDescriptor(ciFilterString, aMappedClass?.first )
        else { fatalError("Demo Load Filter Error ") }
        let thisFilter = thisDescriptor.pglSourceFilter()


        return thisFilter
    }
}

extension UIImage {
    static func ciImages(_ imageFileNames: [String]) -> [CIImage] {
        var answerCIImages = [CIImage]()
        for aFileName in imageFileNames {
            if let aUIImage = UIImage.init(named: aFileName) {
                if let ciVersion = CIImage.init(image: aUIImage) {
                    answerCIImages.append(ciVersion)
                }
            }
        }
    return answerCIImages

    }

    static func uiImages(_ imageFileNames: [String]) -> [UIImage] {
        var answerImages = [UIImage]()
        for aFileName in imageFileNames {
            if let aUIImage = UIImage.init(named: aFileName) {
                answerImages.append(aUIImage)
            }
        }
    return answerImages

    }
}
extension PGLSourceFilter {

    func addChildFilter(toAttributeName: String , childFilterName: String, childImageInputs: PGLImageList?) -> PGLSourceFilter? {

        guard let parentAttr =  attribute(nameKey: kCIInputMaskImageKey)
            else { return nil }
        let maskChildStack = PGLFilterStack()
        maskChildStack.stackName = "Mask"
        maskChildStack.stackType = "input"
        maskChildStack.parentAttribute = parentAttr

        parentAttr.inputStack = maskChildStack
        parentAttr.setImageParmState(newState: .inputChildStack)

        if let childFilter = maskChildStack.demoLoadFilter(ciFilterString: childFilterName) {

            let childInputAttribute = childFilter.getInputImageAttribute()
            if let newInputList = childImageInputs {
                childInputAttribute?.setImageCollectionInput(cycleStack: newInputList)
            }

            maskChildStack.append(childFilter)
            return childFilter
        } else {
            return nil // failed to create child filter
        }

    }

    @objc func setDemoParms() {
        // to capture new values
        // set  breakpoints at PGLImageController panEnded line parm.set(newVector)

        switch filterName {
            case "CIPerspectiveTransform":
                demoPerspectiveTransformParms()
            case "CIBlendWithMask":
                demoBlendWithMaskParms()
            case "CIKaleidoscope":
                demoKaleidoscopeParms()
            case "CIDifferenceBlendMode":
                demoDifferenceBlendParms()
            default:
                return
        }

    }

    func demoKaleidoscopeParms() {
        setVectorValue(newValue: CIVector(x: 300, y: 697), keyName: "inputCenter")
        setNumberValue(newValue: 0.7306029, keyName: "inputAngle")
    }

    func demoPerspectiveTransformParms() {
        // filter is CIPerspectiveTransform

        setVectorValue(newValue: CIVector(x: 1416, y: 350), keyName: "inputBottomRight")
        setVectorValue(newValue: CIVector(x: 1409, y: 1195), keyName: "inputTopRight")
        setVectorValue(newValue: CIVector(x: 113, y: 657), keyName: "inputBottomLeft")
        setVectorValue(newValue: CIVector(x: 89, y: 1137), keyName: "inputTopLeft")


    }

    func demoBlendWithMaskParms() {
            //   filter is CIBlendWithMask

        if let starMask = addChildFilter(toAttributeName: kCIInputMaskImageKey, childFilterName: "CIStarShineGenerator", childImageInputs: nil) {

            starMask.setVectorValue(newValue: CIVector(x: 431.0, y: 1019.0), keyName: "inputCenter")
                // ( [431 1019] , inputCenter
            starMask.setNumberValue(newValue:  81.62791, keyName: "inputRadius")


        }
    }

        func demoDifferenceBlendParms() {
            // filter "CIDifferenceBlendMode"
            let eyeGlassMask = PGLImageList(imageFileNames: [
                "eyeGlasses"])
            if let backgrdInputAttribute = self.attribute(nameKey: kCIInputBackgroundImageKey) {
                backgrdInputAttribute.setImageCollectionInput(cycleStack: eyeGlassMask ) }
            
        }



    }

extension PGLVectorBasedFilter {

    @objc override func setDemoParms() {

//        if let myInputParm = attribute(nameKey: "inputPoint1") {
//            myInputParm.set(CIVector(x: 213, y: 576 ))
//        }
        self.setVectorValue(newValue: CIVector(x: 0.15, y: 0.12), keyName: "inputPoint0")
        self.setVectorValue(newValue: CIVector(x: 0.316, y: 0.398), keyName: "inputPoint1")
        self.setVectorValue(newValue: CIVector(x: 0.673, y: 0.415), keyName: "inputPoint2")
        self.setVectorValue(newValue: CIVector(x: 0.76, y: 0.761), keyName: "inputPoint3")

//        if let myInputParm = attribute(nameKey: "inputPoint3") {
//            myInputParm.set(CIVector(x: 973, y: 707 ))
//        }



    }
}


//extension PGL
//    // CIPerspectiveTransform
//    // (149.0, 318.0)
//    // inputTopLeft
//}
