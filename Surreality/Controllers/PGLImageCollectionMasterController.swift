/*
	Copyright (C) 2017 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Manages the top-level table view, a list of photo collections.
 */


import UIKit
import Photos

let PGLImageCollectionClose = NSNotification.Name(rawValue: "PGLImageCollectionClose")
let PGLImageCollectionOpen = NSNotification.Name(rawValue: "PGLImageCollectionOpen")
let PGLImageCollectionChange = NSNotification.Name(rawValue: "PGLImageCollectionChange")
let PGLImageNavigationBack = NSNotification.Name(rawValue: "PGLImageNavigationBack")

 enum PhotoTypeIdentifier: String {

        case smartAlbum
        case album
        case userCollections
//        case moments
    }

    enum SegueIdentifier: String {

        case showCollection
    }

    // work on showing segue of PHCollectionListType.folder and subtype  PHCollectionListSubtype.regularFolder
    let PhotoCollectionListTypes = [PHCollectionListType.folder,
//                               PHCollectionListType.momentList,
                               PHCollectionListType.smartFolder]
    // the enum is not CaseIterable
    // hence using array of the enum so that count and iteration can be used
    // add new enum cases in future iOS?

    let PhotoCollectionListSubtypes = [
//                                PHCollectionListSubtype.momentListCluster,
//                                  PHCollectionListSubtype.momentListYear,
                                  PHCollectionListSubtype.regularFolder,
                                  PHCollectionListSubtype.smartFolderEvents,
                                  PHCollectionListSubtype.smartFolderFaces]
    // omitting .any
    // the enum is not CaseIterable
    // same use as ListTypes..need for count & iteration on the enum

// MARK: Types for managing sections, cell and segue identifiers
 enum Section: Int {
     // regular folders are userCollections

     case smartAlbum = 0
     case userCollections = 1

     case album = 2

     static let count = 3

     func description() -> String {
            switch self {
            case .smartAlbum :
                return sectionLocalizedTitles[0]
            case .userCollections:
                return sectionLocalizedTitles[1]
            case .album:
                return sectionLocalizedTitles[2]
            }
        }
        func secondaryDescription() -> String {
            switch self {
            case .userCollections:
                return "User Collections"
            default:
                return ""
            }
        }
 }
 // Section and sectionLocalizedTitles could be a tuple of Int & String
 // they have to stay in sync.

 let sectionLocalizedTitles = [
       NSLocalizedString("Smart Albums", comment: ""),
       NSLocalizedString("Collections", comment: ""),
       NSLocalizedString("Albums", comment: "")
     ]

class PGLImageCollectionMasterController: UIViewController, UINavigationControllerDelegate {


    // MARK: Properties
    var dataSource: PGLDataSource! = nil

    var albumTableView: UITableView! = nil
        // assigned in configureHierarchy of viewDidLoad
    let searchBar = UISearchBar(frame: .zero)

    var identifierIndexPathDict = [String:IndexPath]()
        // key is collection localIdentifier value is the IndexPath of the row in the view

    var smartAlbums: PHFetchResult<PHAssetCollection>?
    var albums: PHFetchResult<PHAssetCollection>?
    var userCollections: PHFetchResult<PHCollection>?

    var fetchResult = PGLFetchResults()
    var appStack: PGLAppStack!

    let indentBy = 1

    var notifications = [Any]() // an opaque type is returned from addObservor


    var inputFilterAttribute: PGLFilterAttributeImage? // PGLFilterAttribute?  // model object for updates
    //  PGLFilterAttributeImage this controller is only for images

    // MARK: UIViewController / Lifecycle
    
     func fetchTopLevel() {
        //        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.addAlbum))
        //        self.navigationItem.rightBarButtonItem = addButton


        // Create a PHFetchResult object for each section in the table view.
        // if user has not granted PhotoLibrary permission then a dialog appears
        
        smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any , options: nil)
        if !isLimitedPhotoLibAccess() {
            albums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular , options: nil)
            userCollections = PHCollectionList.fetchTopLevelUserCollections(with: nil)
        }
            // all of these should have drill down to contents

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // if the tappedAttribute has an input then highlight and show it
        NSLog("PGLImageCollectionMasterController viewDidLoad")
//        PHPhotoLibrary.shared().register(self)
//        PHPhotoLibrary.shared().unregisterChangeObserver(self)
        // in theory register as observor for permission changes then update an existing query
        // see PhotoKit 'Requesting Authorization to View Photos'
        // Use the registerChangeObserver: method to observe photo library changes before fetching content.
        // After the user grants your app access to the photo library,
        // Photos sends change messages for any empty fetch results you retrieved earlier,
        // notifying you that library content for those fetches is now available.


        navigationController?.delegate = self
        // assume that fetchTopLevel has populated the albums,smartAlbums & userCollections
       guard let myAppDelegate =  UIApplication.shared.delegate as? AppDelegate
                         else { fatalError("AppDelegate not loaded")}
                     appStack = myAppDelegate.appStack




        configureHierarchy()
        configureDataSource()
//        performQuery(with: nil)
    }





    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        performQuery(with: nil)

         NSLog("PGLImageCollectionMasterController viewDidAppear")
        let myCenter =  NotificationCenter.default
              let queue = OperationQueue.main

         let selectImageBack = myCenter.addObserver(forName: PGLSelectImageBack , object: nil , queue: queue) { [weak self ]
                        myUpdate in
            guard let self = self else { return } // a released object sometimes receives the notification
                // the guard is based upon the apple sample app 'Conference-Diffable'
                 // navigate back here too
                NSLog("PGLImageCollectionMasterController \(self) PGLSelectImageBack notification received - viewDidLoad")
                self.navigationController?.popViewController(animated: true)
                }


           let imageAccepted =  myCenter.addObserver(forName: PGLImageAccepted, object: nil , queue: queue) {[weak self]
                   myUpdate in
                guard let self = self else { return } // a released object sometimes receives the notification
                              // the guard is based upon the apple sample app 'Conference-Diffable'
                   NSLog("PGLImageCollectionMasterController  notificationBlock PGLImageAccepted viewDidAppear  ")
                self.navigationController?.popViewController(animated: true)

               }
        notifications.append(selectImageBack)
        notifications.append(imageAccepted)

        if inputFilterAttribute?.hasImageInput() ?? false {
            // select the cells of the collections/albums
            // fill the grid with the images
            // more than one album may be included
            NSLog("PGLImageCollectionMasterController input images already exist")

            guard let firstCollection = inputFilterAttribute?.inputCollection?.sourceAssetCollection()
                else { return  }


            // mark rows of albums in userAssetSelection as selected
            let currentSnapShot = dataSource.snapshot()
            let currentItems = currentSnapShot.itemIdentifiers
            var unloadedAlbums = [PGLUUIDAssetCollection]()
            var lastItemIndexPath = IndexPath(row: 0, section: 0)
            if let currentUserSelection = inputFilterAttribute?.inputCollection?.userSelection {
                for userAlbumId in currentUserSelection.sectionAlbumIdentifiers() {
                    // get the indexPath
                    if let matchingItem = currentItems.first(where: {$0.albumIdentifier() == userAlbumId}) {
                    let albumPath = dataSource.indexPath(for: matchingItem)
                    albumTableView.selectRow(at: albumPath, animated: true, scrollPosition: UITableView.ScrollPosition.none)
                        //  don't scroll for each album
                    lastItemIndexPath = albumPath!
                    } else {
                        // album is not visible.. load it
                      let  notLoadedAlbum:  PHAssetCollection? =
                               { let fetchResult = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [userAlbumId], options: nil)
                                   return fetchResult.object(at: 0)
                               }()
                        if let notLoadedUUIDCollection = PGLUUIDAssetCollection(notLoadedAlbum) {
                            unloadedAlbums.append(notLoadedUUIDCollection) }
                    }

                }
                if !unloadedAlbums.isEmpty {
                    appendToDataSource(albums: unloadedAlbums, section: Section.album.rawValue)
                    // should select the unloadedAlbum rows...??
                }
                albumTableView.scrollToRow(at: lastItemIndexPath, at: .none, animated: true)
                // scroll to last album.
            }


            openImageCollection(assetCollection: firstCollection)
            }
        else {
            // no user input.. esp for limitedAccess mode
            if isLimitedPhotoLibAccess() {
                // Recents album is most likely to have the user picked images for access
                // which is the first index path
                let recentsRow = IndexPath(item: 0, section: 0)
                albumTableView.selectRow(at: recentsRow, animated: true, scrollPosition: UITableView.ScrollPosition.none)
                tableView(albumTableView, didSelectRowAt: recentsRow)
            }
        }

    }

    override func viewWillDisappear(_ animated: Bool) {
        for anObserver in  notifications {
            NotificationCenter.default.removeObserver(anObserver)
        }
        notifications = [Any]() // reset

    }
// MARK: Navigation Bar

    @IBAction func backBtnClick(_ sender: UIBarButtonItem) {
        let actionAccepted = Notification(name: PGLImageNavigationBack )
               NotificationCenter.default.post(actionAccepted)

               self.navigationController?.popViewController(animated: true)

    }
  



    // MARK: Table View

    func openImageGrid(indexPath: IndexPath) {
         // signals to the appStack to change the imageController to the imageGrids display
         // passes the assets to display in the userInfo


         if let uuidCollection = dataSource.itemIdentifier(for: indexPath) {

            openImageCollection(assetCollection: uuidCollection.getCollection())
         }
     }


    func openImageCollection(assetCollection: PHCollection) {
        // signals to the appStack to change the imageController to the imageGrids display
        // passes the assets to display in the userInfo


//        if let rowAssets = getCellAssets(indexPath) {
    

        if let anAssetCollection = assetCollection as? PHAssetCollection {
         let collectionFetch =   PHAsset.fetchAssets(in: anAssetCollection, options: nil)

            let theInfo = PGLAlbumSource(anAssetCollection, collectionFetch)
            theInfo.filterParm = inputFilterAttribute
            // show the content images of the selected collection for user pick

            // if thePGLImagesSelectContainer is open notify it to merage the new info
            // with the existing info - ie keep the current user selection and show another album as a source
            if appStack.isImageControllerOpen {

                 NSLog("PGLImageCollectionMasterController #openImageGrid notification =  PGLImageCollectionOpen")
                let updateFilterNotification = Notification(name:PGLImageCollectionOpen)

                NotificationCenter.default.post(name: updateFilterNotification.name, object: nil, userInfo: ["assetInfo": theInfo as Any])
            }
            else { // image collection is not open -
                // just combine the userSelection.. send to the Asset container to merge

                NSLog("PGLImageCollectionMasterController #openImageGrid notification =  PGLImageCollectionChange")
                let changeAlbumNotification = Notification(name:PGLImageCollectionChange)

                NotificationCenter.default.post(name: changeAlbumNotification.name, object: nil, userInfo: ["assetInfo": theInfo as Any])
            }
        } else {
            // limited access mode on Recents
            let updateFilterNotification = Notification(name:PGLImageCollectionOpen)

            NotificationCenter.default.post(name: updateFilterNotification.name, object: nil, userInfo: nil)
        }
    }


     func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        return sectionLocalizedTitles[section]
// OR
         let sectionKind = Section(rawValue: section)
          return sectionKind?.description()
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard let collectionSelected = dataSource.itemIdentifier(for: indexPath)
                  else { return }

        collectionSelected.isSelected = false

            let selectionRemoved = Notification(name: PGLImageAlbumSelectionRemoved )
            if let albumRemovedId = collectionSelected.assetCollection?.localIdentifier {

            NotificationCenter.default.post(name: selectionRemoved.name, object: nil, userInfo: ["albumId": albumRemovedId as Any])

        }

    }

     func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        NSLog("PGLImageCollectionMaster #didSelectRowAt")
        // highlight this cell
        // notify the detail controller to show the assets in this cell

        guard var collectionSelected = dataSource.itemIdentifier(for: indexPath)
            else { return }
        if collectionSelected.isCollectionList() {
            let wasExpanded = collectionSelected.isExpanded
            // hold old state
            NSLog("PGLImageCollectionMaster #didSelectRowAt wasExpanded = \(wasExpanded)")
            if wasExpanded
                { hideSubItemsQuery(collectionListItem: collectionSelected)}
            else
                { performExpandCollectionList(collectionItem: &collectionSelected ) }
           
        }
        else {
            collectionSelected.isSelected = true
            // an album / collection - show it
            openImageGrid(indexPath: indexPath) }
    }

}


// MARK: CompositionLayout
extension PGLImageCollectionMasterController: UITableViewDelegate {

    func isLimitedPhotoLibAccess() -> Bool {
        let accessLevel: PHAccessLevel = .readWrite // or .addOnly
        let authorizationStatus = PHPhotoLibrary.authorizationStatus(for: accessLevel)

        switch authorizationStatus {
            case .limited :
            return true
        default:
            // all other authorizationStatus values
           return false
        }
    }

    func getSmartAlbums() -> [PGLUUIDAssetCollection] {
        // make this generic with types parm?
        var answer = [PGLUUIDAssetCollection]()
        for index in 0 ..< (smartAlbums?.count ?? 0) {
            if let castAlbum = smartAlbums?.object(at: index) {
                answer.append(PGLUUIDAssetCollection( castAlbum)!)
            }
        }
         NSLog("PGLImageCollectionMasterController #getSmartAlbums count = \(answer.count)")
        return answer
    }


    func getAlbums() -> [PGLUUIDAssetCollection] {
        // make this generic with types parm?
        var answer = [PGLUUIDAssetCollection]()
        for index in 0 ..< (albums?.count ?? 0) {
            if let castAlbum = albums?.object(at: index) {
                answer.append( PGLUUIDAssetCollection( castAlbum)!)
            }
        }
        NSLog("PGLImageCollectionMasterController #getAlbums count = \(answer.count)")
        return answer
    }

    func getUserCollections() -> [PGLUUIDAssetCollection] {
           // make this generic with types parm?
           var answer = [PGLUUIDAssetCollection]()
           for index in 0 ..< (userCollections?.count ?? 0) {
               if let castAlbum = userCollections?.object(at: index)  {
                   answer.append( PGLUUIDAssetCollection( castAlbum)!)
               }
           }
        NSLog("PGLImageCollectionMasterController #getUserCollections count = \(answer.count)")
           return answer
       }




    func configureHierarchy() {
        albumTableView = UITableView(frame: .zero, style: .insetGrouped)
        albumTableView.translatesAutoresizingMaskIntoConstraints = false

         searchBar.translatesAutoresizingMaskIntoConstraints = false

        albumTableView.backgroundColor = .systemBackground
        albumTableView.register(OutlineItemCell.self, forCellReuseIdentifier: OutlineItemCell.reuseIdentifer)
        albumTableView.allowsMultipleSelection = true
        view.addSubview(albumTableView)

         view.addSubview(searchBar)

        let views = ["cv": albumTableView as Any, "searchBar": searchBar] as [String : Any] //as! [String : UIView]
          var constraints = [NSLayoutConstraint]()
          constraints.append(contentsOf: NSLayoutConstraint.constraints(
              withVisualFormat: "H:|[cv]|", options: [], metrics: nil, views: views))
          constraints.append(contentsOf: NSLayoutConstraint.constraints(
              withVisualFormat: "H:|[searchBar]|", options: [], metrics: nil, views: views))
          constraints.append(contentsOf: NSLayoutConstraint.constraints(
              withVisualFormat: "V:[searchBar]-20-[cv]|", options: [], metrics: nil, views: views))
          constraints.append(searchBar.topAnchor.constraint(
              equalToSystemSpacingBelow: view.safeAreaLayoutGuide.topAnchor, multiplier: 1.0))
          NSLayoutConstraint.activate(constraints)


        albumTableView.delegate = self
        searchBar.delegate = self
    }

    func configureDataSource() {
        let reuseIdentifier = OutlineItemCell.reuseIdentifer

        dataSource = PGLDataSource(tableView: albumTableView) { (tableView, indexPath, assetCollection) -> OutlineItemCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as? OutlineItemCell

            if let cell = cell  {
                cell.textLabel?.text = assetCollection.getCollection().localizedTitle
                cell.isGroup = assetCollection.isCollectionList()

                cell.isExpanded = assetCollection.isExpanded
                cell.indentLevel = assetCollection.indentLevel
//                cell.isHighlighted = assetCollection.isHighLighted

                return cell
            } else {
                fatalError("failed to create a new cell")
            }
        }

        // initial data


    }


    func performQuery(with filter: String?) {

        let isFullAccess = !isLimitedPhotoLibAccess()
            // keep the sections lined up with the items

        var currentAlbums = getSmartAlbums()
        let matchSmartAlbums = filterAlbums(source: currentAlbums, titleString: filter)

       currentAlbums = getUserCollections()
        let matchUserAlbums = filterAlbums(source: currentAlbums, titleString: filter)

        currentAlbums = getAlbums()
        let matchAlbums = filterAlbums(source: currentAlbums, titleString: filter)


        var snapshot = NSDiffableDataSourceSnapshot<Int, PGLUUIDAssetCollection>()

        snapshot.appendSections([Section.smartAlbum.rawValue])
        snapshot.appendItems(matchSmartAlbums,toSection: Section.smartAlbum.rawValue )

        if isFullAccess {
            snapshot.appendSections([Section.userCollections.rawValue])
             snapshot.appendItems(matchUserAlbums, toSection: Section.userCollections.rawValue)

             snapshot.appendSections([Section.album.rawValue])
            snapshot.appendItems(matchAlbums, toSection: Section.album.rawValue)
        }

        dataSource.apply(snapshot, animatingDifferences: true)


    }

    func appendToDataSource(albums: [PGLUUIDAssetCollection], section: Int){
       var aSnapShot = dataSource.snapshot()

        aSnapShot.appendItems(albums, toSection: section)
        dataSource.apply(aSnapShot, animatingDifferences: false)

    }
    func expandQuery(fromCollectionListItem: PGLUUIDAssetCollection) {
        // the collectionListItem has child Lists..
        // add to the query

        var snapshot = dataSource.snapshot()

        fromCollectionListItem.setIsExpanded(newValue: true)
        snapshot.reloadItems([fromCollectionListItem])
        snapshot.insertItems(fromCollectionListItem.childCollections, afterItem: fromCollectionListItem)

        dataSource.apply(snapshot, animatingDifferences: true)

    }

    func hideSubItemsQuery(collectionListItem: PGLUUIDAssetCollection) {
        // assumes that subitems of the collectionList are in the datasource
        // ie expandQuery has been run
//        _ = cloneItem(changeItem: collectionListItem)

        var snapshot = dataSource.snapshot()
        let subItems = collectionListItem.childCollections
        snapshot.deleteItems(subItems)

        collectionListItem.setIsExpanded(newValue:false)
        snapshot.reloadItems([collectionListItem])

        dataSource.apply(snapshot, animatingDifferences: true)
    }

    func performExpandCollectionList( collectionItem: inout PGLUUIDAssetCollection) {
        //expand the dataSource to include items in the collectionItem which is a collectionList
        var newbie: PGLUUIDAssetCollection?
        guard let thisList = collectionItem.collectionList
            else {return}
        if (collectionItem.childCollections.isEmpty) {

            let listFetch =  PHCollectionList.fetchCollections(in: thisList , options: nil)
            NSLog("performExpandCollectionList listFetch count = \(listFetch.count)")

            for index in 0 ..< (listFetch.count ) {
                 newbie = PGLUUIDAssetCollection( listFetch.object(at: index))
                 if newbie == nil { continue }
                 newbie!.indentLevel = collectionItem.indentLevel + indentBy
                    collectionItem.childCollections.append( newbie!)
                }
            }

        expandQuery(fromCollectionListItem: collectionItem)
    }

    func filterAlbums(source: [PGLUUIDAssetCollection], titleString: String?) -> [PGLUUIDAssetCollection] {
        if titleString == nil { return source }
        else { return source.filter { $0.contains(titleString)} }
    }

    func configureNavigationItem() {
           navigationItem.title = "Collections"
           let editingItem = UIBarButtonItem(title: albumTableView.isEditing ? "Done" : "Edit", style: .plain, target: self, action: #selector(toggleEditing))
           navigationItem.rightBarButtonItems = [editingItem]
       }
 
       @objc
       func toggleEditing() {
           albumTableView.setEditing(!albumTableView.isEditing, animated: true)
           configureNavigationItem()
       }
}


extension PGLImageCollectionMasterController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        performQuery(with: searchText)
    }
}

// MARK: PHPhotoLibraryChangeObserver
//extension PGLImageCollectionMasterController: PHPhotoLibraryChangeObserver {
//
//    func photoLibraryDidChange(_ changeInstance: PHChange) {
//        // Change notifications may be made on a background queue. Re-dispatch to the
//        // main queue before acting on the change as we'll be updating the UI.
//        DispatchQueue.main.sync {
//            // Check each of the three top-level fetches for changes.
//
//            // Update the cached fetch results, and reload the table sections to match.
//            if smartAlbums != nil {
//                if let changeDetails = changeInstance.changeDetails(for: smartAlbums!) {
//                    smartAlbums = changeDetails.fetchResultAfterChanges
//                    collectionView.reloadSections(IndexSet(integer: Section.smartAlbum.rawValue), with: .automatic)
//                }
//            }
//            if userCollections != nil {
//                if let changeDetails = changeInstance.changeDetails(for: userCollections!) {
//                    userCollections = changeDetails.fetchResultAfterChanges
//                    selectionView.reloadSections(IndexSet(integer: Section.userCollections.rawValue), with: .automatic)
//                }
//            }
//
//        }
//    }
//}

struct PGLFetchResults {
    //knows what type of fetch result is held for display.
    // This is a composite result for the segue of PGLImagCollectionMasterController


    var smartAlbums: PHFetchResult<PHAssetCollection>?
    var albums: PHFetchResult<PHAssetCollection>?
    var userCollections: PHFetchResult<PHCollection>?


    func hasResults() -> Bool {
        // answer true if at least one var has a fetch result

        if smartAlbums != nil { return true }

        if albums != nil { return true }

        if userCollections != nil { return true }


        return false


    }
}


