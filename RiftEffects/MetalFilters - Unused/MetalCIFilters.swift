//
//  MetalCIFilters.swift
//  Glance
//
//  Created by Will on 2/28/19.
//  Copyright © 2019 Will Loew-Blosser All rights reserved.
//

//
//  MetalFilters.swift
//  Filterpedia
//
//  Created by Simon Gladman on 24/01/2016.
//  Copyright © 2016 Simon Gladman. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.

//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>

// THE METAL SHADER KERNELS are not compiled when the -cikernel flags are set..
// COMMENTED OUT the filters.. and MetalFilter class

//import CoreImage
//import MetalKit
//
//// MARK: MetalPixellateFilter
//class PGLMetalPincushion: MetalFilter {
//    class func register() {
//        CIFilter.registerName("Pincushion",
//                              constructor: PGLFilterConstructor(),
//                              classAttributes: PGLMetalPincushion.customAttributes() )
//    }
//    
//    @objc  class func customAttributes() -> [String: Any] {
//            let customDict:[String: Any] = [
//                kCIAttributeFilterDisplayName: "Pincushion",
//                kCIAttributeFilterCategories: [kCICategoryBlur],
//                
//                "inputImage": [kCIAttributeIdentity: 0,
//                               kCIAttributeClass: "CIImage",
//                               kCIAttributeDisplayName: "Image",
//                               kCIAttributeType: kCIAttributeTypeImage],
//                
//                "inputCenterPoint": [kCIAttributeIdentity: 0, // sets metal buffer position
//                                    kCIAttributeClass: "CIVector",
//                                    kCIAttributeDisplayName: "Effect Center",
//
//                                    kCIAttributeType: kCIAttributeTypePosition],
//                
//                "inputFactor": [kCIAttributeIdentity: 1,  // sets metal buffer position
//                                     kCIAttributeClass: "NSNumber",
//                                     kCIAttributeDefault: 0.1,
//                                     kCIAttributeDisplayName: "Factor",
//                                     kCIAttributeMin: -5.0,
//                                     kCIAttributeSliderMin: -5.0,
//                                     kCIAttributeSliderMax: 5.0]
////                                     kCIAttributeType: kCIAttributeTypeScalar]
//
//            ]
//            return customDict
//    }
//    
//    @objc var inputImage: CIImage?
//    @objc var inputCenterPoint: CIVector = CIVector(x: 0.1, y: 0.1)
//    @objc var inputFactor: Float = 0.1
//    
//    override func setDefaults() {
//        inputCenterPoint = CIVector(x: 0.1, y: 0.1)
//        inputFactor = 0.1
//    }
//    
//    convenience init() {
//        self.init(kernelFunctionName: "pincushion")
//    }
//    
//    override init(kernelFunctionName: String) {
//        super.init(kernelFunctionName: kernelFunctionName  )
//    }
//    
//    required init?(coder aDecoder: NSCoder)
//    {
//        fatalError("init(coder:) has not been implemented")
//    }
//}
//
//class MetalPixellateFilter: MetalFilter
//{      class func register() {
//        CIFilter.registerName("Pixellate",
//                          constructor: PGLFilterConstructor(),
//                          classAttributes: MetalPixellateFilter.customAttributes() )
//}
//  
//    @objc  class func customAttributes() -> [String: Any] {
//        let customDict:[String: Any] = [
//            kCIAttributeFilterDisplayName: "Metal Pixellate",
//            kCIAttributeFilterCategories: [kCICategoryBlur],
//
//            "inputImage": [kCIAttributeIdentity: 0,
//                           kCIAttributeClass: "CIImage",
//                           kCIAttributeDisplayName: "Image",
//                           kCIAttributeType: kCIAttributeTypeImage],
//
//            "inputPixelWidth": [kCIAttributeIdentity: 0,
//                                kCIAttributeClass: "NSNumber",
//                                kCIAttributeDefault: 50,
//                                kCIAttributeDisplayName: "Pixel Width",
//                                kCIAttributeMin: 0,
//                                kCIAttributeSliderMin: 0,
//                                kCIAttributeSliderMax: 100,
//                                kCIAttributeType: kCIAttributeTypeScalar],
//
//            "inputPixelHeight": [kCIAttributeIdentity: 1,
//                                 kCIAttributeClass: "NSNumber",
//                                 kCIAttributeDefault: 25,
//                                 kCIAttributeDisplayName: "Pixel Height",
//                                 kCIAttributeMin: 0,
//                                 kCIAttributeSliderMin: 0,
//                                 kCIAttributeSliderMax: 100,
//                                 kCIAttributeType: kCIAttributeTypeScalar]
//
//        ]
//        return customDict
//    }
//
//    convenience init() {
//        self.init(kernelFunctionName: "pixellate")
//    }
//
//    override init(kernelFunctionName: String) {
//        super.init(kernelFunctionName: kernelFunctionName  )
//    }
//
//    required init?(coder aDecoder: NSCoder)
//    {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    @objc var inputImage: CIImage?
//    @objc var inputPixelWidth: CGFloat = 50
//    @objc var inputPixelHeight: CGFloat = 25
//
//    override func setDefaults()
//    {
//        inputPixelWidth = 50
//        inputPixelHeight = 25
//    }
//}
//
//// MARK: Perlin Noise
//
//class MetalPerlinNoise: MetalFilter
//{
//     class func register() {
////      filter does not produce image on parm changes  WL-B 3/7/19
////        CIFilter.registerName("PerlinNoise",
////                            constructor: PGLFilterConstructor(),
////                            classAttributes: MetalPerlinNoise.customAttributes())
//    }
//
//    @objc  class func customAttributes() -> [String: Any] {
//        let customDict:[String: Any] = [
//
//            kCIAttributeFilterCategories: [kCICategoryBlur],
//
//            kCIAttributeFilterDisplayName: "Perlin Noise",
//
//            "inputReciprocalScale": [kCIAttributeIdentity: 0,
//                                     kCIAttributeClass: "NSNumber",
//                                     kCIAttributeDefault: 50,
//                                     kCIAttributeDisplayName: "Scale",
//                                     kCIAttributeMin: 10,
//                                     kCIAttributeSliderMin: 10,
//                                     kCIAttributeSliderMax: 100,
//                                     kCIAttributeType: kCIAttributeTypeScalar],
//
//            "inputOctaves": [kCIAttributeIdentity: 1,
//                             kCIAttributeClass: "NSNumber",
//                             kCIAttributeDefault: 2,
//                             kCIAttributeDisplayName: "Octaves",
//                             kCIAttributeMin: 1,
//                             kCIAttributeSliderMin: 1,
//                             kCIAttributeSliderMax: 16,
//                             kCIAttributeType: kCIAttributeTypeScalar],
//
//            "inputPersistence": [kCIAttributeIdentity: 2,
//                                 kCIAttributeClass: "NSNumber",
//                                 kCIAttributeDefault: 0.5,
//                                 kCIAttributeDisplayName: "Persistence",
//                                 kCIAttributeMin: 0,
//                                 kCIAttributeSliderMin: 0,
//                                 kCIAttributeSliderMax: 1,
//                                 kCIAttributeType: kCIAttributeTypeScalar],
//
//            "inputColor0": [kCIAttributeIdentity: 3,
//                            kCIAttributeClass: "CIColor",
//                            kCIAttributeDefault: CIColor(red: 0.5, green: 0.25, blue: 0),
//                            kCIAttributeDisplayName: "Color One",
//                            kCIAttributeType: kCIAttributeTypeColor],
//
//            "inputColor1": [kCIAttributeIdentity: 4,
//                            kCIAttributeClass: "CIColor",
//                            kCIAttributeDefault: CIColor(red: 0, green: 0, blue: 0.15),
//                            kCIAttributeDisplayName: "Color Two",
//                            kCIAttributeType: kCIAttributeTypeColor],
//
//            "inputZ": [kCIAttributeIdentity: 5,
//                       kCIAttributeClass: "NSNumber",
//                       kCIAttributeDefault: 1,
//                       kCIAttributeDisplayName: "Z Position",
//                       kCIAttributeMin: 0,
//                       kCIAttributeSliderMin: 0,
//                       kCIAttributeSliderMax: 1024,
//                       kCIAttributeType: kCIAttributeTypeScalar],
//
//            "inputWidth": [kCIAttributeIdentity: 2,
//                           kCIAttributeClass: "NSNumber",
//                           kCIAttributeDefault: 640,
//                           kCIAttributeDisplayName: "Width",
//                           kCIAttributeMin: 100,
//                           kCIAttributeSliderMin: 100,
//                           kCIAttributeSliderMax: 2048,
//                           kCIAttributeType: kCIAttributeTypeScalar],
//
//            "inputHeight": [kCIAttributeIdentity: 2,
//                            kCIAttributeClass: "NSNumber",
//                            kCIAttributeDefault: 640,
//                            kCIAttributeDisplayName: "Height",
//                            kCIAttributeMin: 100,
//                            kCIAttributeSliderMin: 100,
//                            kCIAttributeSliderMax: 2048,
//                            kCIAttributeType: kCIAttributeTypeScalar]
//
//        ]
//        return customDict
//    }
//
//    convenience init() {
//        self.init(kernelFunctionName: "perlin")
//    }
//
//    override init(kernelFunctionName: String) {
//        super.init(kernelFunctionName: kernelFunctionName  )
//    }
//
//    required init?(coder aDecoder: NSCoder)
//    {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    @objc var inputReciprocalScale = CGFloat(50)
//    @objc var inputOctaves = CGFloat(2)
//    @objc var inputPersistence = CGFloat(0.5)
//
//    @objc var inputColor0 = CIColor(red: 0.5, green: 0.25, blue: 0)
//    @objc var inputColor1 = CIColor(red: 0, green: 0, blue: 0.15)
//
//    @objc var inputZ = CGFloat(0)
//
//    override func setDefaults()
//    {
//        inputReciprocalScale = 50
//        inputOctaves = 2
//        inputPersistence = 0.5
//
//        inputColor0 = CIColor(red: 0.5, green: 0.25, blue: 0)
//        inputColor1 = CIColor(red: 0, green: 0, blue: 0.15)
//    }
//
//}
//
//// MARK: MetalKuwaharaFilter
//
//class MetalKuwaharaFilter: MetalFilter
//{
//     class func register() {
//        // filter has performance issue in the kernel function WL-B 3/7/19
////        CIFilter.registerName("Kuwahara",
////                              constructor: PGLFilterConstructor(),
////                              classAttributes:  MetalKuwaharaFilter.customAttributes())
//    }
//
//    @objc    class func customAttributes() -> [String: Any] {
//        let customDict:[String: Any] = [
//            kCIAttributeFilterDisplayName : "Kuwahara",
//
//            kCIAttributeFilterCategories :
//                [kCICategoryBlur, kCICategoryVideo, kCICategoryInterlaced, kCICategoryNonSquarePixels, kCICategoryStillImage],
//
//            "inputImage": [kCIAttributeIdentity: 0,
//                           kCIAttributeClass: "CIImage",
//                           kCIAttributeDisplayName: "Image",
//                           kCIAttributeType: kCIAttributeTypeImage],
//
//            "inputRadius": [kCIAttributeIdentity: 0,
//                            kCIAttributeClass: "NSNumber",
//                            kCIAttributeDefault: 15,
//                            kCIAttributeDisplayName: "Radius",
//                            kCIAttributeMin: 0,
//                            kCIAttributeSliderMin: 0,
//                            kCIAttributeSliderMax: 30,
//                            kCIAttributeType: kCIAttributeTypeScalar]
//        ]
//        return customDict
//    }
//    convenience init() {
//        self.init(kernelFunctionName: "kuwahara")
//    }
//
//    override init(kernelFunctionName: String) {
//        // rules for inheritance must call designated initializer
//        // means
//        super.init(kernelFunctionName: kernelFunctionName  )
//    }
//
//    required init?(coder aDecoder: NSCoder)
//    {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    @objc var inputImage: CIImage?
//    @objc var inputRadius: CGFloat = 15
//
//    override func setDefaults()
//    {
//        inputRadius = 15
//    }
//
//}
//
