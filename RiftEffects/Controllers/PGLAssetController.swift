/*
	Copyright (C) 2017 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Displays a single photo, live photo, or video asset and demonstrates simple editing.
 */


import UIKit
import Photos
import PhotosUI
import os



class PGLAssetController: UIViewController {

    var asset: PGLAsset!
    var assetIndex = 0
    var selectedAlbumId: String?
    var userAssetSelection: PGLUserAssetSelection!

    var notifications = [Any]() // an opaque type is returned from addObservor
    var swiper: UISwipeGestureRecognizer!

    @IBOutlet weak var imageView: UIImageView!



    @IBOutlet var favoriteButton: UIBarButtonItem!


    @IBOutlet weak var badgeBtn: UIButton!


    @IBOutlet weak var gestureView: UIView!

    // MARK: UIViewController / Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        Logger(subsystem: LogSubsystem, category: LogNavigation).info("\( String(describing: self) + "-" + #function)")
        asset = userAssetSelection.asset(position: assetIndex,albumId: selectedAlbumId)
            // selectedAlbumId may be nil - uses selectedAssets
//        NSLog("PGLAssetController #viewDidLoad")
        if asset == nil { return }
        navigationItem.title = userAssetSelection.headerTitle(albumId: selectedAlbumId)
        navigationController?.isToolbarHidden = false
 

        setLeftRightBtns(enableOn: ( userAssetSelection.isFetchMultiple() ) )


//        view.isUserInteractionEnabled = true
            // set in IB attributes of the view
            // for the swipe gesture


    }

  

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let myCenter =  NotificationCenter.default
        let queue = OperationQueue.main

        // this uses PGLImageCollectionChange.. while ImageCollectionMaster signals
        // PGLImageCollectionChange  in PGLImagesSelectContainter to PGLImageAlbumAdded
       var aNotification = myCenter.addObserver(forName: PGLImageCollectionChange , object: nil , queue: queue) { [weak self]
        myUpdate in
        guard let self = self else { return } // a released object sometimes receives the notification
                      // the guard is based upon the apple sample app 'Conference-Diffable'
        Logger(subsystem: LogSubsystem, category: LogNavigation).debug("PGLAssetController  notificationBlock PGLImageCollectionChange")
        if let assetInfo = ( myUpdate.userInfo?["assetInfo"]) as? PGLAlbumSource {
            let userSelectionInfo = PGLUserAssetSelection(assetSources: assetInfo)
            if self.userAssetSelection.merge(newAssetSource: userSelectionInfo) != nil {
                self.selectedAlbumId = assetInfo.identifier
                self.assetIndex = 0
                self.asset = self.userAssetSelection.asset(position: self.assetIndex,albumId: self.selectedAlbumId)
                self.navigationItem.title = self.userAssetSelection.headerTitle(albumId: self.selectedAlbumId)
                self.updateImage()
                self.setLeftRightBtns(enableOn: self.userAssetSelection.isFetchMultiple() )
            }
            }
        }
        notifications.append(aNotification)

        aNotification = myCenter.addObserver(forName: PGLImageNavigationBack , object: nil , queue: queue) { [weak self ]
           myUpdate in
            guard let self = self else { return } // a released object sometimes receives the notification
                          // the guard is based upon the apple sample app 'Conference-Diffable'
            // PGLImageCollectionMasterController in the master section is navigating back.
            // navigate back here too
            Logger(subsystem: LogSubsystem, category: LogNavigation).debug("PGLAssetController  notificationBlock PGLImageNavigationBack")
//            NSLog("PGLAssetController navigationController.viewControllers = \(self.navigationController?.viewControllers)")
            if let imageController = self.navigationController?.viewControllers.first {

                self.navigationController?.popToViewController(imageController, animated: true)
            }
                // else if no imageController then this is a second notify after navigation has popped to the image controller
                // and do nothing :)
        }
        notifications.append(aNotification)
        if asset == nil { return }
        
        favoriteButton.title = asset.asset.isFavorite ? "♥︎" : "♡"
        favoriteButton.isEnabled = asset.asset.canPerform(.properties)

        // Make sure the view layout happens before requesting an image sized to fit the view.
        view.layoutIfNeeded()
        updateImage()
        setSwipe()
        self.setLeftRightBtns(enableOn: self.userAssetSelection.isFetchMultiple() )

    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
       for anObserver in  notifications {
           NotificationCenter.default.removeObserver(anObserver)
       }
       notifications = [Any]() // reset
        navigationController?.isToolbarHidden = true

        removeSwipe()
    }

    // MARK: UI Actions


    
    @IBAction func assetSelectDone(_ sender: UIBarButtonItem) {
        // return to the  assetGrid and add this image asset
        // to the current grid selection
//        NSLog("PGLAssetController #assetSelectDone btn action")
        // keep the image highlight in the assetGrid
        Logger(subsystem: LogSubsystem, category: LogCategory).notice("PGLAssetController #assetSelectDone popViewController")
        navigationController?.popViewController(animated: true) 

    }

    func nextImage(direction: UISwipeGestureRecognizer.Direction) {
        var increment = 0 // don't move initial
        let maxIndex = userAssetSelection.fetchCount(albumId: selectedAlbumId) - 1
            // zero based array subtract 1 from count

        switch direction {
            case .right:
                increment = 1
            case .left:
                increment = -1
            default:
            increment = 0
        }

        // positive direction guard
        if (assetIndex >=  maxIndex ) && (direction == .right) {
            assetIndex = -1 }  // increments to zero next

        // negative direction guard
        if (assetIndex <= 0) && (direction == .left) {
            assetIndex = maxIndex + 1 } // increments to maxIndex next
        if (userAssetSelection.isFetchMultiple()) {
            // confirms assets are left in collection - user has not removed last one
            assetIndex += increment
            asset = userAssetSelection.asset(position: assetIndex, albumId: selectedAlbumId)
        }
        self.setLeftRightBtns(enableOn: (self.userAssetSelection.isFetchMultiple()))
        updateImage()

    }

    func setLeftRightBtns(enableOn: Bool) {
        leftBarBtn.isEnabled = enableOn
        rightBarBtn.isEnabled = enableOn
    }

    @IBOutlet weak var leftBarBtn: UIBarButtonItem!
    @IBOutlet weak var rightBarBtn: UIBarButtonItem!

    @IBAction func rightToolBarAction(_ sender: UIBarButtonItem) {
        nextImage(direction: .right)
    }
   

    @IBAction func leftToolBarAcdtion(_ sender: UIBarButtonItem) {
        nextImage(direction: .left)
    }

    @IBAction func badgeBtnToggle(_ sender: UIButton) {
        let imageWasSelected = userAssetSelection.contains(localIdentifier: asset.localIdentifier)
          // if the image is in the userSelection then it can be removed
        if imageWasSelected {
            userAssetSelection.remove(asset)
        } else {
             userAssetSelection.append(asset)
        }
        // toggle UI to other state
        setBadgeUI(isUserSelected: !imageWasSelected)
    }

    func setBadgeUI(isUserSelected: Bool) {
              // image selected state badge should be green and minus symbol
              // image not selected state badge should be blue and plus symbol
              if isUserSelected {
                    badgeBtn.isSelected = true // uses minus symbol in IB
                    badgeBtn.tintColor =  .systemBlue

              }
              else {
                badgeBtn.isSelected = false  // uses plus symbol in IB
                badgeBtn.tintColor = .systemGreen

              }

    }

    @IBAction func toggleFavorite(_ sender: UIBarButtonItem) {
//        NSLog("PGLAssetController \(#function)")
        if let thePHAsset = self.asset?.asset {
                PHPhotoLibrary.shared().performChanges({
                let request = PHAssetChangeRequest(for: thePHAsset)
                request.isFavorite = !thePHAsset.isFavorite

                }, completionHandler: { success, error in
                    if success {
                        DispatchQueue.main.sync {
                            sender.title = thePHAsset.isFavorite ? "♥︎" : "♡"
                            //                    self.navigationItem.setRightBarButton(sender, animated: true) // actually it is the nav bar that needs the update
                            // updating is not working right... there is a caching going on too.

                        }
                    } else {
                        print("can't set favorite: \(String(describing: error))")
                    }
                })
        }
    }
    // MARK: Gestures


    func setSwipe() {
        swiper = UISwipeGestureRecognizer(target: self, action: #selector(PGLAssetController.swipeAction(_:)))
        if swiper != nil {
            swiper.isEnabled = true
            swiper.direction = .right
            swiper.numberOfTouchesRequired = 1  // default
            gestureView.addGestureRecognizer(swiper)


        }

    }

    @IBAction func leftSwipeAction(_ sender: UISwipeGestureRecognizer) {
        if sender.state == .ended {
               nextImage(direction: sender.direction)
        }

    }
    @objc func swipeAction(_ gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
        if swipeGesture.state == .ended {
                   nextImage(direction: swipeGesture.direction)
            }
        }
        
    }

    func removeSwipe() {
        if swiper != nil {
//             swiper.removeTarget(self, action: #selector(swipeAction(_:)))
            gestureView.removeGestureRecognizer(swiper)
             swiper = nil
        }
    }

    // MARK: Image display

    var targetSize: CGSize {
        let scale = UIScreen.main.scale
        return CGSize(width: imageView.bounds.width * scale,
                      height: imageView.bounds.height * scale)
    }

    func updateImage() {

        updateStaticImage()

        favoriteButton.title = asset.asset.isFavorite ? "♥︎" : "♡"
        favoriteButton.isEnabled = asset.asset.canPerform(.properties)

    }

    func isSelected(asset: PHAsset) -> Bool {
        // answer true if the asset is in the userAssetSelection
        return userAssetSelection.contains(localIdentifier: asset.localIdentifier)
    }



    func updateStaticImage() {
        // Prepare the options to pass when fetching the (photo, or video preview) image.
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
//        options.progressHandler = { progress, _, _, _ in
//            // Handler might not be called on the main queue, so re-dispatch for UI work.
//            DispatchQueue.main.sync {
//                self.progressView.progress = Float(progress)
//            }
//        }

        PHImageManager.default().requestImage(for: asset.asset, targetSize: targetSize, contentMode: .aspectFit, options: options, resultHandler: { image, _ in
            // Hide the progress view now the request has completed.
//            self.progressView.isHidden = true

            // If successful, show the image view and display the image.
            guard let image = image else { return }

            // Now that we have the image, show it.
//            self.livePhotoView.isHidden = true
            self.imageView.isHidden = false
            self.imageView.image = image

        })
        let  imageIsUserSelected = userAssetSelection.contains(localIdentifier: asset.localIdentifier)
        // if the image not in the userSelection then it can be added
        // image selected state badge should be blue and minus symbol
        // image not selected state badge should be green and plus symbol
        setBadgeUI(isUserSelected: imageIsUserSelected)

}


    // MARK: Asset editing

    func revertAsset(sender: UIAlertAction) {
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetChangeRequest(for: self.asset.asset)
            request.revertAssetContentToOriginal()
        }, completionHandler: { success, error in
            if !success { print("can't revert asset: \(String(describing: error))") }
        })
    }

    // Returns a filter-applier function for the named filter, to be passed as a UIAlertAction handler

}




