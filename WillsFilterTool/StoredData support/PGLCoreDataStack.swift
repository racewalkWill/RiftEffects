//
//  PGLCoreDataStack.swift
//  WillsFilterTool
//
//  Created by Will on 8/29/21.
//  Copyright © 2021 Will Loew-Blosser. All rights reserved.
//  based on Apple Sample app "Synchronizing a Local Store to the Cloud"
//
/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A class to set up the Core Data stack, observe Core Data notifications, process persistent history, and deduplicate tags.
*/

import Foundation
import CoreData
import os

// MARK: - Core Data Stack

/**
 Core Data stack setup including history processing.
 */
class CoreDataStack {
    enum DataMigrationError: Error {
        case orphanFilterError
        case orphanStackError
        case orphanParmImageError
    }


    lazy var persistentContainer: NSPersistentContainer = {

        // Create a container that can load CloudKit-backed stores
        let container = NSPersistentCloudKitContainer(name: appStackName)

        // Enable history tracking and remote notifications
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("###\(#function): Failed to retrieve a persistent store description.")
        }
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        container.loadPersistentStores(completionHandler: { (_, error) in
            guard let error = error as NSError? else { return }
            fatalError("###\(#function): Failed to load persistent stores:\(error)")
//            DispatchQueue.main.async {
//                // put back on the main UI loop for the user alert
//                let alert = UIAlertController(title: "Data Store Error", message: " \(error.localizedDescription)", preferredStyle: .alert)
//
//                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
//                    Logger(subsystem: LogSubsystem, category: LogCategory).notice("The userSaveErrorAlert \(error.localizedDescription)")
//                }))
//                let myAppDelegate =  UIApplication.shared.delegate as! AppDelegate
//                myAppDelegate.displayUser(alert: alert)
//            }
        })

        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.transactionAuthor = appTransactionAuthorName
        container.viewContext.undoManager = nil // We don't need undo so set it to nil.
        container.viewContext.shouldDeleteInaccessibleFaults = true

        // Pin the viewContext to the current generation token and set it to keep itself up to date with local changes.
        container.viewContext.automaticallyMergesChangesFromParent = true
        do {
            try container.viewContext.setQueryGenerationFrom(.current)
        } catch {
            fatalError("###\(#function): Failed to pin viewContext to the current generation:\(error)")
        }

        // Observe Core Data remote change notifications.
        NotificationCenter.default.addObserver(
            self, selector: #selector(type(of: self).storeRemoteChange(_:)),
            name: .NSPersistentStoreRemoteChange, object: container)

        return container
    }()

    /**
     Track the last history token processed for a store, and write its value to file.

     The historyQueue reads the token when executing operations, and updates it after processing is complete.
     */
    private var lastHistoryToken: NSPersistentHistoryToken? = nil {
        didSet {
            guard let token = lastHistoryToken,
                let data = try? NSKeyedArchiver.archivedData( withRootObject: token, requiringSecureCoding: true) else { return }

            do {
                try data.write(to: tokenFile)
            } catch {
                print("###\(#function): Failed to write token data. Error = \(error)")
            }
        }
    }

    /**
     The file URL for persisting the persistent history token.
    */
    private lazy var tokenFile: URL = {
        let url = NSPersistentContainer.defaultDirectoryURL().appendingPathComponent(appStackName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("###\(#function): Failed to create persistent container URL. Error = \(error)")
            }
        }
        return url.appendingPathComponent("token.data", isDirectory: false)
    }()

    /**
     An operation queue for handling history processing tasks: watching changes, deduplicating tags, and triggering UI updates if needed.
     */
    private lazy var historyQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    /**
     The URL of the thumbnail folder.
     */
    static var attachmentFolder: URL = {
        var url = NSPersistentContainer.defaultDirectoryURL().appendingPathComponent(appStackName, isDirectory: true)
        url = url.appendingPathComponent("attachments", isDirectory: true)

        // Create it if it doesn’t exist.
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)

            } catch {
                print("###\(#function): Failed to create thumbnail folder URL: \(error)")
            }
        }
        return url
    }()

    init() {
        // Load the last token from the token file.
        if let tokenData = try? Data(contentsOf: tokenFile) {
            do {
                lastHistoryToken = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSPersistentHistoryToken.self, from: tokenData)
            } catch {
                print("###\(#function): Failed to unarchive NSPersistentHistoryToken. Error = \(error)")
            }
        }
    }
}
// MARK: - Notifications

extension CoreDataStack {
    /**
     Handle remote store change notifications (.NSPersistentStoreRemoteChange).
     */
    @objc
    func storeRemoteChange(_ notification: Notification) {
        print("###\(#function): Merging changes from the other persistent store coordinator.")

        // Process persistent history to merge changes from other coordinators.
        historyQueue.addOperation {
            self.processPersistentHistory()
        }
    }
}

/**
 Custom notifications in this sample.
 */
extension Notification.Name {
    static let didFindRelevantTransactions = Notification.Name("didFindRelevantTransactions")
}

// MARK: - Persistent history processing

extension CoreDataStack {

    // MARK: clean up delete
    fileprivate func deleteOrphanStacks() -> Bool {
        // all child stacks
        let backgroundContext = persistentContainer.backgroundContext()
        backgroundContext.performAndWait {
            let stackRequest: NSFetchRequest<CDFilterStack> = CDFilterStack.fetchRequest()
            stackRequest.sortDescriptors = [NSSortDescriptor(key:"title", ascending: true)]
            stackRequest.predicate = NSPredicate(format:"outputToParm != null")
            let stackController = NSFetchedResultsController(fetchRequest: stackRequest,
                                                             managedObjectContext: backgroundContext,
                                                             sectionNameKeyPath: nil, cacheName: nil)
            do {
                try stackController.performFetch()
            } catch {

                Logger(subsystem: LogSubsystem, category: LogCategory).error( "deleteOrphanStacks: Failed to performFetch")
            }

            var orphanStacks = [CDFilterStack]()
            for aChildStack in stackController.fetchedObjects! {
                if let imageParm = aChildStack.outputToParm {
                    guard let parmFilter = imageParm.filter
                    else {
                        // no filter related.. this stack is an orphan
                        orphanStacks.append(aChildStack)
                        continue  // to next childStack in the loop
                    }
                    if parmFilter.stack == nil {
                        orphanStacks.append(aChildStack)
                    }
                } else {
                    // no image parm this stack is an orphan
                    orphanStacks.append(aChildStack)
                }

            }

            let orphanStackIDs = orphanStacks.map({$0.objectID})
            NSLog("deleteOrphanStacks count = \(orphanStackIDs.count)")
            batchDelete(deleteIds: orphanStackIDs, aContext: backgroundContext)
        }
        return true  // no errors
    }

    fileprivate func deleteOrphanFilters() -> Bool {
        //  builds before build 14 did not have the delete rule to remove child stacks
        // at startup appDelegate checks db version, build
        // if they do not match. ie. not migrated migrated run this func
        // rows to delete...
        // remember that the delete cascade rule is now used for the relationships
        // it was a nullify rule in the previous db versions

        //  filters that are orphaned from a filter stack
        let backgroundContext = persistentContainer.backgroundContext()
        let filterRequest: NSFetchRequest<CDStoredFilter> = CDStoredFilter.fetchRequest()
        filterRequest.sortDescriptors = [NSSortDescriptor(key:"ciFilterName", ascending: true)]
        filterRequest.predicate = NSPredicate(format:"stack = null")

        let filterController = NSFetchedResultsController(fetchRequest: filterRequest,
                                                          managedObjectContext: backgroundContext,
                                                          sectionNameKeyPath: nil, cacheName: nil)
        let startingCount = countFilterTable()
        NSLog("starting Filter Count = \(startingCount)")

        backgroundContext.performAndWait {

            do {
                try filterController.performFetch()
            } catch {
                Logger(subsystem: LogSubsystem, category: LogCategory).error( "deleteOrphanFilters: Failed to performFetch")
            }
            // delete the orphan filters
            var filterDeleteIDs = [NSManagedObjectID]()

            for aFilterObject in filterController.fetchedObjects! {
                filterDeleteIDs.append(aFilterObject.objectID)
            }

           NSLog("deleteOrphanFilters count = \(filterDeleteIDs.count)")
            batchDelete(deleteIds: filterDeleteIDs, aContext: backgroundContext)
        }


        return true  // no errors
    }

    fileprivate func deleteOrphanParms() -> Bool {
        //  remaining ParmImages that are orphaned from a filter
        let startingParmCount = countParmsTable()
        let backgroundContext = persistentContainer.backgroundContext()
        backgroundContext.performAndWait {
            let parmRequest: NSFetchRequest<CDParmImage> = CDParmImage.fetchRequest()
            parmRequest.sortDescriptors = [NSSortDescriptor(key:"parmName", ascending: true)]
            parmRequest.predicate = NSPredicate(format:"filter = null")
            let parmController = NSFetchedResultsController(fetchRequest: parmRequest,
                                                            managedObjectContext: backgroundContext,
                                                            sectionNameKeyPath: nil, cacheName: nil)
            do {
                try parmController.performFetch()
            } catch {
                Logger(subsystem: LogSubsystem, category: LogCategory).error( "deleteOrphanParms: Failed to performFetch")
            }
            // delete the orphan filters
            if let parmDeleteIds = parmController.fetchedObjects?.map( {$0.objectID} )
            { NSLog("deleteOrphanParms count = \(parmDeleteIds.count)")
                batchDelete(deleteIds: parmDeleteIds, aContext: backgroundContext)
            }
        }
        let endingParmCount = countParmsTable()
        NSLog("startingParmCount = \(startingParmCount) ending = \(endingParmCount)")
        return true  // no errors
    }

    fileprivate func deleteOrphanImageList() -> Bool {
        //  remaining ParmImages that are orphaned from a filter
        let startingParmCount = countImageListTable()
        let backgroundContext = persistentContainer.backgroundContext()
        backgroundContext.performAndWait {
            let parmRequest: NSFetchRequest<CDImageList> = CDImageList.fetchRequest()
            parmRequest.sortDescriptors = [NSSortDescriptor(key:"attributeName", ascending: true)]
            parmRequest.predicate = NSPredicate(format:"parm = null")
            let listController = NSFetchedResultsController(fetchRequest: parmRequest,
                                                            managedObjectContext: backgroundContext,
                                                            sectionNameKeyPath: nil, cacheName: nil)
            do {
                try listController.performFetch()
            } catch {
                Logger(subsystem: LogSubsystem, category: LogCategory).error( "deleteOrphanImageList: Failed to performFetch")
            }
            // delete the orphan filters
            if let listDeleteIds = listController.fetchedObjects?.map( {$0.objectID} )
            { NSLog("deleteOrphanImageList count = \(listDeleteIds.count)")
                batchDelete(deleteIds: listDeleteIds, aContext: backgroundContext)
            }
        }
        let endingParmCount = countImageListTable()
        NSLog("startingParmCount = \(startingParmCount) ending = \(endingParmCount)")
        return true  // no errors
    }


// MARK: count table rows
    func countParmsTable() -> Int {

        let fetchRequest:NSFetchRequest<CDParmImage> = CDParmImage.fetchRequest()
        fetchRequest.predicate = NSPredicate(value: true)
        let number = try? persistentContainer.viewContext.count(for: fetchRequest)
        return number ?? 0
    }

    func countFilterTable() -> Int {

        let fetchRequest:NSFetchRequest<CDStoredFilter> = CDStoredFilter.fetchRequest()
        fetchRequest.predicate = NSPredicate(value: true)
        let number = try? persistentContainer.viewContext.count(for: fetchRequest)
        return number ?? 0
    }

    func countStackTable() -> Int {

        let fetchRequest:NSFetchRequest<CDFilterStack> = CDFilterStack.fetchRequest()
        fetchRequest.predicate = NSPredicate(value: true)
        let number = try? persistentContainer.viewContext.count(for: fetchRequest)
        return number ?? 0
    }

    func countImageListTable() -> Int {

        let fetchRequest:NSFetchRequest<CDImageList> = CDImageList.fetchRequest()
        fetchRequest.predicate = NSPredicate(value: true)
        let number = try? persistentContainer.viewContext.count(for: fetchRequest)
        return number ?? 0
    }


    func build14DeleteOrphanStacks() -> Bool {

        let stacksProcessed = true  // deleteOrphanStacks()
       let filtersProcessed =  deleteOrphanFilters()
        let parmsProcessed =  true // deleteOrphanParms()
        let imageListProcessed = true // deleteOrphanImageList()

        return ( stacksProcessed && filtersProcessed && parmsProcessed && imageListProcessed)
    }



    func batchDelete(deleteIds: [NSManagedObjectID], aContext: NSManagedObjectContext) {
        if deleteIds.isEmpty { return  }

        let batchDelete = NSBatchDeleteRequest(objectIDs: deleteIds)
        batchDelete.resultType = .resultTypeObjectIDs
        batchDelete.resultType = .resultTypeCount
        do {
            let batchDeleteResult = try aContext.execute(batchDelete) as? NSBatchDeleteResult
            print("###\(#function): Batch deleted post count: \(String(describing: batchDeleteResult?.result))")
        } catch {
            print("###\(#function): Failed to batch delete existing records: \(error)")
        }
}
    /**
     Process persistent history, posting any relevant transactions to the current view.
     */
    func processPersistentHistory() {
        let taskContext = persistentContainer.newBackgroundContext()
        taskContext.performAndWait {

            // Fetch history received from outside the app since the last token
            let historyFetchRequest = NSPersistentHistoryTransaction.fetchRequest!
            historyFetchRequest.predicate = NSPredicate(format: "author != %@", appTransactionAuthorName)
            let request = NSPersistentHistoryChangeRequest.fetchHistory(after: lastHistoryToken)
            request.fetchRequest = historyFetchRequest

            let result = (try? taskContext.execute(request)) as? NSPersistentHistoryResult
            guard let transactions = result?.result as? [NSPersistentHistoryTransaction],
                  !transactions.isEmpty
                else { return }

            // Post transactions relevant to the current view.
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .didFindRelevantTransactions, object: self, userInfo: ["transactions": transactions])
            }

            // Deduplicate the new tags.
//            var newTagObjectIDs = [NSManagedObjectID]()
//            let tagEntityName = PGLTag.entity().name

//            for transaction in transactions where transaction.changes != nil {
//                for change in transaction.changes!
//                    where change.changedObjectID.entity.name == tagEntityName && change.changeType == .insert {
//                        newTagObjectIDs.append(change.changedObjectID)
//                }
//            }
//            if !newTagObjectIDs.isEmpty {
//                deduplicateAndWait(tagObjectIDs: newTagObjectIDs)
//            }

            // Update the history token using the last transaction.
            lastHistoryToken = transactions.last!.token
        }
    }
}

// MARK: - Deduplicate tags

extension CoreDataStack {
    /**
     Deduplicate tags with the same name by processing the persistent history, one tag at a time, on the historyQueue.

     All peers should eventually reach the same result with no coordination or communication.
     */
//    private func deduplicateAndWait(tagObjectIDs: [NSManagedObjectID]) {
//        // Make any store changes on a background context
//        let taskContext = persistentContainer.backgroundContext()
//
//        // Use performAndWait because each step relies on the sequence. Since historyQueue runs in the background, waiting won’t block the main queue.
//        taskContext.performAndWait {
//            tagObjectIDs.forEach { tagObjectID in
//                self.deduplicate(tagObjectID: tagObjectID, performingContext: taskContext)
//            }
//            // Save the background context to trigger a notification and merge the result into the viewContext.
//            taskContext.save(with: .deduplicate)
//        }
//    }

    /**
     Deduplicate a single tag.
     */
//    private func deduplicate(tagObjectID: NSManagedObjectID, performingContext: NSManagedObjectContext) {
//        guard let tag = performingContext.object(with: tagObjectID) as? PGLTag,
//            let tagName = tag.name else {
//            fatalError("###\(#function): Failed to retrieve a valid tag with ID: \(tagObjectID)")
//        }
//
//        // Fetch all tags with the same name, sorted by uuid
//        let fetchRequest: NSFetchRequest<PGLTag> = PGLTag.fetchRequest()
//        fetchRequest.sortDescriptors = [NSSortDescriptor(key: Schema.PGLTag.uuid.rawValue, ascending: true)]
//        fetchRequest.predicate = NSPredicate(format: "\(Schema.PGLTag.name.rawValue) == %@", tagName)
//
//        // Return if there are no duplicates.
//        guard var duplicatedTags = try? performingContext.fetch(fetchRequest), duplicatedTags.count > 1 else {
//            return
//        }
//        print("###\(#function): Deduplicating tag with name: \(tagName), count: \(duplicatedTags.count)")
//
//        // Pick the first tag as the winner.
//        let winner = duplicatedTags.first!
//        duplicatedTags.removeFirst()
//        remove(duplicatedTags: duplicatedTags, winner: winner, performingContext: performingContext)
//    }

    /**
     Remove duplicate tags from their respective posts, replacing them with the winner.
     */
//    private func remove(duplicatedTags: [PGLTag], winner: PGLTag, performingContext: NSManagedObjectContext) {
//        duplicatedTags.forEach { tag in
//            defer { performingContext.delete(tag) }
//            guard let posts = tag.posts else { return }
//
//            for case let post as Post in posts {
//                if let mutableTags: NSMutableSet = post.tags?.mutableCopy() as? NSMutableSet {
//                    if mutableTags.contains(tag) {
//                        mutableTags.remove(tag)
//                        mutableTags.add(winner)
//                    }
//                }
//            }
//        }
//    }
}

