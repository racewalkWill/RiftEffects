//
//  PGLMetalController.swift
//  Glance
//
//  Created by Will on 1/20/19.
//  Copyright © 2019 Will Loew-Blosser. All rights reserved.
//


import MetalKit
import CoreGraphics
import UIKit
import simd
import os

class PGLMetalController: UIViewController {

    var appStack: PGLAppStack! = nil  // model object

    var filterStack: () -> PGLFilterStack?  = { PGLFilterStack() } // a function is assigned to this var that answers the filterStack
    var metalRender: Renderer!
        // Metal View setup for Core Image Rendering
        // see listing 1-7 in
        // https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/CoreImaging/ci_tasks/ci_tasks.html#//apple_ref/doc/uid/TP30001185-CH3-SW5

        /// in full screen mode the MetalController uses GestureRecogniziers
    var isFullScreen = false
    override var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }
    var tapGesture: UITapGestureRecognizer?


    //MARK: View Load/Unload

    override func viewDidLoad() {
        super.viewDidLoad()
        Logger(subsystem: LogSubsystem, category: LogNavigation).info("\( String(describing: self) + "-" + #function)")
        guard let metalView = view as? MTKView else {
            Logger(subsystem: LogSubsystem, category: LogCategory).fault ( "PGLMetalController viewDidLoad fatalError(metal view not set up in storyboard")
            return
        }
        guard let myAppDelegate =  UIApplication.shared.delegate as? AppDelegate
            else { Logger(subsystem: LogSubsystem, category: LogCategory).fault ( "PGLMetalController viewDidLoad fatalError AppDelegate not loaded")
                return
        }
        appStack = myAppDelegate.appStack
        filterStack = { self.appStack.outputOrViewFilterStack() }

        metalRender = appStack.appRenderer
        metalRender.set(metalView: metalView)

       metalRender.mtkView(metalView, drawableSizeWillChange: metalView.drawableSize)

        metalRender.drawBasicCentered(in: metalView)
            // draw once so that the view has the current stack output image
            // then normal 60 fps drawing is controlled by the PGLNeedsRedraw

        if isFullScreen {
            // add dismiss tap recognizier
            setGestureRecogniziers()

        }

    }

    func setGestureRecogniziers() {
        if tapGesture == nil {
            tapGesture = UITapGestureRecognizer(target: self, action: #selector(PGLMetalController.userTapAction ))
            if tapGesture != nil {
                tapGesture?.numberOfTapsRequired = 2
                view.addGestureRecognizer(tapGesture!)
            }
        }
    }

    func removeGestureRecogniziers() {

//        if panner != nil {
////                NSLog("PGLImageController #removeGestureRecogniziers")
//            view.removeGestureRecognizer(panner!)
//            panner?.removeTarget(self, action: #selector(PGLImageController.panAction(_:)) )
//            panner = nil
//        }
        if tapGesture != nil {
            view.removeGestureRecognizer(tapGesture!)
            tapGesture!.removeTarget(self, action: #selector(PGLMetalController.userTapAction ))
            tapGesture = nil
        }

    }


    @objc func userTapAction(sender: UITapGestureRecognizer) {
        // two taps dismiss
        self.dismiss(animated: true)
    }

    override func viewWillAppear(_ animated: Bool) {
//        Logger(subsystem: LogSubsystem, category: LogNavigation).info("\( String(describing: self) + "-" + #function)")
        metalRender.needsRedraw.toggleViewWillAppear()
            // toggles to redraw 2 times
    }
//    override func viewDidAppear(_ animated: Bool) {
    // this code causes
    //  [CAMetalLayerDrawable texture] should not be called after already presenting this drawable. Get a nextDrawable instead.
    //Execution of the command buffer was aborted due to an error during execution. Caused GPU Timeout Error (00000002:kIOGPUCommandBufferCallbackErrorTimeout)
//        Logger(subsystem: LogSubsystem, category: LogNavigation).info("\( String(describing: self) + "-" + #function)")
//        if let myMetalView = view as? MTKView {
////            DoNotDraw = false // okay to draw now
//            metalRender.drawBasic(in: myMetalView)
//        }
//    }

//    override func viewWillDisappear(_ animated: Bool) {
//        Logger(subsystem: LogSubsystem, category: LogNavigation).info("\( String(describing: self) + "-" + #function)")
////        DoNotDraw = true
//            // don't draw while off screen
//    }

}
