//
//  PGLControlVisual.swift
//  Glance
//
//  Created by Will on 11/27/17.
//  Copyright © 2017 Will. All rights reserved.
//  Based on VisuallyRichUX sample app file StarPolygonRenderer.swift
/* StarPolygonRenderer.swift
 Copyright © 2017 Apple Inc.

 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.



 Abstract:
 This is a utility class that uses UIGraphicsImageRenderer and Core Graphics to draw star-shaped regular polygon images.
 */

import UIKit

class PGLControlRenderer {
    class func starImage(withSize size: CGSize, fillColor: UIColor = UIColor.groupTableViewBackground, pointCount: Int = 5, radiusRatio: CGFloat = 0.382) -> UIImage {
        let outerRadius = min(size.width, size.height) / 2
        let innerRadius = outerRadius * radiusRatio

        let centerX = size.width / 2
        let centerY = size.height / 2

        let renderer = UIGraphicsImageRenderer(size: size)

        let image = renderer.image { rendererContext in
            let cgContext = rendererContext.cgContext
            cgContext.setFillColor(fillColor.cgColor)
            cgContext.setStrokeColor(UIColor.yellow.cgColor)

            let angleStride = (2 * CGFloat.pi) / CGFloat(pointCount)

            var outerAngle = CGFloat.pi / 2
            var innerAngle = outerAngle - (angleStride / 2)

            let topPoint = CGPoint(x: centerX + outerRadius * cos(outerAngle),
                                   y: centerY - outerRadius * sin(outerAngle))
            cgContext.move(to: topPoint)

            for _ in 0..<pointCount {
                outerAngle += angleStride
                innerAngle += angleStride

                let innerPoint = CGPoint(x: centerX + innerRadius * cos(innerAngle),
                                         y: centerY - innerRadius * sin(innerAngle))
                cgContext.addLine(to: innerPoint)

                let outerPoint = CGPoint(x: centerX + outerRadius * cos(outerAngle),
                                         y: centerY - outerRadius * sin(outerAngle))
                cgContext.addLine(to: outerPoint)
            }

            cgContext.fillPath()
        }

        return image
    }

    class func starImageHighLight(withSize size: CGSize, fillColor: UIColor = UIColor.groupTableViewBackground, pointCount: Int = 5, radiusRatio: CGFloat = 0.382) -> UIImage {
        let outerRadius = min(size.width, size.height) / 2
        let innerRadius = outerRadius * radiusRatio

        let centerX = size.width / 2
        let centerY = size.height / 2

        let renderer = UIGraphicsImageRenderer(size: size)

        let image = renderer.image { rendererContext in
            let cgContext = rendererContext.cgContext
//            cgContext.setFillColor(fillColor.cgColor)
            cgContext.setFillColor(UIColor.blue.cgColor)
            cgContext.setStrokeColor(UIColor.yellow.cgColor)

            let angleStride = (2 * CGFloat.pi) / CGFloat(pointCount)

            var outerAngle = CGFloat.pi / 2
            var innerAngle = outerAngle - (angleStride / 2)

            let topPoint = CGPoint(x: centerX + outerRadius * cos(outerAngle),
                                   y: centerY - outerRadius * sin(outerAngle))
            cgContext.move(to: topPoint)

            for _ in 0..<pointCount {
                outerAngle += angleStride
                innerAngle += angleStride

                let innerPoint = CGPoint(x: centerX + innerRadius * cos(innerAngle),
                                         y: centerY - innerRadius * sin(innerAngle))
                cgContext.addLine(to: innerPoint)

                let outerPoint = CGPoint(x: centerX + outerRadius * cos(outerAngle),
                                         y: centerY - outerRadius * sin(outerAngle))
                cgContext.addLine(to: outerPoint)
            }

            cgContext.fillPath()
        }

        return image
    }
}





