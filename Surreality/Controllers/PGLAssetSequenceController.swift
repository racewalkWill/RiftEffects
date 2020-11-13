//
//  PGLAssetSequenceController.swift
//  Glance
//
//  Created by Will on 3/3/20.
//  Copyright © 2020 Will. All rights reserved.
//

import UIKit
import Photos
import PhotosUI

private let reuseIdentifier = "Cell"
let PGLSequenceSelectUpdate = NSNotification.Name(rawValue: "PGLSequenceSelectUpdate")

// PGLAssetSequenceController responds to PGLImageSelectUpdate and generates PGLSequenceSelectUpdate

class PGLAssetSequenceController: UIViewController,  UIGestureRecognizerDelegate {
    // displays selected assets from the album grid (PGLAssetSequenceController)
    // in the order they will be used.
    // drag to change the order
    // some image assets may be from another album that is not currently displayed
    // on the grid..
     static let badgeElementKind = "badge-element-kind"
    static let sectionHeaderElementKind = "section-header-element-kind"

    var dataSource: PGLDiffableDataSource! = nil
    var userAssetSelection: PGLUserAssetSelection!
    var collectionView: UICollectionView! = nil

    var targetSize: CGSize {
          let scale = UIScreen.main.scale
          return CGSize(width: collectionView!.bounds.width * scale,
                        height: collectionView!.bounds.height * scale)
      }
    var availableWidth: CGFloat = 0

    fileprivate let imageManager = PHCachingImageManager()
    fileprivate var thumbnailSize: CGSize!
    fileprivate var previousPreheatRect = CGRect.zero

    var tapper: UITapGestureRecognizer!

    var longPressGesture: UILongPressGestureRecognizer!
    var longPressStart: IndexPath?
    var lastSelectedCell: UICollectionViewCell?
    let cellSizeConstant: CGFloat = 80 // was 80

    var hasCellDoubleTap = false
    var notifications = [Any]() // an opaque type is returned from addObservor

     // MARK: UIViewController / Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
//        collectionView.allowsSelection = true
//        collectionView.allowsMultipleSelection = true

//        installsStandardGestureForInteractiveMovement = true
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false


        configureHierarchy()
        configureDataSource()
        
        // Do any additional setup after loading the view.

    }

    override func viewWillDisappear(_ animated: Bool) {
//         removeGestureRecogniziers(targetView: view)
          super.viewWillDisappear(animated)
              for anObserver in  notifications {
                  NotificationCenter.default.removeObserver(anObserver)
              }
              notifications = [Any]() // reset

       }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
             setLongPressGesture()

        let myCenter =  NotificationCenter.default
         let queue = OperationQueue.main
        let aNotification = myCenter.addObserver(forName: PGLImageSelectUpdate , object: nil , queue: queue) { [weak self]
                myUpdate in
            guard let self = self else { return } // a released object sometimes receives the notification
                          // the guard is based upon the apple sample app 'Conference-Diffable'
            NSLog("PGLAssetSequenceController notification receieved PGLImageSelectUpdate ")
            self.applyDataSource()
        }
        notifications.append(aNotification)
            NSLog("PGLAssetSequenceController  viewWillAppear observer for PGLImageSelectUpdate")
         postSelectionChange()

    }



    // MARK: UINavigationControllerDelegate

    func postSelectionChange(){

        applyDataSource()
        NSLog("PGLAssetSequenceController posts notification #PGLSequenceAssetChanged start")
        let notification = Notification(name:PGLSequenceAssetChanged)
        NotificationCenter.default.post(notification)
    }

     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

            let segueId = segue.identifier
            switch segueId {


            case "showSequenceDetail" :

                guard let destination = segue.destination  as? PGLAssetController
                    else { fatalError("unexpected view controller for segue")  }

                    destination.userAssetSelection = self.userAssetSelection
                    destination.selectedAlbumId = nil
                        // nil value to show the selectedAssets from the sequence
               

            default: fatalError("unexpected view controller for segue")
            }

        
    }


    //MARK: Drag GestureRecognizer
     func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
//         NSLog("PGLAssetSequenceController canMoveItemAt answers true")
        // the dataSource needs to answer true..
        return true
    }

     func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {

//        NSLog("PGLAssetSequenceController moveItemAt \(sourceIndexPath) to \(destinationIndexPath)")
        userAssetSelection.moveItemAt(sourceIndexPath.row, toIndex: destinationIndexPath.row)

    }



        func setLongPressGesture() {

            longPressGesture = UILongPressGestureRecognizer(target: self , action: #selector(PGLAssetSequenceController.longPressAction(_:)))
              if longPressGesture != nil {

//                 " defaults to 0.5 sec 1 finger 10 points allowed movement"
                  collectionView.addGestureRecognizer(longPressGesture!)
                  longPressGesture!.isEnabled = true
                NSLog("PGLAssetSequenceController setLongPressGesture \(String(describing: longPressGesture))")
              }
          }

         func removeGestureRecogniziers(targetView: UIView) {
            // not called in viewWillDissappear..
            // recognizier does not seem to get restored if removed...
             if longPressGesture != nil {
                 collectionView.removeGestureRecognizer(longPressGesture!)
                 longPressGesture!.removeTarget(self, action: #selector(PGLAssetSequenceController.longPressAction(_:)))
                 longPressGesture = nil
                NSLog("PGLAssetSequenceController removeGestureRecogniziers ")
            }
            if tapper != nil {
               targetView.removeGestureRecognizer(tapper!)
               tapper!.removeTarget(self, action: #selector(PGLAssetSequenceController.openSingleAssetView(_:)))
               tapper = nil
            }
         }

    @objc func longPressAction(_ sender: UILongPressGestureRecognizer) {
        
        let point = sender.location(in: collectionView)
        switch sender.state {
        case .began:
            NSLog("PGLAssetSequenceController longPressAction begin")
            guard let longPressIndexPath = collectionView.indexPathForItem(at: point) else {
                longPressStart = nil // assign to var
                return
            }
            longPressStart = longPressIndexPath // assign to var
           let isS = collectionView.beginInteractiveMovementForItem(at: longPressIndexPath)
            NSLog("PGLAssetSequenceController #longPressAction begins \(isS) path \(String(describing: longPressStart))")

        case .changed:
            collectionView.updateInteractiveMovementTargetPosition(point)
//            NSLog("PGLAssetSequenceController longPressAction change to \(point)")
        case .ended:
            collectionView.endInteractiveMovement()
             NSLog("PGLAssetSequenceController longPressAction ended")

            guard let endIndex = collectionView.indexPathForItem(at: point) else { return  }
            userAssetSelection.moveItemAt(longPressStart!.row, toIndex: endIndex.row)
            NSLog("PGLAssetSequenceController longPress ended move from \(longPressStart!.row) to \(endIndex)")
//            dataSource.collectionView(collectionView, moveItemAt: longPressStart!, to: endIndex)

            applyDataSource()
            NSLog("PGLAssetSequenceController longPressAction move from \(String(describing: longPressStart)) to \(endIndex)")
        default:
            collectionView.cancelInteractiveMovement()
             NSLog("PGLAssetSequenceController longPressAction cancelled")
        }
    }

           //MARK: Swipe GestureRecognizer

        @objc func openSingleAssetView(_ sender: UITapGestureRecognizer){

            hasCellDoubleTap = true
            NSLog("PGLAssetGridController hasHeaderCellTap = \(hasCellDoubleTap) ")
            if let headerTitleView = sender.view as? TitleSupplementaryView {
                     performSegue(withIdentifier: "showSequenceDetail", sender: headerTitleView )
            }

        }


       func setOpenZoomGesture(headerCell: TitleSupplementaryView) {

                     tapper = UITapGestureRecognizer(target: self , action: #selector(PGLAssetSequenceController.openSingleAssetView(_:)))
                     if tapper != nil {
                            tapper?.numberOfTapsRequired = 1
                            headerCell.addGestureRecognizer(tapper!)
                            tapper!.isEnabled = true
                     }
         }



    //MARK: UICollectionViewDelegate

    // Uncomment this method to specify if the specified item should be highlighted during tracking
     func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
         NSLog("PGLAssetSequenceController shouldHighLightItemAt \(indexPath)")
        return true
    }



    // Uncomment this method to specify if the specified item should be selected
     func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        NSLog("PGLAssetSequenceController shouldSelectItemAt \(indexPath)")
        return true
    }

    func collectionView(_ collectionView: UICollectionView, shouldSpringLoadItemAt indexPath: IndexPath, with context: UISpringLoadedInteractionContext) -> Bool {
         NSLog("PGLAssetSequenceController shouldSpringLoadItemAt \(indexPath)")
        return true
    }
}


// MARK: CompositionLayout
extension PGLAssetSequenceController: UICollectionViewDelegate {

    func applyDataSource() {

        var snapshot = NSDiffableDataSourceSnapshot<Int, PGLAsset>()
        snapshot.appendSections([0]) // only one section
            let sectionItems = userAssetSelection.selectedAssets
            snapshot.appendItems(sectionItems)
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout {
                   (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in

            let badgeAnchor = NSCollectionLayoutAnchor(edges: [.top, .trailing], fractionalOffset: CGPoint(x: 0.3, y: -0.3))
            let badgeSize = NSCollectionLayoutSize(widthDimension: .absolute(20),
                                                  heightDimension: .absolute(20))
            let badge = NSCollectionLayoutSupplementaryItem(
                layoutSize: badgeSize,
                elementKind: PGLAssetSequenceController.badgeElementKind,
                containerAnchor: badgeAnchor)

            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.2),
                                                 heightDimension: .fractionalHeight(1.0))
//          let item = NSCollectionLayoutItem(layoutSize: itemSize)
           let item = NSCollectionLayoutItem(layoutSize: itemSize, supplementaryItems: [badge])
           item.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2 )
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                   heightDimension: .fractionalHeight(1.0))

            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

//            let spacing = CGFloat(2)
//          group.interItemSpacing = .fixed(spacing)
//            group.interItemSpacing = .flexible(spacing)

            let section = NSCollectionLayoutSection(group: group)
//            section.interGroupSpacing = spacing
            section.orthogonalScrollingBehavior = .continuous

            let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                        layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                          heightDimension: .estimated(44)),
                        elementKind: PGLAssetGridController.sectionHeaderElementKind,
                        alignment: .top)

                    sectionHeader.pinToVisibleBounds = true
            //        sectionHeader.zIndex = 2  // what does this do?
                        // defn -   default is 0; all other section items will be automatically be promoted to zIndex=1

            section.boundarySupplementaryItems = [sectionHeader ]
            return section
        }
        return layout
    }


    func configureHierarchy() {
           collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
           collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
           collectionView.backgroundColor = .systemBackground
           collectionView.register(ListCell.self, forCellWithReuseIdentifier: ListCell.reuseIdentifier)
            collectionView.register(BadgeSupplementaryView.self,
                            forSupplementaryViewOfKind: PGLAssetSequenceController.badgeElementKind,
                            withReuseIdentifier: BadgeSupplementaryView.reuseIdentifier)
            collectionView.register(TitleSupplementaryView.self,
                                forSupplementaryViewOfKind: PGLAssetSequenceController.sectionHeaderElementKind,
                                withReuseIdentifier: TitleSupplementaryView.reuseIdentifier)

           view.addSubview(collectionView)
           collectionView.delegate = self
       }

     func configureDataSource() {
        dataSource = PGLDiffableDataSource(collectionView: collectionView) { [weak self]
                (collectionView: UICollectionView, indexPath: IndexPath, identifier: PGLAsset) -> UICollectionViewCell? in
                guard let self = self
                    else { return  nil}
//                NSLog("PGLAssetSequenceController #configureDataSource start indexPath = \(indexPath)")
//                NSLog("PGLAssetSequenceController #configureDataSource start identifier = \(identifier)")
                // Get a cell of the desired kind.
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: ListCell.reuseIdentifier,
                    for: indexPath) as? ListCell else { fatalError("Cannot create new cell") }

                // Populate the cell with our item description.
    
                let asset = identifier
                cell.representedAssetIdentifier = asset.localIdentifier

                let thumbnailSize = CGSize(width: 100.0, height: 100.0)

            self.imageManager.requestImage(for: asset.asset, targetSize: thumbnailSize, contentMode: .aspectFill, options: nil, resultHandler: { image, _ in
                    // The cell may have been recycled by the time this handler gets called;
                    // set the cell's thumbnail image only if it's still showing the same asset.
                    // resetAfterReuse should take care of this??

                    if cell.representedAssetIdentifier == asset.localIdentifier {
                        if let storedThumbNail  = image {
                            cell.assetImageView.image = storedThumbNail
                            if ((self.userAssetSelection.selectedAssets.count ) > (indexPath.row + 1))
                            {    //count is 1 more than zero based row
                                cell.addChevron() }
                            // else  don't put chevron on last asset
                        }
                    }
//                    else  the callback is late and the cell is reused
//                    {
//                        NSLog("PGLAssetSequenceController.configureDataSource() identifier mismatch path \(indexPath)")
//                    }
                })
            
                // Return the cell.
                return cell
            }

        self.dataSource.supplementaryViewProvider = { [weak self]
                (collectionView: UICollectionView, kind: String, indexPath: IndexPath) -> UICollectionReusableView? in
                    guard let self = self
                        else { return  nil}
                // Get a supplementary view of the desired kind.
                // Header label

                switch kind {
                    case PGLAssetSequenceController.sectionHeaderElementKind :
                    guard let header = collectionView.dequeueReusableSupplementaryView(
                            ofKind: kind,
                            withReuseIdentifier: TitleSupplementaryView.reuseIdentifier,
                            for: indexPath) as? TitleSupplementaryView else { fatalError("Cannot create new header") }

                        // Populate the view with our section's description.
                    
                    header.label.text =  self.userAssetSelection.parmInputName() + " >"  //+ "images"
                        header.backgroundColor = .systemBlue// this the selected color badge.. make header the same
                        header.layer.borderColor = UIColor.black.cgColor
                        header.layer.borderWidth = 1.0
                        self.setOpenZoomGesture(headerCell: header)
                        // set text size and bold face here

                        return header
                    case PGLAssetSequenceController.badgeElementKind :
                        guard let badgeView = collectionView.dequeueReusableSupplementaryView(
                        ofKind: kind,
                        withReuseIdentifier: BadgeSupplementaryView.reuseIdentifier,
                        for: indexPath) as? BadgeSupplementaryView  else { fatalError("Cannot create new badgeView") }

                        // sequence area only action is to remove
                        badgeView.label.text = "-"
                        badgeView.label.textColor = .systemTeal
                        badgeView.backgroundColor = .systemBlue
                    
                        return badgeView

                    default: return nil
                }
            }

    }




    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // remove from the sequence

         NSLog("PGLAssetSequenceController didSelectItem at indexPath = \(indexPath)  ")

       let theItem = userAssetSelection.selectedAssets[indexPath.item]
            // only selectedAssets are in the collectionView
            // toggle to deselect state
                userAssetSelection.remove(theItem)
                // notify the lower grid that the badge changes

                postSelectionChange()  // post calls applyDataSource()


     }
}


