//
//  PGLRectangleController.swift
//  Glance
//
//  Created by Will on 2/12/18.
//  Copyright © 2018 Will. All rights reserved.
//

import UIKit
import MetalKit
import os

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
//    var cornerRects = [CGRect]()
    // bizarre this var cornerRects has no refs but commenting it out
    // makes the crop corners show for the crop filter
    // AND makes the crop corners not visible for the other inputRectangle filters
    // such as DepthBlurEffecto or Ripple
    // defining the var reverses the effect - Ripple is visible corners and crop is NOT
//     var tapGesture: UITapGestureRecognizer?
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
                Logger(subsystem: LogSubsystem, category: LogCategory).error("PGLRectangleController thisCropAttribute is nil")
            }
            croppingFilter?.cropAttribute = thisCropAttribute

        }
    }

    lazy var controlViewCorners = [upperLeft, upperRight, lowerLeft, lowerRight]

    var scaleTransform: CGAffineTransform?

    // view lifecycle
    override func viewDidLoad() {
        Logger(subsystem: LogSubsystem, category: LogNavigation).info("\( String(describing: self) + "-" + #function)")
        view.translatesAutoresizingMaskIntoConstraints = true
         // this turns on error notice in the log of UIViewAlertForUnsatisfiableConstraints on one constraint
        // but value of false and the whole crop rectangle does not work..
        // (Note: If you're seeing NSAutoresizingMaskLayoutConstraints that you don't understand, refer to the documentation
        //         for the UIView property translatesAutoresizingMaskIntoConstraints)

        if controlViewCorners.isEmpty {
            Logger(subsystem: LogSubsystem, category: LogCategory).error("PGLRectangleController does not have cornerRects...")
        }
    }
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
//                NSLog("PGLFilterAttributeRectangle #hitTestCorners found corner = \(String(describing: Vertex(rawValue: i)))")
//                NSLog("PGLFilterAttributeRectangle #hitTestCorners filterMode = \(filterMode)")
               return controlViewCorners[i]?.frame
            }
        }
//        Logger(subsystem: LogSubsystem, category: LogCategory).notice("PGLFilterAttributeRectangle #hitTestCorners filterMode = \(filterMode)")
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
//            NSLog("PGLRectangleController #setCorners \(isHidden) on \(String(describing: aCornerView))")
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
    func rectImage(imageRect: CGRect, fillColor: UIColor = UIColor.systemGroupedBackground) -> UIImage {

        let renderer = UIGraphicsImageRenderer(size: imageRect.size)

        let image = renderer.image { rendererContext in
            let rectPath = UIBezierPath(rect: imageRect)
            rectPath.lineWidth = rectLineWidth
            rectPath.stroke()
        }
//        NSLog("PGLFramedView rectImage fillCollor")
        return image
    }

    func rectHighLight(imageRect: CGRect, fillColor: UIColor = UIColor.systemGroupedBackground) -> UIImage {

//        NSLog("PGLFramedView #rectHighLight")

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
            Logger(subsystem: LogSubsystem, category: LogCategory).debug("PGLFramedView #rectImageHighLight path = \(rectPath)" )
        }
        return image
    }

}
