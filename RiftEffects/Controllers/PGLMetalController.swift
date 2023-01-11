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
        filterStack = { self.appStack.outputFilterStack() }

//        filterStack()?.setStartupDefault()

        metalRender = appStack.appRenderer
        metalRender.set(metalView: metalView)

        metalRender.mtkView(metalView, drawableSizeWillChange: metalView.drawableSize)



    }

}
