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
        let maskInputName = "CIPersonSegmentation"   // blend mask child input
                                                     //        let backgroundInput = "Sequenced Filters"  // blend background input
        stackName = "Demo"

        let sequenceFilters = [
            "CIBlendWithMask", // sequenceStack child
            "CIToneCurve",
            "CIKaleidoscope",
            "CIPerspectiveTransform"
        ]


        let demoInput = PGLImageList(imageFileNames: [
            "Eagle Mtn",
            "FarmSunrise",
            "foggyPath"])
        let demoBackgrdInput = PGLImageList(imageFileNames: [
            "LakeHarbor",
            "LakeOverlook",
            "LakeHarbor" ] )
        let demoMaskInput = PGLImageList(imageFileNames: [
            "morningMeadow",
            "winterScene" ] )
        let demoPersonSegmentImage = PGLImageList(imageFileNames: [
            "WL-B" ] )


        if let startingFilter =  demoLoadFilter(ciFilterString: topFilterName) {
            append(startingFilter)

            let imageAttribute = startingFilter.getInputImageAttribute()
            imageAttribute?.setImageCollectionInput(cycleStack: demoPersonSegmentImage)

                /// set up mask
            let startingFilterMaskAttr =  startingFilter.attribute(nameKey: kCIInputMaskImageKey)

            let maskChildStack = PGLFilterStack()
            maskChildStack.stackName = "Mask"
            maskChildStack.stackType = "input"
            maskChildStack.parentAttribute = startingFilterMaskAttr

            startingFilterMaskAttr?.inputStack = maskChildStack
            startingFilterMaskAttr?.setImageParmState(newState: .inputChildStack)

            if let childFilter = demoLoadFilter(ciFilterString: maskInputName) {

                let childInputAttribute = childFilter.getInputImageAttribute()
                childInputAttribute?.setImageCollectionInput(cycleStack: demoPersonSegmentImage)

                maskChildStack.append(childFilter)
            }


                /// set up background sequence
            let backgrdInputAttribute = startingFilter.attribute(nameKey: kCIInputBackgroundImageKey)
            let backgrdChildStack = PGLFilterStack()
            backgrdChildStack.stackName = "Mask"
            backgrdChildStack.stackType = "input"
            backgrdChildStack.parentAttribute = backgrdInputAttribute

            backgrdInputAttribute?.inputStack = backgrdChildStack
            backgrdInputAttribute?.setImageParmState(newState: .inputChildStack)

            let theDescriptor = PGLFilterDescriptor(kPSequencedFilter, PGLSequencedFilters.self)

            guard let seqFilter = theDescriptor?.pglSourceFilter() as? PGLSequencedFilters
            else {   fatalError("Did not create SequencedFilters" ) }
            backgrdChildStack.append(seqFilter)

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
    @objc func setDemoParms() {
        // to capture new values
        // set  breakpoints at PGLImageController panEnded line parm.set(newVector)

        switch filterName {
            case "CIPerspectiveTransform":
                demoPerspectiveTransformParms()
            default:
                return
        }

    }

    func demoPerspectiveTransformParms() {
        if let myInputParm = attribute(nameKey: "inputTopLeft") {
            myInputParm.set(CIVector(x: 350, y: 903 ))
        }
        if let myInputParm = attribute(nameKey: "inputTopRight") {
            myInputParm.set(CIVector(x: 1146, y: 1218 ))
        }

    }
}
extension PGLVectorBasedFilter {

    @objc override func setDemoParms() {

        if let myInputParm = attribute(nameKey: "inputPoint1") {
            myInputParm.set(CIVector(x: 213, y: 576 ))
        }

        if let myInputParm = attribute(nameKey: "inputPoint3") {
            myInputParm.set(CIVector(x: 973, y: 707 ))
        }



    }
}


//extension PGL
//    // CIPerspectiveTransform
//    // (149.0, 318.0)
//    // inputTopLeft
//}
