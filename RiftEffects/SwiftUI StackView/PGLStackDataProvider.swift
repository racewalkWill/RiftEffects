//
//  PGLStackDataProvider.swift
//  RiftEffects
//
//  Created by Will on 6/16/23.
//  Copyright © 2023 Will Loew-Blosser. All rights reserved.
//

import Foundation
import Combine
import UIKit
import os

final class PGLStackDataUIProvider: ObservableObject {
    @Published var provider: PGLStackProvider!

    init() {
        provider = loadProvider()
    }

    func loadProvider() -> PGLStackProvider {
        guard let myAppDelegate =  UIApplication.shared.delegate as? AppDelegate
            else { Logger(subsystem: LogSubsystem, category: LogCategory).fault("PGLStackDataUIProvider loadProvider() fatalError(AppDelegate not loaded")
            fatalError("PGLSelectParmController could not access the AppDelegate")
        }
        let stackProvider =  PGLStackProvider(with: myAppDelegate.dataWrapper.persistentContainer)
        provider.setFetchControllerForStackViewContext()

// provider.fetchedResultsController.delegate = self
// "If you do not specify a delegate, the controller does not track changes to managed objects associated with its managed object context.
// see NSFetchedResultsControllerDelegate
// Rather than responding to changes individually (as illustrated in Typical Use), you could just implement controllerDidChangeContent(_:) (which is sent to the delegate when all pending changes have been processed) to reload the table view.


         return provider

    }

    func firstStack() -> CDFilterStack? {
       return provider.fetchedResultsController.fetchedObjects?.first
    }

}


