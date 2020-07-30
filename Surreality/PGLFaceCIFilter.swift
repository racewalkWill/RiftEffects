//
//  PGLFaceFilter.swift
//  Glance
//
//  Created by Will on 8/26/18.
//  Copyright © 2018 Will Loew-Blosser All rights reserved.
//

import UIKit

class PGLFaceCIFilter: PGLFilterCIAbstract {
    // PGLDetectorFilter and this custom CIFilter are connected in PGLCIFilterExtensions  method CIFilter #pglClassMap
    //  with the key value pair of  "FaceFilter": PGLDetectorFilter.self
    // this ciFilter part of the collobrating classes is doing the blending / matting using the
    // cached features from the PGLSourceFilter vars of PGLDetector
    // 'clever' aka difficult design to trace


    override class func register() {
 //       let attr: [String: AnyObject] = [:]
        NSLog("PGLFaceCIFilter #register()")
        CIFilter.registerName(kPFaceFilter, constructor: PGLFilterConstructor(), classAttributes: PGLFaceCIFilter.customAttributes())
    }

    @objc override class func customAttributes() -> [String: Any] {

        let customDict:[String: Any] = [
            kCIAttributeFilterDisplayName : "Face Filter",

            kCIAttributeFilterCategories :
                [kCICategoryBlur],

            "inputRadius" :  [
                kCIAttributeMin       :  0.0,
                kCIAttributeSliderMin :  0.0,
                kCIAttributeSliderMax : 100.0,
                kCIAttributeDefault   : 10.0,
                kCIAttributeIdentity  :  0.0,
                kCIAttributeType      : kCIAttributeTypeScalar
            ]

        ]

        return combineCustomAttributes(otherAttributes: customDict)
    }


//    @objc dynamic  var inputImage: CIImage?
    @objc dynamic var inputRadius: NSNumber = 10.0
   
    let opaqueGreen = CIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0 )
    let transparentGreen =  CIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 0.0 )


   fileprivate func addToComposite(_ i: Int, _ compositeMap: inout CIImage?) {
        var index = 0
        if( i > features.count - 1 ) { index = features.count - 1} else { index = i }
            // truncate index to max of features if slider value is too big
        if let theHighLight = faceHighlight(aFace: features[index]) {
            compositeMap = addMap(theHighLight, toImage: compositeMap)
        }

    }

    
  override var outputImage: CIImage? {
        get {
            var compositeMap: CIImage?
            if features.isEmpty { return inputImage}

            if (inputFeatureSelect >= 0)  {
                // select just one feature
                addToComposite(inputFeatureSelect, &compositeMap)}
            else {
                for i in displayFeatures! {
                // add all the features
                addToComposite(i, &compositeMap)
                }
            }
          
            if let theBlend = blendFace(startImage: inputImage!, shadeMap: compositeMap) {
                return theBlend
            } else {return inputImage}

        }
    }

    func setCIContext(detectorContext: CIContext?) {
        // pass on the context for the  detectorFilter.detector
        
//       let detector = PGLDetector(ciFilter: PGLFaceCIFilter())
//        detector.setCIContext(detectorContext: detectorContext)
//        detectors.append(detector)
    }

    func addMap(_ newMap: CIImage, toImage: CIImage?) -> CIImage? {
        if toImage == nil { return newMap}
        if let compositeFilter = CIFilter(name: "CIMinimumCompositing") { // "CISubtractBlendMode" gave blurring to faces
            compositeFilter.setValue(newMap, forKey: kCIInputImageKey)
            compositeFilter.setValue(  toImage, forKey: kCIInputBackgroundImageKey)
            let myMapOutput = compositeFilter.outputImage

            return myMapOutput
        } else { return newMap}
    }

    func faces() -> [PGLFaceBounds] {
          return features
//        return (detector?.features(in: inputImage!))!
    }

    func faceCenter(_ aFace: PGLFaceBounds) -> CIVector {

        let faceBox = aFace.boundingBox(withinImageBounds: inputImage!.extent)
        let xCenter: CGFloat = faceBox.origin.x + faceBox.size.width/2.0
        let yCenter: CGFloat = faceBox.origin.y + faceBox.size.height/2.0
        return CIVector(x: xCenter, y: yCenter)
    }

    func faceHighlight(aFace: PGLFaceBounds ) -> CIImage? {
        if inputImage == nil { return inputImage}
        let faceBox = aFace.boundingBox(withinImageBounds: inputImage!.extent)
        if let faceShadeMap = CIFilter(name: "CIRadialGradient") {
            let longDimension = max(faceBox.size.width, faceBox.size.height)

            faceShadeMap.setValue(longDimension * 0.7 , forKey:"inputRadius0")
                // sharp region
            faceShadeMap.setValue(longDimension * 1.5 ,forKey:"inputRadius1" )
                // blurred region  larger than sharp inputRadius0
            faceShadeMap.setValue(faceCenter(aFace), forKey: "inputCenter")

            faceShadeMap.setValue(transparentGreen , forKey: "inputColor0") //transparentGreen
            faceShadeMap.setValue(  opaqueGreen , forKey: "inputColor1")

//            inputRadius = (longDimension / 2.0) as NSNumber  // inputRadius used by the CIMaskedVariablBluer in blendFace
            let faceMapImage = faceShadeMap.outputImage
            return faceMapImage
        } else {return inputImage}
    }

    func blendFace(startImage: CIImage, shadeMap: CIImage?) -> CIImage? {
        if shadeMap == nil { return startImage}
        startImage.clampedToExtent()
        if let faceBlend = CIFilter(name: "CIMaskedVariableBlur") {  // or Gaussian Blur??
            faceBlend.setValue(startImage  ,forKey: kCIInputImageKey)
            faceBlend.setValue( shadeMap  , forKey: "inputMask")
            faceBlend.setValue(inputRadius, forKey: kCIInputRadiusKey)

            return faceBlend.outputImage?.cropped(to: (inputImage?.extent)!)
        } else {return startImage}
    }

}
