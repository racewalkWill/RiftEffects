/*
	Copyright (C) 2017 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Manages the second-level collection view, a grid of photos in a collection (or all photos).

    Modified from Apple code -  changes Copyright (C) Will Loew-Blosser 2018
 */


import UIKit
import Photos
import PhotosUI


let PGLImageSelectUpdate = NSNotification.Name(rawValue: "PGLImageSelectUpdate")
let PGLSequenceAssetChanged = NSNotification.Name(rawValue: "PGLSequenceAssetChanged")
let PGLImageAlbumAdded = NSNotification.Name(rawValue: "PGLImageAlbumAdded")
let PGLImageAlbumSelectionRemoved = NSNotification.Name(rawValue: "PGLImageAlbumSelectionRemoved")


// PGLAssetGridController responds to PGLSequenceSelectUpdate  and generates PGLImageSelectUpdate

class PGLAssetGridController: UIViewController,  UIGestureRecognizerDelegate {
    // shows images of the selected collection/album in a grid
       // tap selects images
       // double tap opens single image to full view

    static let sectionHeaderElementKind = "section-header-element-kind"
    static let badgeElementKind = "badge-element-kind"

    var dataSource: UICollectionViewDiffableDataSource<PGLAlbumSource, PGLAsset>! = nil
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
    var hasCellDoubleTap = false

    let cellSizeConstant: CGFloat = 80 // was 80

     var notifications = [Any]() // an opaque type is returned from addObservor

    // MARK: UIViewController / Lifecycle

   required init?(coder: NSCoder) {
        super.init(coder: coder)
        NSLog("PGLAssetGridController init = \(self)")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureHierarchy()
        configureDataSource()

        applyDataSource()

        NSLog("PGLAssetGridController #viewDidLoad FINISH")
        NSLog("PGLAssetGridController #viewDidLoad controller = \(self)")


    }


        override func viewWillDisappear(_ animated: Bool) {

            // confirm if the user is accepting or cancelling the assetGrid selection
            super.viewWillDisappear(animated)
            for anObserver in  notifications {
                NotificationCenter.default.removeObserver(anObserver)
            }
            notifications = [Any]() // reset



        }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

    }

    override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)


        let myCenter =  NotificationCenter.default
        let queue = OperationQueue.main


        var aNotification = myCenter.addObserver(forName: PGLSequenceSelectUpdate , object: nil , queue: queue) {[weak self]
                  myUpdate in
                      // now make the sequence show this too
                    NSLog("PGLAssetGridController notification PGLSequenceSelectUpdate")
                    guard let self = self else { return } // a released object sometimes receives the notification
                                  // the guard is based upon the apple sample app 'Conference-Diffable'
                    self.applyDataSource()
                      self.postSelectionChange() // tells sequence to update next
                     }
        notifications.append(aNotification)

        aNotification =  myCenter.addObserver(forName: PGLSequenceAssetChanged , object: nil , queue: queue) {[weak self]
                         myUpdate in
                             // now make the sequence show this too
                           guard let self = self else { return } // a released object sometimes receives the notification
                                         // the guard is based upon the apple sample app 'Conference-Diffable'
                            self.applyDataSource() // new state of the userAssetSelection will be loade
                            }
        notifications.append(aNotification)

          aNotification =  myCenter.addObserver(forName: PGLImageAlbumAdded , object: nil , queue: queue) { [weak self]
                    myUpdate in
                    guard let self = self else { return } // a released object sometimes receives the notification
                                  // the guard is based upon the apple sample app 'Conference-Diffable'
                    if let newAlbumSource = ( myUpdate.userInfo?["newSource"]) as?  PGLAlbumSource {
                        NSLog("PGLAssetGridController = \(self) notification PGLImageAlbumAdded for newAlbumSourse = \(newAlbumSource)")
                        self.applyDataSource()
        //                self?.appendDataSource(albumId: newAlbumSource.identifier, aSourceFetch: newAlbumSource)
                    }
            }
            notifications.append(aNotification)

           aNotification = myCenter.addObserver(forName: PGLImageAlbumSelectionRemoved , object: nil , queue: queue) {[weak self]
                     myUpdate in
                         // now make the sequence show this too
                       guard let self = self else { return }
                        // a released object sometimes receives the notification
                        // the guard is based upon the apple sample app 'Conference-Diffable'
                    if let albumId = ( myUpdate.userInfo?["albumId"]) as?  String{

                        self.removeAlbum(albumId: albumId)
                    }
                }
            notifications.append(aNotification)

    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        updateCachedAssets()


        let openNotification = Notification(name:PGLImageCollectionOpen)
         NotificationCenter.default.post(openNotification)
        NSLog("PGLAssetGridController viewDidAppear completed self = \(self)")
    }

       //MARK: GestureRecognizer

    @objc func openSingleAssetView(_ sender: UITapGestureRecognizer){

        hasCellDoubleTap = true
        NSLog("PGLAssetGridController hasCellDoubleTap = \(hasCellDoubleTap) ")
        if let headerTitleView = sender.view as? TitleSupplementaryView {
                 performSegue(withIdentifier: "showImageDetail", sender: headerTitleView )
        }

    }


   func setOpenZoomGesture(headerCell: TitleSupplementaryView) {

                 tapper = UITapGestureRecognizer(target: self , action: #selector(PGLAssetGridController.openSingleAssetView(_:)))
                 if tapper != nil {
                     tapper?.numberOfTapsRequired = 1
//                    tapper?.cancelsTouchesInView = true // pass touchs to the view
                     headerCell.addGestureRecognizer(tapper!)
                     tapper!.isEnabled = true
                 }
     }

    func removeGestureRecogniziers(targetView: UIView) {
        // not called in viewWillDissappear..
        // recognizier does not seem to get restored if removed...
        if tapper != nil {
            targetView.removeGestureRecognizer(tapper!)
            tapper!.removeTarget(self, action: #selector(PGLAssetGridController.openSingleAssetView(_:)))
            tapper = nil
               }
    }



// MARK: actions
    @IBAction func backBtnAction(_ sender: UIBarButtonItem) {
        // DELETE?
//        NSLog("backBtnAction... but where to?")
    }

    @IBAction func goToAssetGridView(segue: UIStoryboardSegue) {
        // DELETE?
        NSLog("PGLParmsFilterTabsController goToAssetGridView segue")

    }






    func applyDataSource() {
        // 4/6/20 - there is an issue with two instances of the AssetGridController receviing
        // the Notifications and both running with two instances of the dataSource.
        // just call applyDataSource instead of appendDataSource. Apply updates everything at once without a fatal error
        // watch for two calls to applyDataSource which indicates the issue, but does not crash..
        // 5/20/20 the two instances issue is fixed.
        
        var snapshot = NSDiffableDataSourceSnapshot<PGLAlbumSource, PGLAsset>()

        NSLog("PGLAssetGridController #applyDataSource controller = \(self)")

        for ( albumId, albumSource) in userAssetSelection.sections
        {
            NSLog("PGLAssetGridController #applyDataSource albumId = \(albumId)")



            guard let albumAssets = albumSource.assets()
                else { continue }
           
            snapshot.appendSections([albumSource])
            snapshot.appendItems(albumAssets, toSection: albumSource)

        }
        if snapshot.numberOfSections != snapshot.sectionIdentifiers.count {
            fatalError("snapshot.numberOfSections != snapshot.sectionIdentifiers.count")
        }
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    func removeAlbum(albumId: String){
        // album must not be included in the userSelection..
        // if any image assets are selected then do not remove

        if userAssetSelection.removeAlbum(albumId: albumId) != nil {
            applyDataSource()
        }
    }

    // MARK: UINavigationControllerDelegate

    func postSelectionChange(){
           NSLog("PGLAssetGridController #postSelectionChange start")
           // the badge is changed for the grid by the changedItems in selectedCell
            NSLog("PGLAssetGridController #postSelectionChange sends notification PGLImageSelectUpdate")
           let notification = Notification(name:PGLImageSelectUpdate)
           NotificationCenter.default.post(notification)
       }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        let segueId = segue.identifier
        switch segueId {


        case "showImageDetail" :

            guard let destination = segue.destination  as? PGLAssetController
                else { fatalError("unexpected view controller for segue")  }
            if let theHeaderCell = sender as? TitleSupplementaryView {
                destination.userAssetSelection = self.userAssetSelection
                destination.selectedAlbumId = theHeaderCell.headerAlbumId
            }

        default: fatalError("unexpected view controller for segue")
        }

    }
}



// MARK: CompositionLayout
extension PGLAssetGridController {
    func createLayout() -> UICollectionViewLayout {
            let columnCount = 5
            let groupSizeHeight: CGFloat = 1.0/CGFloat(columnCount)

            let badgeAnchor = NSCollectionLayoutAnchor(edges: [.top, .trailing], fractionalOffset: CGPoint(x: 0.3, y: -0.3))
            let badgeSize = NSCollectionLayoutSize(widthDimension: .absolute(20),
                                                  heightDimension: .absolute(20))
            let badge = NSCollectionLayoutSupplementaryItem(
                layoutSize: badgeSize,
                elementKind: PGLAssetGridController.badgeElementKind,
                containerAnchor: badgeAnchor)

            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                 heightDimension: .fractionalHeight(1.0))
//          let item = NSCollectionLayoutItem(layoutSize: itemSize)
           let item = NSCollectionLayoutItem(layoutSize: itemSize, supplementaryItems: [badge])
            item.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                   heightDimension: .fractionalHeight(groupSizeHeight))
    //            .estimated(80.0))  //heightDimension: .absolute(80)

            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: columnCount)

            let spacing = CGFloat(2)
    //        group.interItemSpacing = .fixed(spacing)
            group.interItemSpacing = .flexible(spacing)

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = spacing
            section.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5)

            let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                  heightDimension: .estimated(44)),
                elementKind: PGLAssetGridController.sectionHeaderElementKind,
                alignment: .top)

            sectionHeader.pinToVisibleBounds = true
    //        sectionHeader.zIndex = 2  // what does this do?
                // defn -   default is 0; all other section items will be automatically be promoted to zIndex=1

             section.boundarySupplementaryItems = [sectionHeader ]

            let layout = UICollectionViewCompositionalLayout(section: section)
            return layout
        }
}

extension PGLAssetGridController {
    func configureHierarchy() {
           collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
           collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
           collectionView.backgroundColor = .systemBackground
           collectionView.register(ListCell.self, forCellWithReuseIdentifier: ListCell.reuseIdentifier)
            collectionView.register(BadgeSupplementaryView.self,
                            forSupplementaryViewOfKind: PGLAssetGridController.badgeElementKind,
                            withReuseIdentifier: BadgeSupplementaryView.reuseIdentifier)
           collectionView.register(TitleSupplementaryView.self,
                       forSupplementaryViewOfKind: PGLAssetGridController.sectionHeaderElementKind,
                       withReuseIdentifier: TitleSupplementaryView.reuseIdentifier)

           view.addSubview(collectionView)
           collectionView.delegate = self
       }

     func configureDataSource() {
            dataSource = UICollectionViewDiffableDataSource<PGLAlbumSource, PGLAsset>(collectionView: collectionView) { [weak self]
                (collectionView: UICollectionView, indexPath: IndexPath, identifier: PGLAsset) -> UICollectionViewCell? in
                    guard let self = self
                                          else { return  nil}
                // Get a cell of the desired kind.
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: ListCell.reuseIdentifier,
                    for: indexPath) as? ListCell else { fatalError("Cannot create new cell") }

                // Populate the cell with our item description.
    //            cell.label.text = "\(indexPath.section),\(indexPath.item)"
//                NSLog("PGLAssetGridController #configureDataSource on indexPath = \(indexPath)")
//                NSLog("PGLAssetGridController #configureDataSource on identifier = \(identifier)")
                // range check needed for object(at: indexPath.item)


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
                        }
                    }
                })

                // Return the cell.
                return cell
            }
            dataSource.supplementaryViewProvider = { [weak self]
                (collectionView: UICollectionView, kind: String, indexPath: IndexPath) -> UICollectionReusableView? in
                    guard let self = self
                        else { return  nil}
                // Get a supplementary view of the desired kind.
                // Header label

                switch kind {
                    case PGLAssetGridController.sectionHeaderElementKind :
                        guard let header = collectionView.dequeueReusableSupplementaryView(
                                ofKind: kind,
                                withReuseIdentifier: TitleSupplementaryView.reuseIdentifier,
                                for: indexPath) as? TitleSupplementaryView else { fatalError("Cannot create new header") }

                            // Populate the view with our section's description.


                        NSLog("PGLAssetGridController #configureDataSource supplementaryViewProvider path = \(indexPath)")
                        let thisItem = self.dataSource.itemIdentifier(for: indexPath)
                        let headerText = (thisItem?.collectionTitle ?? "untitled") + (" ...")
                        header.label.text =  headerText
                        header.headerAlbumId = thisItem?.albumId

                            header.backgroundColor = .lightGray
                            header.layer.borderColor = UIColor.black.cgColor
                            header.layer.borderWidth = 1.0

                            // set text size and bold face here
                        self.setOpenZoomGesture(headerCell: header)
                            return header

                    case PGLAssetGridController.badgeElementKind :
                        guard let badgeView = collectionView.dequeueReusableSupplementaryView(
                        ofKind: kind,
                        withReuseIdentifier: BadgeSupplementaryView.reuseIdentifier,
                        for: indexPath) as? BadgeSupplementaryView  else { fatalError("Cannot create new badgeView") }
                        if let myAsset = self.dataSource.itemIdentifier(for: indexPath)  {

                            let cellIsSelected = self.userAssetSelection.contains(localIdentifier: myAsset.localIdentifier)
                                if cellIsSelected {

                                    badgeView.label.text = "-"
                                    badgeView.backgroundColor = .systemBlue
                                    badgeView.label.textColor = .white
                                } else {

                                    badgeView.label.text = "+"
                                    badgeView.label.textColor = .black

                                    badgeView.backgroundColor = .green
                                }
                        } else {NSLog("PGLAssetGridController #configureDataSource() myAsset FAILS at \(indexPath)" )}


                        return badgeView

                    default: return nil

                }
            }

            // initial data

        }
}

    extension PGLAssetGridController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // user may be selecting multiple pictures from the album
         NSLog("PGLAssetGridController didSelectItem at indexPath = \(indexPath) hasCellDoubleTap = \(hasCellDoubleTap) ")

//        userAssetSelection.setCurrentAlbum(forIndexPath: indexPath)
        if let selectedAsset = dataSource.itemIdentifier(for: indexPath) {

            if collectionView.cellForItem(at: indexPath) != nil{
                // REMOVE - selectedCell not needed with identifiers?

                if userAssetSelection.contains(localIdentifier: (selectedAsset.localIdentifier)  )
                    {  // it was selected before - so toggle to deselect state
                        userAssetSelection.removeSourceFromSelection( aPGLAsset: selectedAsset)

                    }

                else {
                    NSLog("PGLAssetGridController didSelecteItem \(selectedAsset.asset.localIdentifier)")
                     userAssetSelection.append(selectedAsset)
                }


            }
            var newSnapShot = dataSource.snapshot()
            newSnapShot.reloadItems([selectedAsset])
            dataSource.apply(newSnapShot)
        }
        hasCellDoubleTap = false // always set to false for next event
        postSelectionChange()
     }

}
