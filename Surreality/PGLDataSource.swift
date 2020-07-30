//
//  PGLDataSource.swift
//  Glance
//
//  Created by Will on 4/28/20.
//  Copyright © 2020 Will. All rights reserved.
//

import UIKit
import Photos


class PGLDataSource: UITableViewDiffableDataSource<Int, PGLUUIDAssetCollection> {
    //UITableViewDiffableDataSource<SectionType, ItemType>


    // MARK: header/footer titles support

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionKind = Section(rawValue: section)
        return sectionKind?.description() // and secondaryDescription?
    }

    // MARK: reordering support

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        guard let sourceIdentifier = itemIdentifier(for: sourceIndexPath) else { return }
        guard sourceIndexPath != destinationIndexPath else { return }
        let destinationIdentifier = itemIdentifier(for: destinationIndexPath)

        var snapshot = self.snapshot()

        if let destinationIdentifier = destinationIdentifier {
            if let sourceIndex = snapshot.indexOfItem(sourceIdentifier),
               let destinationIndex = snapshot.indexOfItem(destinationIdentifier) {
                let isAfter = destinationIndex > sourceIndex &&
                    snapshot.sectionIdentifier(containingItem: sourceIdentifier) ==
                    snapshot.sectionIdentifier(containingItem: destinationIdentifier)
                snapshot.deleteItems([sourceIdentifier])
                if isAfter {
                    snapshot.insertItems([sourceIdentifier], afterItem: destinationIdentifier)
                } else {
                    snapshot.insertItems([sourceIdentifier], beforeItem: destinationIdentifier)
                }
            }
        } else {
            let destinationSectionIdentifier = snapshot.sectionIdentifiers[destinationIndexPath.section]
            snapshot.deleteItems([sourceIdentifier])
            snapshot.appendItems([sourceIdentifier], toSection: destinationSectionIdentifier)
        }
        apply(snapshot, animatingDifferences: false)
    }

    // MARK: editing support

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if let identifierToDelete = itemIdentifier(for: indexPath) {
                var snapshot = self.snapshot()
                snapshot.deleteItems([identifierToDelete])
                apply(snapshot)
            }
        }
    }
}
