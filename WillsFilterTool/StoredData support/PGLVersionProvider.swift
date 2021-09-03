//
//  PGLVersionProvider.swift
//  WillsFilterTool
//
//  Created by Will on 9/2/21.
//  Copyright © 2021 Will Loew-Blosser. All rights reserved.
//


/*
See LICENSE folder for info on the Apple Sample app CoreDataCloudKitDemo
 Synchronizing a Local Store to the Cloud

Abstract:
A class to wrap everything related to fetching, creating, and deleting PGLVersion.
*/

import UIKit
import CoreData

class PGLVersionProvider {
    private(set) var persistentContainer: NSPersistentContainer
//    private weak var fetchedResultsControllerDelegate: NSFetchedResultsControllerDelegate?

    init(with persistentContainer: NSPersistentContainer ) {
        self.persistentContainer = persistentContainer
//        self.fetchedResultsControllerDelegate = fetchedResultsControllerDelegate
    }

    /**
     A fetched results controller for the Tag entity, sorted by name.
     */
    lazy var fetchedResultsController: NSFetchedResultsController<PGLVersion> = {
        let fetchRequest: NSFetchRequest<PGLVersion> = PGLVersion.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "buildLabel", ascending: false)]

        let controller = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                    managedObjectContext: persistentContainer.backgroundContext(),
                                                    sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try controller.performFetch()
        } catch {
            let nserror = error as NSError
            fatalError("###\(#function): Failed to performFetch: \(nserror), \(nserror.userInfo)")
        }

        return controller
    }()

    /**
     The number of tags. Used for tag name input validation.
     */
    func versionDataRows() -> [PGLVersion] {
        let result =  fetchedResultsController.fetchedObjects ?? [PGLVersion]()
        if result.isEmpty {
           addVersion(version: "0", build: "0", context: persistentContainer.backgroundContext())
           return [PGLVersion]()
        } else {
            return result
        }
    }

    /**
     Add a version
     */
    func addVersion(version: String, build: String, context: NSManagedObjectContext, shouldSave: Bool = true)   {
        var thisVersion: PGLVersion!
        context.performAndWait {
            thisVersion = PGLVersion(context: context)
            thisVersion.appVersion = version
            thisVersion.buildLabel = build
            thisVersion.isMigrated = false
            if shouldSave {
                context.save(with: .addTag)
            }
        }

    }

    func deleteVersion(at indexPath: IndexPath, shouldSave: Bool = true) {
        let context = fetchedResultsController.managedObjectContext
        context.performAndWait {
            context.delete(fetchedResultsController.object(at: indexPath))
            if shouldSave {
                context.save(with: .deleteTag)
            }
        }
    }
}

