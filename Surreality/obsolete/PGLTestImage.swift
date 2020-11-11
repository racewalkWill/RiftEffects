//
//  PGLTestImage.swift
//  Glance
//
//  Created by Will on 5/27/18.
//  Copyright © 2018 Will. All rights reserved.
//

import Foundation
import CoreImage
import UIKit

enum Coordinate  {
    case ULO, LLO
}

class PGLTestImage {
    // provides UIImage for testing

 class func gridImage(withSize size: CGSize, axisInterval: CGFloat = 50.0 * 2 , origin: Coordinate = Coordinate.LLO, fillColor: UIColor = UIColor.systemGroupedBackground ) -> CIImage {
    var point1 = CGPoint.zero
    var point2 = CGPoint.zero
    var gridPoint = CGPoint.zero


    let renderer = UIGraphicsImageRenderer(size: size)
//    NSLog("PGLFilterStack #gridImage axisInterval = \(axisInterval)")
//    NSLog("PGLFilterStack #gridImage size = \(size)")
    let grids = renderer.image { rendererContext in
        let cgContext = rendererContext.cgContext
        //            cgContext.setFillColor(fillColor.cgColor)
        // flip & scale context
        if origin == Coordinate.LLO {
            cgContext.translateBy(x: 0.0, y: size.height)
            cgContext.scaleBy(x: 1.0, y: -1.0)
        } else {
            // Coordinate.ULO

        }

        cgContext.setLineWidth(1.0)
        cgContext.setStrokeColor(UIColor.black.cgColor)
        cgContext.setLineWidth(0.5)
        cgContext.clip(to: CGRect(origin: CGPoint.zero, size: size))
        cgContext.setFillColor(UIColor.lightGray.cgColor)

        let outLineRect = CGRect(origin: point1, size: size)
        cgContext.stroke(outLineRect)
        cgContext.fill(outLineRect)

        cgContext.beginPath()

        for verticalTick in stride(from: 0.0 as CGFloat, to: size.height, by: axisInterval) {
            // horizontal axis lines
            point1 = CGPoint(x: 0.0, y: verticalTick) // (0.0, 0.0), (0.0, 20.0)..(0.0, 1780.0)
            point2 = CGPoint(x: size.width, y: verticalTick) // (780.0, 0.0), (780.0, 20.0)..(780.0, 1780.0)
            cgContext.move(to: point1)
            cgContext.addLine(to: point2)


        }
        for horizontalTick in stride(from: 0.0 as CGFloat, to: size.width, by: axisInterval) {
        // vertical axis lines
            point1 = CGPoint(x: horizontalTick, y: 0.0) // (0.0, 0.0), (20.0, 0.0)..(780.0, 0)
            point2 = CGPoint(x: horizontalTick, y: size.height)
            cgContext.move(to: point1)
            cgContext.addLine(to: point2)

        }

        cgContext.strokePath()



         cgContext.beginPath()

        var gridPointLabel = CGPoint.zero
        if origin == Coordinate.ULO {
            //flip the ends
        }
        let vertStart: CGFloat = 0.0
        let horzStart: CGFloat = 0.0
        let vertEnd: CGFloat = size.height
        let horzEnd: CGFloat = size.width

        for verticalTick in stride(from: vertStart , to: vertEnd, by: axisInterval) {
            for horizontalTick in stride(from: horzStart, to: horzEnd , by: axisInterval) {
                gridPointLabel = CGPoint(x: horizontalTick, y: verticalTick) // ( (20.0, 20.0),(40.0, 20.0),(60.0, 20.0)..(20.0, 40.0),(40.0, 40.0),(60.0, 40.0)
                gridPoint = gridPointLabel
                drawPointLabel(drawingContext: cgContext, point: gridPoint, pointLabel: "\(gridPointLabel)")
            }
        }
        cgContext.strokePath()

        if origin == Coordinate.LLO {
            // restore the context
            cgContext.translateBy(x: 0.0, y: size.height * -1.0)
            cgContext.scaleBy(x: 1.0, y: 1.0)

        } else { //Coordinate.ULO
        }

    }
//    NSLog("PGLFilterStack #gridImage grids = \(grids)")
    return CIImage(image: grids)!
    }

    class func drawPointLabel(drawingContext: CGContext,point: CGPoint , pointLabel: String) {
        let attrString = NSAttributedString(string: pointLabel)  // uses default font/size
        let line = CTLineCreateWithAttributedString(attrString)

        // Set text position and draw the line into the graphicsdrawingContext
        let labelPosition = CGPoint(x: point.x + 2, y: point.y + 5)

        drawingContext.textPosition = labelPosition
        CTLineDraw(line,drawingContext)

    }

}
