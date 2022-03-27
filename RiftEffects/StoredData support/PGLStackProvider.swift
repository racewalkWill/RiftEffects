//
//  PGLStackProvider.swift
//  WillsFilterTool
//
//  Created by Will on 9/1/21.
//  Copyright © 2021 Will Loew-Blosser. All rights reserved.
//

import Foundation
import CoreData

class PGLStackProvider {
    private(set) var persistentContainer: NSPersistentContainer


    init(with persistentContainer: NSPersistentContainer) {
        self.persistentContainer = persistentContainer
    }

    lazy var fetchedResultsController: NSFetchedResultsController<CDFilterStack> = {
        let fetchRequest: NSFetchRequest<CDFilterStack> = CDFilterStack.fetchRequest()
//        fetchRequest.predicate = NSPredicate(format: "outputToParm = null")  // only parent stacks
        fetchRequest.predicate = NSPredicate(value: true) // return all stacks
        fetchRequest.fetchBatchSize = 15  // usually 12 rows visible -
            // breaks up the full object fetch into view sized chunks

            // only CDFilterStacks with outputToParm = null.. ie it is not a child stack)
        var sortArray = [NSSortDescriptor]()
        sortArray.append(NSSortDescriptor(key: "type", ascending: true))
        sortArray.append(NSSortDescriptor(key: "created", ascending: false))


        fetchRequest.sortDescriptors = sortArray

        let controller = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                    managedObjectContext: persistentContainer.viewContext,
                                                    sectionNameKeyPath: "type" , cacheName: "StackType")
//        controller.delegate = fetchedResultsControllerDelegate
            // Full persistent tracking: the delegate and the file cache name are non-nil. The controller monitors objects in its result set
            // and updates section and ordering information in response
            // to relevant changes. The controller maintains a persistent cache of the results of its computation.

        do {
            try controller.performFetch()
        } catch {
            fatalError("###\(#function): Failed to performFetch: \(error)")
        }

        return controller
    }()

    lazy var fetchedStacks = fetchedResultsController.fetchedObjects?.map({ ($0 ) })

    func delete(stack: CDFilterStack, shouldSave: Bool = true, completionHandler: (() -> Void)? = nil) {
        guard let context = stack.managedObjectContext else {
            fatalError("###\(#function): Failed to retrieve the context from: \(stack)")
        }
        context.perform {
            context.delete(stack)

            if shouldSave {
                context.save(with: .deletePost)
            }
            completionHandler?()
        }
    }

    func batchDelete(deleteIds: [NSManagedObjectID]) {
        let taskContext = persistentContainer.viewContext
        let batchDelete = NSBatchDeleteRequest(objectIDs: deleteIds)
        batchDelete.resultType = .resultTypeObjectIDs
        batchDelete.resultType = .resultTypeCount
        do {
            let batchDeleteResult = try taskContext.execute(batchDelete) as? NSBatchDeleteResult
            print("###\(#function): Batch deleted post count: \(String(describing: batchDeleteResult?.result))")
        } catch {
            print("###\(#function): Failed to batch delete existing records: \(error)")
        }
    }

    func saveStack(aStack: CDFilterStack, in context: NSManagedObjectContext, shouldSave: Bool = true) {
        context.perform {

            if shouldSave {
                context.save(with: .addPost)
            }

        }
    }

    func filterStackCount() -> Int {
        // number of rows in the CDFilterStack table
        var rowCount = 0

        let fetchCountRequest: NSFetchRequest<CDFilterStack> = CDFilterStack.fetchRequest()
        fetchCountRequest.predicate = NSPredicate(value: true)
            // all rows returned

        rowCount = try! persistentContainer.viewContext.count(for: fetchCountRequest)

        return rowCount
    }

}
