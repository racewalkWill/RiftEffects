//
//  PGLVisionDetection.swift
//  Glance
//
//  Created by Will on 6/15/20.
//  Copyright © 2020 Will. All rights reserved.
//

import Photos
import UIKit
import Vision

class PGLVisionDetector: PGLDetection {
    // uses Vision framework to detect faces and features
    // replaces CIDetector in PGLDetector

    enum Direction: Int {
           case forward = 1
           case back = -1
       }

    // MARK: internal vars
    var localFilter: CIFilter?  // filter to produce outputs on the detected features  rename?
    var currentFeatureIndex = 0
      // detector and features vars also used in CIFilterAbstract for the Bump and Face CI filter subclasses
    var inputImage: CIImage?
    var oldInputImage: CIImage?
    lazy var viewCIContext = (UIApplication.shared.delegate as? AppDelegate)?.appStack.getViewerStack().imageCIContext
    var filterAttribute: PGLFilterAttribute?
    var targetInputAttribute: PGLFilterAttributeImage?
    var targetInputTargetAttribute: PGLFilterAttributeImage?
    var  displayFeatures: CountableRange<Int>?

    // MARK: Vision vars
    var faceObservations: [VNFaceObservation]?

    // MARK: protocol PGLDetection
    var features = [PGLFaceBounds]()

    var inputTime: Double = 0.0 // ranges -1.0 to +1.0 for animation
    lazy var faceDetectionRequest = VNDetectFaceRectanglesRequest(completionHandler: self.handleDetectedFaces)

    required init(ciFilter: CIFilter?) {
        localFilter = ciFilter
        // requires setCIContext to function but needs to be sent later
    }

      // MARK: animation
    func setInputTime(time: Double) {
        inputTime = time
    }
    func increment() {
        nextFeature(to: Direction.forward)
    }

    func nextFeature(to: Direction) {
        // 12/2/19 should have a dissolve on incremnent for smooth change to next feature
        // moves upward to features.count. then returns to start at zero
        NSLog("PGLVisionDetector nextFeature start currentFeatureIndex = \(currentFeatureIndex) features.count = \(features.count)")
        currentFeatureIndex += to.rawValue
        if (currentFeatureIndex >= features.count) || (currentFeatureIndex < 0) {
            currentFeatureIndex = 0
        }
//        NSLog("PGLVisionDetector nextFeature end currentFeatureIndex = \(currentFeatureIndex) features.count = \(features.count)")
//        setFeaturePoint()
    }


    func setInput(image: CIImage?, source: String?) {
        // searches for features in the image
         // called every imageUpdate by the PGLFilterStack->filter.setInput->detectors#setInput
         if let anInputImage = image {
            inputImage = anInputImage
            if oldInputImage === inputImage {
                NSLog("PGLVisionDetection #setInput(image: is returning without performing ImageRequestHandler")
                return }
                // === is test of object identity don't process twice
                // CIImage is a class so object identity can be tested
                // this assumes that we have the source ciImage
                // after processing by a filter.. is this true?. doesn't the filter produce
                // a new output image.. so in the case of a chain of filters..
                // this check is useless.

            else { features = [PGLFaceBounds]()
                    // new image clear the old features
            }
        }
      let requests = [faceDetectionRequest] // other requests can be added to the array

        let requestHandler = VNImageRequestHandler(ciImage: inputImage!, orientation: .up , options: [VNImageOption.ciContext: viewCIContext as Any ])

       do {
           try requestHandler.perform(requests)
       } catch let error as NSError {
           print("Failed to perform image request: \(error)")
//           self.presentAlert("Image Request Failed", error: error)
           return
       }

    }

     fileprivate func handleDetectedFaces(request: VNRequest?, error: Error?) {
           if let nsError = error as NSError? {
               self.presentAlert("Face Detection Error", error: nsError)
               return
           }
           // Perform  on the main thread.

//            NSLog( "PGLVisionDetection handleDetectedFaces start")
            self.faceObservations = (request?.results) as? [VNFaceObservation]
                    //first! as! VNFaceObservation
                    // use the boundingBox of the observations
            if self.faceObservations != nil {
                for aFace in self.faceObservations! {
                    self.features.append(PGLFaceBounds(onVNFace: aFace, onCIFace: nil))
                }
                self.displayFeatures = self.features.indices


            // this code from the VisionBasics sample app draws outlines on the detected faces
            // use this to debug the detection mapping
            // this should be performed on the main queue
//               guard let drawLayer = self.pathLayer,
//                   let results = request?.results as? [VNFaceObservation] else {
//                       return
//               }
//               self.draw(faces: results, onImageWithBounds: drawLayer.bounds)
//               drawLayer.setNeedsDisplay()
           }
       }
    func presentAlert(_ title: String, error: NSError) {
        NSLog("PGLVisionDetection alert error  = \(title) , \(error)")

         // self.present is for a UIViewController.. this is model object..
        //  just log for the moment
           // Always present alert on main thread.
//           DispatchQueue.main.async {
//               let alertController = UIAlertController(title: title,
//                                                       message: error.localizedDescription,
//                                                       preferredStyle: .alert)
//               let okAction = UIAlertAction(title: "OK",
//                                            style: .default) { _ in
//                                               // Do nothing -- simply dismiss alert.
//               }
//               alertController.addAction(okAction)
//               self.present(alertController, animated: true, completion: nil)
//
//           }
       }

    func setOutputAttributes(wrapperFilter: PGLDissolveWrapperFilter) {
        targetInputAttribute = wrapperFilter.imageInputAttribute()
        targetInputTargetAttribute = wrapperFilter.imageTargetImageAttribute()
    }

    func featureImagePair() -> (inputFeature: CIImage, targetFeature: CIImage) {
        // PGLVisionDetector
        // used for the first setup of the dissolve wrapper
        // answers the internal filter output with two images for a dissolve
        // the dissolve uses inputImage and targetImage
        // current two features are used to set the input attrbute point
        // uses currentFeatureIndex. should increment on increment intervals
        let restoreIndex = currentFeatureIndex
        setFeaturePoint()
        let inputDissolveImage = localFilter?.outputImage
        nextFeature(to: Direction.forward) // moves featureIndex forward or back to zero for looping
        setFeaturePoint()
        let targetDissolveImage = localFilter?.outputImage
        currentFeatureIndex = restoreIndex
        return (inputDissolveImage ?? CIImage.empty(),targetDissolveImage ?? CIImage.empty())
    }

        func setFeaturePoint(){
            // put the center of the first feature into the point value of the attribute
    //         NSLog("PGLVisionDetector setFeaturePoint currentFeatureIndex = \(currentFeatureIndex) features.count = \(features.count)")
            if features.isEmpty {return }
            if currentFeatureIndex >= features.count {return}
            let mainFeature = features[currentFeatureIndex]
            let mainBox = mainFeature.boundingBox(withinImageBounds: inputImage!.extent)
                let centerX = mainBox.midX
                let centerY = mainBox.midY
                let pointVector = CIVector(x:centerX, y: centerY)
                filterAttribute?.set( pointVector)
    //            NSLog("PGLVisionDetector setFeaturePoint = \(pointVector)")

        }

    func nextImage() -> CIImage {
           increment()
            setFeaturePoint()
        return localFilter?.outputImage ?? CIImage.empty()
    }

    func outputFeatureImages() -> [CIImage] {
        // answer a collection of images starting without features and then each feature highlighted.
                var answerImages = [CIImage]()
                guard inputImage != nil  // features are not highlighted
                    else { return answerImages }

        //        answerImages.append(startImage) // put the unaltered image first}
//            NSLog("PGLVisionDetection outputFeatureImages() START ")
                if let myFaceFilter = localFilter as? PGLFilterCIAbstract {
                    guard let myDisplayFeatures = self.displayFeatures
                        else { return answerImages }
                    myFaceFilter.features = features
                    myFaceFilter.displayFeatures = myDisplayFeatures
                    myFaceFilter.inputImage = inputImage
                        // updateValue(value, forKey: kCIInputImageKey)
                    for i in myDisplayFeatures {
                        myFaceFilter.inputFeatureSelect = i
                        if let thisFeatureImage = myFaceFilter.outputImage {
                            answerImages.append(thisFeatureImage)
                        }
                    }
                } else {
                    // not a PGLFilterCIAbstract..which has features set by the detector
                     // here set the the attribute to the feature point and output an image
                    let restoreIndex = currentFeatureIndex
                    for i in 0..<features.count {
                        currentFeatureIndex = i
                        setFeaturePoint()
                        answerImages.append((localFilter?.outputImage)!)
                    }
                    currentFeatureIndex = restoreIndex


                }

                return answerImages
    }

    func setCIContext(detectorContext: CIContext?) {
        viewCIContext = detectorContext
    }

    func releaseContext() {
                // release everything
//       detector = nil
        features = [PGLFaceBounds]()
        localFilter = nil
        inputImage = nil
        oldInputImage = nil

        viewCIContext?.clearCaches()
        viewCIContext = nil
    }

    func releaseTargetAttributes() {
           targetInputTargetAttribute = nil
             targetInputAttribute = nil
    }


}
