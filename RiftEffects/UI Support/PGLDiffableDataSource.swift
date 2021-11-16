//
//  PGLDiffableDataSource.swift
//  Glance
//
//  Created by Will on 3/22/20.
//  Copyright © 2020 Will Loew-Blosser. All rights reserved.
//

import Foundation
import UIKit
import Photos

class PGLDiffableDataSource: UICollectionViewDiffableDataSource<Int, PGLAsset> {
    override func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return true
    }

}
