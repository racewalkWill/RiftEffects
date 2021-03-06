//
//  AppDelegate.swift
//  Glance
//
//  Created by Will on 10/11/17.
//  Copyright © 2017 Will Loew-Blosser. All rights reserved.
//

import UIKit
import CoreData
import Photos
import os

let iCloudDataContainerName = "iCloud.L-BSoftwareArtist.WillsFilterTool"
let LogSubsystem = "L-BSoftwareArtist.WillsFilterTool"
var LogCategory = "PGL"
var LogMigration = "PGL_Migration"
// change in areas as needed.
// caution on changes it is a GLOBAL

var mainViewImageResize = true
// or false to not perform ciOutputImage.cropped(to: currentStack.cropRect) in Render #drawIn
// should be a user setting
// 2/12/2020 leave as false - makes the cropped produce an empty image if in single filter edit mode.

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {



    var window: UIWindow?
    var appStack: PGLAppStack!
    lazy var dataWrapper: CoreDataWrapper = { return CoreDataWrapper() }()


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        //******* ONLY One time to push schema to cloudKit
        // get the store description
//        guard let description = PersistentContainer.persistentStoreDescriptions.first else {
//            fatalError("Could not retrieve a persistent store description.")
//        }
        // initialize the CloudKit schema


//        do {
//            try
//            PersistentContainer.initializeCloudKitSchema(options: NSPersistentCloudKitContainerSchemaInitializationOptions.printSchema)
//        }
//            catch {
//                NSLog("initializeCloudKitSchema \(error.localizedDescription)" )  }



//       PGLFaceCIFilter.register()
//        PGLFilterCategory.allFilterCategories()
        Logger(subsystem: LogSubsystem, category: LogCategory).notice( "start didFinishLaunchingWithOptions")
        PGLFilterCIAbstract.register()
        WarpItMetalFilter.register()

        CompositeTextPositionFilter.register()
        PGLSaliencyBlurFilter.register()
        PGLImageCIFilter.register()
        PGLRandomFilterAction.register()
       appStack = PGLAppStack()
        Logger(subsystem: LogSubsystem, category: LogCategory).notice( " didFinishLaunchingWithOptions appStack created")
        checkVersion()
       return true
        }

    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
//        NSLog("AppDelegate applicationDidReceiveMemoryWarning")
        Logger(subsystem: LogSubsystem, category: LogCategory).notice("AppDelegate applicationDidReceiveMemoryWarning")
        // run a memory graph.. who and how many objects have the memory?
        // see the Swift Programming Lang  book on strong referencs and reference cycles
        // chap "Automatic Reference Counting"
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.

    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
//        NSLog("AppDelegate #applicationWillTerminate saveContext")
//        self.saveContext()
    }



    //Mark: Error Alert



    func displayUser(alert: UIAlertController) {
        // presents an alert on top of the open viewController
        // informs user to try again with 'Save As'


        guard let lastWindow = UIApplication.shared.windows.last(where: {!$0.isKeyWindow })
            // don't use the keywindow - they have error with the alert of
            //  "Keyboard cannot present view controllers (attempted to present <UIAlertController: 0x131893600>)"
        else { return
            // need a window to present an alert.. give up
        }

        var parentController = lastWindow.rootViewController
        // drill down until front viewController is reached
        while (parentController?.presentedViewController != nil &&
                parentController != parentController!.presentedViewController) {
                    parentController = parentController!.presentedViewController
                    }
        parentController?.present(alert, animated: true )


    }

    // MARK: Migration

    func checkVersion() {
//        self.dataWrapper.build14DeleteOrphanStacks()
        Logger(subsystem: LogSubsystem, category: LogCategory).notice( "completed checkVersion")
    }


}



