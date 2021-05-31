//
//  PGLMetalController.swift
//  Glance
//
//  Created by Will on 1/20/19.
//  Copyright © 2019 Will Loew-Blosser. All rights reserved.
//

import Foundation
import MetalKit
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

        metalRender = Renderer(metalView: metalView)



    }

    func reloadMetalView() {
        // reloadMetalView is attempt to make the saved coredata  record images show in the full size.
        // did not work.  2020-02-17
        // still showing quarter view
        guard let metalView = view as? MTKView else {
            Logger(subsystem: LogSubsystem, category: LogCategory).fault ( "PGLMetalController reloadMetalView fatalError(metal view not set up in storyboard")
            return
              }
        metalRender = Renderer(metalView: metalView)
    }

    func metalLayer() -> CAMetalLayer? {
        if let metalView = view as? MTKView {
            return metalView.currentDrawable?.layer
        } else {
            return nil
        }
    }







}
