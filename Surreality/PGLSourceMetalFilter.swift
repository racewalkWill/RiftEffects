//
//  PGLSourceMetalFilter.swift
//  Glance
//
//  Created by Will L-B on 3/17/19.
//  Copyright © 2019 Will Loew-Blosser. All rights reserved.
//

//
//  WarpItMetalFilter.swift
//  Filterpedia iOS
//
//  Created by Will on 3/20/19.
//  Copyright © 2019 Simon Gladman. All rights reserved.
//
// IMPORTANT
//  metal ciKernels requires metal compiler flags -fcikernel and user defined flag -cikernel
//  these flags turn off compile of metal shader functions... custom build command line needed?
//  if both are required ?

import CoreImage

class MetalLib {
    private static var url = Bundle.main.url(forResource: "default", withExtension: "metallib")!
    static var data = try! Data(contentsOf: url)
}

class WarpItMetalFilter: CIFilter {
    class func register() {
        CIFilter.registerName(kPWarpItMetal,
                              constructor: PGLFilterConstructor(),
                              classAttributes: WarpItMetalFilter.customAttributes() )
    }

    @objc    class func customAttributes() -> [String: Any] {
        let customDict:[String: Any] = [
            kCIAttributeFilterDisplayName : "WarpItMetal",

            kCIAttributeFilterCategories :
                [kCICategoryBlur],

            "inputImage": [kCIAttributeIdentity: 0,
                           kCIAttributeClass: "CIImage",
                           kCIAttributeDisplayName: "Image",
                           kCIAttributeType: kCIAttributeTypeImage],


            "inputCenterPoint": [
                            kCIAttributeClass: "CIVector",
                            kCIAttributeDisplayName: "Effect Center",
                            kCIAttributeType: kCIAttributeTypePosition,
                            kCIAttributeDefault: CIVector(x: 0.1, y: 0.1)],

            "inputFactor": [kCIAttributeIdentity: 0,
                            kCIAttributeClass: "NSNumber",
                            kCIAttributeDefault: 0.0,
                            kCIAttributeDisplayName: "Factor",
                            kCIAttributeMin: -10.0,
                            kCIAttributeSliderMin: -10.0,
                            kCIAttributeSliderMax: 10.0,
                            kCIAttributeType: kCIAttributeTypeScalar]
        ]
        return customDict
    }


    @objc var inputImage: CIImage?
    @objc var inputCenterPoint: CIVector = CIVector(x: 0.0, y: 0.0)
    @objc var inputFactor: Float = 0.0

    private let kernel = try? CIWarpKernel(functionName: "crtWarp", fromMetalLibraryData: MetalLib.data)

    override func setDefaults() {
        inputCenterPoint = CIVector(x: 0.0, y: 0.0)
        inputFactor = 0.0
    }

    override var outputImage: CIImage? {
        guard let kernel = kernel, let inputImage = inputImage else { abort() }

        let extent = inputImage.extent

        let arguments = [CIVector(x: extent.width, y: extent.height), inputFactor, inputCenterPoint] as [Any]

        let myKernelOutput = kernel.apply(extent: extent,
                                          roiCallback: {
                                            (index, rect) in
//                                            NSLog("roiCallback index = \(index), rect = \(rect) " )
//                                            let answer = CGRect(x: 0.0, y: 0.0, width: extent.height/2, height: extent.width/2 )
//                                            NSLog("roiCallback answer = \(answer) " )
                                            return rect
        },
                                          image: inputImage, arguments: arguments)

        return myKernelOutput // ?.clamped(to: extent)
    }

    func regionOf(rect: CGRect, vector: CIVector) -> CGRect {
        return rect.insetBy(dx: -abs(vector.x), dy: -abs(vector.y))
    }



}
