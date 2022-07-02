//
//  PGLCoreData+Defns.swift
//  WillsFilterTool
//
//  Created by Will on 8/29/21.
//  Copyright © 2021 Will Loew-Blosser. All rights reserved.
//  based on Apple Sample app "Synchronizing a Local Store to the Cloud"


/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Extensions for Core Data classes to add convenience methods.
*/

import UIKit
import CoreData
import os

// MARK: - Creating Contexts

let appTransactionAuthorName = "PGL"
let appStackName = "RiftEffects"

enum Schema {
    enum Post: String {
        case title
    }
    
}
/**
 A convenience method for creating background contexts that specify the app as their transaction author.
 */
extension NSPersistentContainer {
    func backgroundContext() -> NSManagedObjectContext {
        let context = newBackgroundContext()
        context.transactionAuthor = appTransactionAuthorName
        return context
    }
}

// MARK: - Saving Contexts

/**
 Contextual information for handling Core Data context save errors.
 */
enum ContextSaveContextualInfo: String {
    case addPost = "adding a stack"
    case deletePost = "deleting a stack"
    case batchAddPosts = "adding a batch of stacks"
    case deduplicate = "deduplicating tags"
    case updatePost = "saving stack details"
    case addTag = "adding a version"
    case deleteTag = "deleting a version"
    case addAttachment = "adding an attachment"
    case deleteAttachment = "deleting an attachment"
    case saveFullImage = "saving a full image"
}

extension NSManagedObjectContext {

    /**
     Handles save error by presenting an alert.
     */
    private func handleSavingError(_ error: Error, contextualInfo: ContextSaveContextualInfo) {

//        Logger(subsystem: LogSubsystem, category: LogCategory).error("\(String(describing: error) )" )


        DispatchQueue.main.async {
            guard let window = UIApplication.shared.delegate?.window,
                let viewController = window?.rootViewController else { return }
            let theUserInfo = error.localizedDescription

            let message = "\(theUserInfo). Failed to save the context when \(contextualInfo.rawValue) ."

            // Append message to existing alert if present
            if let currentAlert = viewController.presentedViewController as? UIAlertController {
                currentAlert.message = (currentAlert.message ?? "") + "\n\n\(message)"
                return
            }

            // Otherwise present a new alert
            let alert = UIAlertController(title: "Core Data Saving Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            viewController.present(alert, animated: true)
        }
    }

    /**
     Save a context, or handle the save error (for example, when there data inconsistency or low memory).
     */
    func save(with contextualInfo: ContextSaveContextualInfo) {
        guard hasChanges else { return }
        do {
            try save()
        } catch {
            handleSavingError(error, contextualInfo: contextualInfo)
        }
    }
}

