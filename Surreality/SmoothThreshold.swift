//
//  SmoothThreshold.swift
// Richard Hoeper
//  Sample of fix for  “unexpected type 'vec4' (should be a sampler type)”
// This is before from 5/18/2018
//
//

import UIKit

class SmoothThreshold: CIFilter
{
    @objc var inputImage : CIImage?
    @objc var inputEdgeO: CGFloat = 0.25
    @objc var inputEdge1: CGFloat = 0.75

    override var attributes: [String : Any]
    {
        return [
            kCIAttributeFilterDisplayName: "B/W Smooth Threshold" as AnyObject,
            "inputImage": [kCIAttributeIdentity: 0,
                           kCIAttributeClass: "CIImage",
                           kCIAttributeDisplayName: "Image",
                           kCIAttributeType: kCIAttributeTypeImage],
            "inputEdgeO": [kCIAttributeIdentity: 0,
                           kCIAttributeClass: "NSNumber",
                           kCIAttributeDefault: 0.25,
                           kCIAttributeDisplayName: "Edge 0",
                           kCIAttributeMin: 0.0,
                           kCIAttributeSliderMin: 0.0,
                           kCIAttributeSliderMax: 1.0,
                           kCIAttributeType: kCIAttributeTypeScalar],
            "inputEdge1": [kCIAttributeIdentity: 0,
                           kCIAttributeClass: "NSNumber",
                           kCIAttributeDefault: 0.75,
                           kCIAttributeDisplayName: "Edge 1",
                           kCIAttributeMin: 0.0,
                           kCIAttributeSliderMin: 0.0,
                           kCIAttributeSliderMax: 1.0,
                           kCIAttributeType: kCIAttributeTypeScalar]
        ]
    }

    let colorKernel = CIKernel(source:
        "kernel vec4 color(sampler pixel, float inputEdgeO, float inputEdge1)" +
            "{" +
            " float pixalpha;" +
            " pixalpha = sample(pixel, samplerCoord(pixel)).a;" +
            " float luma = dot(sample(pixel, samplerCoord(pixel)).rgb, vec3(0.2126, 0.7152, 0.0722));" +
            " float threshold = smoothstep(inputEdgeO, inputEdge1, luma);" +
            " return vec4(threshold, threshold, threshold, pixalpha);" +
        "}"
    )

    override var outputImage: CIImage!
    {
        guard let inputImage = inputImage,
            let colorKernel = colorKernel else
        {
            return nil
        }

        let extent = inputImage.extent
        let arguments = [inputImage,
                         min(inputEdgeO, inputEdge1),
                         max(inputEdgeO, inputEdge1),] as [Any]

        return colorKernel.apply(extent: extent,
                                 roiCallback: {
                                    (index, rect) in
                                    return rect
        },
                                 arguments: arguments)
    }
}
