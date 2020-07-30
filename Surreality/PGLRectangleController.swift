//
//  PGLRectangleController.swift
//  Glance
//
//  Created by Will on 2/12/18.
//  Copyright © 2018 Will. All rights reserved.
//

import UIKit
import MetalKit

enum Mode {
    case move, resize
}
enum Vertex: Int {
    case upperLeft = 0
    case upperRight = 1
    case lowerLeft = 2
    case lowerRight = 3
}

class PGLRectangleController: UIViewController {
// may make a super class for more general parm controller work
// for the color and point parms the ParmTableViewController is working with the attribute directly
// 
// provides draggable and resizing rectangle over the image for filter parms
// use with CICrop filter (and others)
// 2/12/18  WL-B

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
*/


     var filterMode = Mode.move
     var resizeCorner: Vertex?

     var corners = [UIBezierPath]()
     var cornerRects = [CGRect]()
     var tapGesture: UITapGestureRecognizer?
     let rectLineWidth:CGFloat = 12.0

    @IBOutlet var frameImageView: PGLFramedView! {
        didSet {
//            frameImageView.initFrame()
        }
    }
    @IBOutlet weak var upperLeft: UIView!
    @IBOutlet weak var upperRight: UIView!

    @IBOutlet weak var lowerLeft: UIView!
    @IBOutlet weak var lowerRight: UIView!


    var thisCropAttribute: PGLAttributeRectangle? {
        didSet{
            // moving UI rect frameImageView
            thisCropAttribute?.filterRect = frameImageView.frame
        }
    }
    var croppingFilter: PGLRectangleFilter? {
        didSet {
            if thisCropAttribute == nil {
                NSLog("PGLRectangleController thisCropAttribute is nil")
            }
            croppingFilter?.cropAttribute = thisCropAttribute

        }
    }

    lazy var controlViewCorners = [upperLeft, upperRight, lowerLeft, lowerRight]

    var scaleTransform: CGAffineTransform?

     // MARK: movement

    func hitTestCorners(location: CGPoint, controlView: UIView) -> CGRect? {
        // if point is in a corner return return it or nil
        // for aCorner in cornerRects {
//        NSLog("PGLFilterAttributeRectangle #hitTestCorners start location = \(location)")
        filterMode = Mode.move // rect defaults to not resizing.. just moving
        resizeCorner = nil

//        assert(controlViewCorners.count == 4)
        for i in Vertex.upperLeft.rawValue...Vertex.lowerRight.rawValue {
            //            if cornerRects[i].contains(location){
            if (controlViewCorners[i]?.frame.contains(location))! {
                filterMode = Mode.resize
                resizeCorner = Vertex(rawValue: i)
                NSLog("PGLFilterAttributeRectangle #hitTestCorners found corner = \(String(describing: Vertex(rawValue: i)))")
                NSLog("PGLFilterAttributeRectangle #hitTestCorners filterMode = \(filterMode)")
               return controlViewCorners[i]?.frame
            }
        }
        NSLog("PGLFilterAttributeRectangle #hitTestCorners filterMode = \(filterMode)")
        return nil

    }

    func movingChange(startPoint: CGPoint, newPoint: CGPoint, inView: UIView) {
        if thisCropAttribute != nil {
        switch filterMode {

            case Mode.move:
                    thisCropAttribute?.movingChange(startPoint: startPoint, newPoint: newPoint, inView: inView)
            case Mode.resize: if(resizeCorner != nil )
                    {thisCropAttribute?.movingCorner(atCorner: resizeCorner!, startPoint: startPoint, newPoint: newPoint) }
            }
        updateFrame()
        }
    }
    func panEnded(startPoint: CGPoint, newPoint: CGPoint, inView: UIView) -> CGRect {
        // rect controller knows the mode and target corner for changing the rect attribute
        // PGLView is the glkView with LLO system

        return frameImageView.frame  // if the moving change worked and this method does nothing but answer the frame
        
    }

    func setCorners(isHidden: Bool) {
        for aCornerView in controlViewCorners {
            aCornerView?.isHidden = isHidden
        }
    }

    func updateFrame() {
        //assumes the cropAttribute filter frame or origin have been updated by the pan or resize
        //copy into the UI
        if let newFrame = (thisCropAttribute?.filterRect) {
            // filterRect is really  the frame in the superview coordinates.

//           NSLog("PGLRectangleController #updateFrame frameImageView.frame = \(frameImageView.frame)")
            frameImageView.frame = newFrame
//            NSLog("PGLRectangleController #updateFrame changed to frameImageView.frame = \(frameImageView.frame)")
//           frameImageView.setNeedsDisplay()
            //" If you simply change the geometry of the view, the view is typically not redrawn. Instead, its existing content is adjusted based on the value in the view’s contentMode property. Redisplaying the existing content improves performance by avoiding the need to redraw content that has not changed."
        }
    }

}

class PGLFramedView: UIImageView {
   let rectLineWidth:CGFloat = 12.0

    func initFrame() {
        image = rectImage(imageRect: bounds)
        highlightedImage = rectHighLight(imageRect: bounds)


    }
    func rectImage(imageRect: CGRect, fillColor: UIColor = UIColor.groupTableViewBackground) -> UIImage {

        let renderer = UIGraphicsImageRenderer(size: imageRect.size)

        let image = renderer.image { rendererContext in
            let rectPath = UIBezierPath(rect: imageRect)
            rectPath.lineWidth = rectLineWidth
            rectPath.stroke()
        }
        return image
    }

    func rectHighLight(imageRect: CGRect, fillColor: UIColor = UIColor.groupTableViewBackground) -> UIImage {

        NSLog("PGLFramedView #rectHighLight")

        let lineWidth = rectLineWidth

        let renderer = UIGraphicsImageRenderer(size: imageRect.size)

        let image = renderer.image { rendererContext in
            let cgContext = rendererContext.cgContext
            cgContext.setStrokeColor(UIColor.black.cgColor)
            cgContext.setFillColor(UIColor.blue.cgColor) // makes the highlight stand out
            let rectPath = UIBezierPath(rect: imageRect)
            rectPath.lineWidth = lineWidth

            rectPath.stroke()
            rectPath.fill() // the fill color for highlight
            NSLog("PGLControlVisual#rectImageHighLight path = \(rectPath)" )
        }
        return image
    }

}
