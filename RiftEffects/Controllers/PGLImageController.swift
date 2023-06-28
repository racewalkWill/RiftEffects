//
//  PGLImageController.swift
//  PictureGlance
//
//  Created by Will Loew-Blosser on 5/7/17.
//  Copyright © 2017 Will Loew-Blosser LBSoftwareArtist. All rights reserved.
//

import UIKit
import AVFoundation
import GLKit
import MetalKit
import Photos
import os

enum PGLFilterPick: Int {
    case category = 0, filter

    static func numFilterPicks() -> Int
    { return 2 }

}

enum SliderColor: Int {
    case Alpha = 0
    case Blue = 1
    case Green = 2
    case Red = 3
}

let  PGLCurrentFilterChange = NSNotification.Name(rawValue: "PGLCurrentFilterChangeNotification")
//let  PGLOutputImageChange = NSNotification.Name(rawValue: "PGLOutputImageChange")
let  PGLUserAlertNotice = NSNotification.Name(rawValue: "PGLUserAlertNotice")
let  PGLUpdateLibraryMenu = NSNotification.Name(rawValue: "PGLUpdateLibraryMenu")
let  PGLHideImageViewReleaseStack = NSNotification.Name(rawValue: "PGLHideImageViewReleaseStack")
let PGLHideParmUIControls = NSNotification.Name(rawValue: "PGLHideParmUIControls")

let ExportAlbumId = "ExportAlbumId"
let ExportAlbum = "ExportAlbum"

let ShowHelpPageAtStartupKey = "DisplayStartHelp"

class PGLImageController: PGLCommonController, UIDynamicAnimatorDelegate, UINavigationBarDelegate {


    // controller in detail view - shows the image as filtered - knows the current filter

// MARK: Property vars

    static var LibraryMenuIdentifier = UIAction.Identifier("Library")
//

    var videoPreviewViewBounds = CGRect.init()
    var myScale: CGFloat = 1.0
    var myScaleFactor: CGFloat = 1.0
    var myScaleTransform: CGAffineTransform = CGAffineTransform.identity

    var filterStack: () -> PGLFilterStack?  = { PGLFilterStack() } // a function is assigned to this var that answers the filterStack



    var parmController: PGLSelectParmController?
    var metalController: PGLMetalController?

   let debugLogDrawing = false
    let crossPoint = UIImage(systemName: "plus.circle.fill")
//    let reverseCrossPoint = UIImage(systemName: "plus.circle")



    // MARK: control Vars

    var keepParmSlidersVisible = false
        // when navigating in .phone vertical compact from parms keep
        // parm value controllers visible in the imageController

    @IBOutlet weak var parmSlider: UISlider!


    @IBAction func sliderValueEvent(_ sender: UISlider) {

        sliderValueDidChange(sender)
        // should be self sliderValueDidChange...
        // hook up the event triggers !
    }

    // MARK: Gesture vars
    var startPoint = CGPoint.zero
    var endPoint = CGPoint.zero
    var panner: UIPanGestureRecognizer?
    var selectedParmControlView: UIView?
    var tappedControl: UIView?


        // MARK: Navigation Buttons

    @IBOutlet var sliders: [UISlider]! { didSet {
        for aSlider in sliders {
            taggedSliders[aSlider.tag] = aSlider
        }
    }}

    var taggedSliders = [Int:UISlider]()

    @IBOutlet weak var helpBtn: UIBarButtonItem!
    
    @IBOutlet weak var moreBtn: UIBarButtonItem!

    @IBOutlet weak var randomBtn: UIBarButtonItem! {
        didSet{
            if isLimitedPhotoLibAccess() {
                randomBtn.isEnabled = false
                // if user changes privacy settings then the view is reloaded
                // and the button is enabled.. without quitting the app
                }
            }
    }

    @IBOutlet weak var toggleAnimationPauseBtyn: UIBarButtonItem!

    @IBAction func toggleAnimationPause(_ sender: UIBarButtonItem) {
        let updateNotification = Notification(name:PGLPauseAnimation)
        NotificationCenter.default.post(name: updateNotification.name, object: nil, userInfo: nil )
    }



    @IBAction func randomBtnAction(_ sender: UIBarButtonItem) {
//        NSLog("PGLImageController addRandom button click")
        let setInputToPrior = appStack.viewerStack.stackHasFilter()

        let demoGenerator = PGLDemo()
//        appStack.removeDefaultEmptyFilter()
        demoGenerator.appStack = appStack // pass on the stacks
        let startingDemoFilter = demoGenerator.multipleInputTransitionFilters()

        appStack.viewerStack.activeFilterIndex = 0
        if setInputToPrior {
            startingDemoFilter.setInputImageParmState(newState: ImageParm.inputPriorFilter)
        }
        postCurrentFilterChange() // triggers PGLImageController to set view.isHidden to false
            // show the new results !

        showStackControllerAction()
        updateNavigationBar()


    }



    // MARK: save btn Actions

    func saveStackActionBtn(_ sender: UIBarButtonItem) {

        guard let saveDialogController = storyboard?.instantiateViewController(withIdentifier: "PGLSaveDialogController") as? PGLSaveDialogController
        else {
            return
        }
        saveDialogController.doSaveAs = false
        presentSaveDialog(saveDialogController: saveDialogController)

        updateNavigationBar()

    }

    func saveStackAsActionBtn(_ sender: UIBarButtonItem) {

        guard let saveDialogController = storyboard?.instantiateViewController(withIdentifier: "PGLSaveDialogController") as? PGLSaveDialogController
        else {
            return
        }
        saveDialogController.doSaveAs = true
        presentSaveDialog(saveDialogController: saveDialogController)



    }

   func openStackActionBtn(_ sender: UIBarButtonItem) {

//            let pickStoredStackViewController = storyboard!.instantiateViewController( withIdentifier: "OpenStackController")
       let pickStoredStackViewController = PGLLibraryController()

       pickStoredStackViewController.modalPresentationStyle = .popover

       guard let popOverPresenter = pickStoredStackViewController.popoverPresentationController
       else { return }
       popOverPresenter.canOverlapSourceViewRect = true // or barButtonItem
       popOverPresenter.delegate = self

       popOverPresenter.barButtonItem = sender

       let sheet = popOverPresenter.adaptiveSheetPresentationController //adaptiveSheetPresentationController
       sheet.detents = [.medium(), .large()]
//        sheet.prefersScrollingExpandsWhenScrolledToEdge = false
       sheet.prefersEdgeAttachedInCompactHeight = true
       sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true

       present(pickStoredStackViewController, animated: true )

        }


    func presentSaveDialog(saveDialogController: PGLSaveDialogController){
        // assumes shouldSaveAs mode is correctly set in the controller

        saveDialogController.modalPresentationStyle = .popover
        saveDialogController.preferredContentSize = CGSize(width: 350, height: 200.0)
        
        guard let popOverPresenter = saveDialogController.popoverPresentationController
        else { return }
        popOverPresenter.canOverlapSourceViewRect = false // or barButtonItem
        popOverPresenter.delegate = self
        // popOverPresenter.popoverLayoutMargins // default is 10 points inset from device edges
//        popOverPresenter.sourceView = view
        let sheet = popOverPresenter.adaptiveSheetPresentationController //adaptiveSheetPresentationController
        sheet.detents = [.medium(), .large()]
//        sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        sheet.prefersEdgeAttachedInCompactHeight = true
        sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true

        popOverPresenter.barButtonItem = moreBtn
         present(saveDialogController, animated: true )
    }

    @IBAction func helpBtnAction(_ sender: UIBarButtonItem) {
        guard let helpController = storyboard?.instantiateViewController(withIdentifier: "PGLHelpPageController") as? PGLHelpPageController
        else {
            return
        }
        helpController.modalPresentationStyle = .popover
        // specify anchor point?
        guard let popOverPresenter = helpController.popoverPresentationController
        else { return }
        popOverPresenter.canOverlapSourceViewRect = true // or barButtonItem
        // popOverPresenter.popoverLayoutMargins // default is 10 points inset from device edges
//      popOverPresenter.sourceView = view
//        popOverPresenter.sourceRect = view.frame.insetBy(dx: 300.0, dy: 20.0)
        popOverPresenter.barButtonItem = sender //helpBtn

        let sheet = popOverPresenter.adaptiveSheetPresentationController //adaptiveSheetPresentationController
        sheet.detents = [.medium(), .large()]
//        sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        sheet.prefersEdgeAttachedInCompactHeight = true
        sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true

        present(helpController, animated: true )
    }


    var tintViews = [UIView]()

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

    func saveStack( newSaveAs: Bool) {
        if isLimitedPhotoLibAccess() {
            self.appStack.firstStack()?.exportAlbumName = nil
        }
        if newSaveAs {self.appStack.setToNewStack()
            // set the coredata vars to nil
            }
        splitViewController?.preferredDisplayMode = .secondaryOnly
        // go to full screen to render the save image
        // preferredStatusBarStyle left to user action


        self.appStack.saveStack(metalRender: self.metalController!.metalRender)
    }


    @IBAction func newStackActionBtn(_ sender: UIBarButtonItem) {
        // confirm user action if current stack is not saved
        // from the trash action button -
        // new means the old one is discarded

        confirmTrashDisplayStack(sender)

        }

    

    func displayPrivacyPolicy(_ sender: UIBarButtonItem) {
        let infoPrivacyController = storyboard!.instantiateViewController(
            withIdentifier: "infoPrivacy") as! PGLInfoPrivacyController

        if ( parent is PGLStackImageContainerController ) {
            infoPrivacyController.modalPresentationStyle = .popover
            // specify anchor point?
            guard let popOverPresenter = infoPrivacyController.popoverPresentationController
            else { return }
            popOverPresenter.canOverlapSourceViewRect = true // or barButtonItem
            // popOverPresenter.popoverLayoutMargins // default is 10 points inset from device edges
    //        popOverPresenter.sourceView = view

            let sheet = popOverPresenter.adaptiveSheetPresentationController //adaptiveSheetPresentationController
            sheet.detents = [.medium(), .large()]
    //        sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            sheet.prefersEdgeAttachedInCompactHeight = true
            sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true

            popOverPresenter.barButtonItem = moreBtn
            present(infoPrivacyController, animated: true )
        } else {
            // on the iPad.. just present full size
            let navController = UINavigationController(rootViewController: infoPrivacyController)
                                 present(navController, animated: true)
        }
    }

    // MARK: trash button action
    fileprivate func hideViewReleaseStack() {
            // Respond to user selection of the action
        DoNotDraw = true
        self.metalController?.view.isHidden = true
            // makes the image go blank after the trash button loads a new stack.
            // set visible again when new images are selected in
            //        notification PGLCurrentFilterChange

        self.appStack.releaseTopStack()
        let newStack = PGLFilterStack()

        self.appStack.resetOutputAppStack(newStack)
    }

    func confirmTrashDisplayStack(_ sender: UIBarButtonItem)  {

        let discardAction = UIAlertAction(title: "Discard",
                  style: .destructive) { (action) in
            self.hideViewReleaseStack()
            self.updateNavigationBar()
            // next back out of the parm controller since the filter is removed

            if ( self.parmController?.isViewLoaded ?? false ) {  // or .isBeingPresented?
                Logger(subsystem: LogSubsystem, category: LogNavigation).info( "\("#popViewController " + String(describing: self))")
                self.parmController?.navigationController?.popViewController(animated: true)
                // parmController in the master section of the splitView has a different navigation stack
                // from the PGLImageController
            }

        }

        let cancelAction = UIAlertAction(title: "Cancel",
                  style: .cancel) { (action) in
                   // do nothing

        }

        let alert = UIAlertController(title: "Trash"   ,
                    message: "Completely remove and start over? This cannot be undone",
                    preferredStyle: .alert)
        alert.addAction(discardAction)
    
        alert.addAction(cancelAction)

        // On iPad, action sheets must be presented from a popover.
        alert.popoverPresentationController?.barButtonItem = sender
        self.present(alert, animated: true) {
           // The alert was presented
        }

    }

    func displayUser(alert: UIAlertController) {
        // presents an alert on top of the open viewController
        // informs user to try again with 'Save As'

            present(alert, animated: true )



    }

// MARK:  Navigation
    func showStackControllerAction() {
        // other part of split should navigate back to the stack controller
        // after the Random button is clicked
        let goToStack = Notification(name: PGLLoadedDataStack)
        NotificationCenter.default.post(goToStack)

    }
    

    fileprivate func postCurrentFilterChange() {
        let updateFilterNotification = Notification(name:PGLCurrentFilterChange)
        NotificationCenter.default.post(name: updateFilterNotification.name, object: nil, userInfo: ["sender" : self as AnyObject])
    }







    func doImageCollectionOpen(assetInfo: PGLAlbumSource) {

        if appStack.isImageControllerOpen {

        performSegue(withIdentifier: "showCollection", sender: assetInfo)
                // does not use should performSegue..
                  // alternate path to the assetGrid
        } else {
            // notify that the
        }



    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let segueId = segue.identifier
        Logger(subsystem: LogSubsystem, category: LogNavigation).info("\( String(describing: self) + "-" + #function) + \(String(describing: segueId))")
            if segueId == "showCollection" {
                if let info = sender as? PGLAlbumSource {
                    if let pictureGrid = segue.destination as? PGLImagesSelectContainer {
                        if let aUserAssetSelection = info.filterParm?.getUserAssetSelection() {
                            // there is an existing userSelection in progress.. use it
                            Logger(subsystem: LogSubsystem, category: LogCategory).notice("PGLImageController prepare destination but OPEN..")
                            // use navController and cancel the segue???

                            pictureGrid.userAssetSelection = aUserAssetSelection
                        }
                        else {
                            let userSelectionInfo = PGLUserAssetSelection(assetSources: info)
                            // create a new userSelection
                            pictureGrid.userAssetSelection = userSelectionInfo
                            pictureGrid.title = info.sectionSource?.localizedTitle

                            Logger(subsystem: LogSubsystem, category: LogCategory).debug("PGLImageController #prepare for segue showCollection")
                        }
                            }
                    }
                }
    }

    func updateNavigationBar() {
        self.navigationItem.title = self.appStack.firstStack()?.stackName
        setNeedsStatusBarAppearanceUpdate()
    }


    // MARK: viewController lifecycle
    
//    override func viewLayoutMarginsDidChange() {
//        NSLog("PGLImageController # viewLayoutMarginsDidChange")
//        if  (splitViewController?.isCollapsed)! {
//            splitViewController?.preferredDisplayMode = UISplitViewController.DisplayMode.oneBesideSecondary
//        }

//        hideParmControls()
//    }
    override func viewWillLayoutSubviews() {

//     navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
        // turns on the full screen toggle button on the left nav bar
        // Do not change the configuration of the returned button.
        // The split view controller updates the button’s configuration and appearance automatically based on the current display mode
        // and the information provided by the delegate object.
        // mode is controlled by targetDisplayModeForAction(in svc: UISplitViewController) -> UISplitViewController.DisplayMode

       navigationItem.leftItemsSupplementBackButton = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setGestureRecogniziers()
//        toggleViewControls(hide: false ) // restore removed position & text controls
    }

    func setMoreBtnMenu() {
            //      if traitCollection.userInterfaceIdiom == .phone {
        let libraryMenu = UIAction.init(title: "Library..", image: UIImage(systemName: "folder"), identifier: PGLImageController.LibraryMenuIdentifier, discoverabilityTitle: "Library", attributes: [], state: UIMenuElement.State.off) {
            action in
            self.openStackActionBtn(self.moreBtn)
        }

        if let mySplitView =  splitViewController as? PGLSplitViewController {
                //                if traitCollection.userInterfaceIdiom == .pad {
                //                    libraryMenu.attributes = [.disabled] // always disabled on iPad
                //                } else {
            if !mySplitView.stackProviderHasRows() {
                libraryMenu.attributes = [.disabled]
                    //                    }
            }

        }


        let contextMenu = UIMenu(title: "",
                                 children: [ libraryMenu ,
         UIAction(title: "Demo..", image:UIImage(systemName: "pencil.circle")) {
         action in
         self.loadDemoStack(self.moreBtn)
        },
          UIAction(title: "Save..", image:UIImage(systemName: "pencil")) {
            action in
            self.saveStackActionBtn(self.moreBtn)
        },
          UIAction(title: "Save As..", image:UIImage(systemName: "pencil.circle")) {
            action in
            self.saveStackAsActionBtn(self.moreBtn)
        },
          UIAction(title: "Privacy.. ", image:UIImage(systemName: "info.circle")) {
            action in
            self.displayPrivacyPolicy(self.moreBtn)
        }
            ] )
        moreBtn.menu = contextMenu
    }

    func loadDemoStack(_ sender: UIBarButtonItem)  {
        appStack.createDemoStack(view: view)
    }


    fileprivate func registerImageControllerNotifications() {
        let myCenter =  NotificationCenter.default
        let queue = OperationQueue.main
        Logger(subsystem: LogSubsystem, category: LogNavigation).info("\( String(describing: self) + "-" + #function)")
        
        var aNotification = myCenter.addObserver(forName: PGLStackChange, object: nil , queue: queue) {[weak self]
            myUpdate in
//            guard let self = self else { return }
                // a released object sometimes receives the notification
                                                  // the guard is based upon the apple sample app 'Conference-Diffable'
//            if  (!self.isBeingPresented)  {
                // && (self.splitViewController?.isCollapsed ?? false)
//                return
//            }
            Logger(subsystem: LogSubsystem, category: LogNavigation).info("\( String(describing: self) + " notificationBlock PGLStackChange") ")


            self?.updateNavigationBar()
            if !(self?.keepParmSlidersVisible ?? false) {
                self?.hideParmControls()
            }



        }
        notifications[PGLStackChange] = aNotification

        aNotification =  myCenter.addObserver(forName: PGLCurrentFilterChange , object: nil , queue: queue) { [weak self]
            myUpdate in
//            guard let self = self else { return }
                // a released object sometimes receives the notification
                                                  // the guard is based upon the apple sample app 'Conference-Diffable'
//            if  (!self.isBeingPresented) && (self.splitViewController?.isCollapsed ?? false) {
//                return
//            }
            Logger(subsystem: LogSubsystem, category: LogNavigation).info("\( String(describing: self) + "notificationBlock PGLCurrentFilterChange") " )
                //            self.filterValuesHaveChanged = true

            if !(self?.keepParmSlidersVisible ?? false) {
                self?.hideParmControls()
            }
            if DoNotDraw {
                DoNotDraw = false
            }
            // needed to refresh the view after the trash creates a new stack.
        }
        notifications[PGLCurrentFilterChange] = aNotification

        aNotification = myCenter.addObserver(forName: PGLAttributeAnimationChange , object: nil , queue: queue) { [weak self ]
            myUpdate in
            guard self != nil else { return } // a released object sometimes receives the notification
                                                  // the guard is based upon the apple sample app 'Conference-Diffable'
//            Logger(subsystem: LogSubsystem, category: LogNavigation).info("PGLImageController  notificationBlock PGLAttributeAnimationChange")
                //            self.filterValuesHaveChanged = true

        }
        notifications[PGLAttributeAnimationChange] = aNotification

        aNotification = myCenter.addObserver(forName: PGLUserAlertNotice, object: nil , queue: queue) {[weak self]
            myUpdate in
//            guard let self = self else { return } // a released object sometimes receives the notification
//            if  (!self.isBeingPresented) && (self.splitViewController?.isCollapsed ?? false) {
//                return
//            }
            Logger(subsystem: LogSubsystem, category: LogNavigation).info("PGLImageController  notificationBlock PGLUserAlertNotice")
            if let userDataDict = myUpdate.userInfo {
                if let anAlertController = userDataDict["alertController"] as? UIAlertController {
                    self?.displayUser(alert: anAlertController)
                }
            }
        }
        notifications[PGLUserAlertNotice] = aNotification

        aNotification = myCenter.addObserver(forName: PGLStackSaveNotification , object: nil , queue: queue) { [weak self ]
            myUpdate in
//            guard let self = self else { return}
//            if  (!self.isBeingPresented) && (self.splitViewController?.isCollapsed ?? false) {
//                return
//            }
            Logger(subsystem: LogSubsystem, category: LogNavigation).info("\( String(describing: self) + " notificationBlock PGLStackSaveNotification") ")
            if let userDataDict = myUpdate.userInfo {
                if let userValues = userDataDict["dialogData"] as? PGLStackSaveData {
                        // put the new names into the stack
                    guard let targetStack = self?.appStack.firstStack()
                    else { return }
                    targetStack.stackName = userValues.stackName!
                    targetStack.stackType = userValues.stackType!
                    targetStack.exportAlbumName = userValues.albumName
                    targetStack.shouldExportToPhotos = userValues.storeToPhoto

                    // in iPhone there are multiple imageControllers getting the same
                    // notification. If the stack already has the same save data object
                    // then don't reprocess again. Uses object identity to test

                    if userValues.saveSessionUUID != targetStack.saveSessionUUID {
                        self?.saveStack(newSaveAs: userValues.shouldSaveAs)
                            // save stack will create a utility queue to execute.. but should not
                            // kill the utility queue process when this notification callback process ends.
                        
                        // store this saveData object to guard against other redunant notifications
                        targetStack.saveSessionUUID = userValues.saveSessionUUID
                    }

                    self?.updateLibraryMenu()
                    self?.updateNavigationBar()


                }
            }
        }
        notifications[PGLStackSaveNotification] = aNotification

        aNotification = myCenter.addObserver(forName: PGLUpdateLibraryMenu , object: nil , queue: queue) { [weak self ]
            myUpdate in
//            guard let self = self else { return}

            Logger(subsystem: LogSubsystem, category: LogNavigation).info("PGLImageController  notificationBlock PGLUpdateLibraryMenu")
            // if the popup openStackController called a delete

            self?.updateLibraryMenu()


        }
        notifications[PGLUpdateLibraryMenu] = aNotification

        aNotification = myCenter.addObserver(forName: PGLHideImageViewReleaseStack , object: nil , queue: queue) { [weak self ]
            myUpdate in
//            guard let self = self else { return}

            Logger(subsystem: LogSubsystem, category: LogNavigation).info("PGLImageController  notificationBlock PGLHideImageViewReleaseStack")
            // if the popup openStackController called a delete
            self?.hideViewReleaseStack()


        }
        notifications[PGLHideImageViewReleaseStack] = aNotification


        aNotification = myCenter.addObserver(forName: PGLImageCollectionOpen, object: nil , queue: OperationQueue.main) { [weak self]
            myUpdate in
//            guard let self = self else { return }
                // a released object sometimes receives the notification
                                                  // the guard is based upon the apple sample app 'Conference-Diffable'
//            if  (!self.isBeingPresented) && (self.splitViewController?.isCollapsed ?? false) {
//                return
//            }
            Logger(subsystem: LogSubsystem, category: LogNavigation).info("\( String(describing: self) + " notificationBlock PGLImageCollectionOpen")" )
            if ((self?.view.isHidden) != nil)
                {self?.view.isHidden = false }
                // needed to refresh the view after the trash creates a new stack.
            if let assetInfo = ( myUpdate.userInfo?["assetInfo"]) as? PGLAlbumSource {
                self?.doImageCollectionOpen(assetInfo: assetInfo) }
        }
        notifications[PGLImageCollectionOpen] = aNotification

        aNotification = myCenter.addObserver(forName: PGLHideParmUIControls, object: nil , queue: OperationQueue.main) { [weak self]
            myUpdate in
//            guard let self = self else { return }
//            if  (!self.isBeingPresented) && (self.splitViewController?.isCollapsed ?? false) {
//                return
//            }
            Logger(subsystem: LogSubsystem, category: LogNavigation).info("\( String(describing: self) + " notificationBlock PGLHideParmUIControls") " )
            self?.hideParmControls()
        }
        notifications[PGLHideParmUIControls] = aNotification
    }

    override func viewDidLoad() {
        // conversion to Metal based on Core Image Programming Guide
        // https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/CoreImaging/ci_tasks/ci_tasks.html#//apple_ref/doc/uid/TP30001185-CH3-SW5
        // see Listing 1-7  Setting up a Metal view for Core Image rendering
        super.viewDidLoad()
        Logger(subsystem: LogSubsystem, category: LogNavigation).info("\( String(describing: self) + "-" + #function)")
//      view has been typed as MTKView in the PGLView subclass
//        and the view assigned in the setter of effectView var

        filterStack = { self.appStack.outputFilterStack() }

        if let myMetalControllerView = storyboard!.instantiateViewController(withIdentifier: "MetalController") as? PGLMetalController {
            // does the metalView extend under the navigation bar?? change constraints???
//            myMetalControllerView.view.frame = self.view.bounds

            addChild(myMetalControllerView)
                // tried to use NSLayoutConstraint instead of setting the frame..
            if let theMetalView = myMetalControllerView.view {
               theMetalView.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview(theMetalView)
                view.bringSubviewToFront(theMetalView)
                metalController = myMetalControllerView  // hold the ref
                let iPhoneCompact =  splitViewController?.isCollapsed ?? false

                if iPhoneCompact {  // iPhone case
                    NSLayoutConstraint.activate([
                        theMetalView.topAnchor.constraint(equalTo: view.topAnchor),
                        theMetalView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                        theMetalView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                        theMetalView.centerYAnchor.constraint(equalTo: view.centerYAnchor),

                        theMetalView.widthAnchor.constraint(equalTo: view.heightAnchor , multiplier: 4/3),
                        // iphone width constraint
                    ]) }
                else {  // iPad case
                    NSLayoutConstraint.activate([
                        theMetalView.topAnchor.constraint(equalTo: view.topAnchor),
                        theMetalView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                        theMetalView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                        theMetalView.centerYAnchor.constraint(equalTo: view.centerYAnchor),

                        theMetalView.widthAnchor.constraint(equalTo: view.widthAnchor ),
                        // iPad width constraint
                    ])
                }
                myScaleFactor = theMetalView.contentScaleFactor
                myScaleTransform = CGAffineTransform(scaleX: myScaleFactor, y: myScaleFactor )
                myMetalControllerView.didMove(toParent: self)

            }

        }
        registerImageControllerNotifications()

        tintViews.append(contentsOf: [topTintView, bottomTintView, leftTintView, rightTintView])

        setMoreBtnMenu()


        if ShowHelpOnOpen {
            // if the key does not exist then bool answers false
            helpBtnAction(helpBtn)
            // PGLHelpPageController will set to false after showing help

        }
        if let mySplitView =  splitViewController as? PGLSplitViewController {
                //                if traitCollection.userInterfaceIdiom == .pad {
                //                    libraryMenu.attributes = [.disabled] // always disabled on iPad
                //                } else {
            if !mySplitView.stackProviderHasRows() {
                // empty stacks.. still newbie
                appStack.createDemoStack(view: view)
            }
        }
        updateNavigationBar()

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

         appStack.isImageControllerOpen = true
        Logger(subsystem: LogSubsystem, category: LogNavigation).info("\( String(describing: self) + "-" + #function)")

    }

    func viewDidDisappear(animated: Bool) {
        appStack.isImageControllerOpen = false // selection of new image or image list is started
        removeGestureRecogniziers()
        super.viewDidDisappear(animated)

        Logger(subsystem: LogSubsystem, category: LogNavigation).info("\( String(describing: self) + "-" + #function)")

        for (name , observer) in  notifications {
            Logger(subsystem: LogSubsystem, category: LogNavigation).info("Remove notification \( String(describing: name) )")
                       NotificationCenter.default.removeObserver(observer, name: name, object: nil)

                   }
        notifications = [:] // reset
    }



    func updateLibraryMenu() {
        // from open stack delete command or the saveActionBtns
        // enable/disable the More button library menu item
//        if traitCollection.userInterfaceIdiom == .pad
//            { return
//                // leave as default ie disabled on the iPad
//        }
        if let mySplitView =  splitViewController as? PGLSplitViewController {
            guard let theActions = moreBtn.menu?.children
            else { return }
            for aMenuAction in theActions {
                if let thisAction = aMenuAction as? UIAction {
                    if thisAction.identifier == PGLImageController.LibraryMenuIdentifier {
                        if mySplitView.stackProviderHasRows() {
                            thisAction.attributes = []  // ie not disabled
                        } else {
                            thisAction.attributes = [.disabled]
                        }
                    break
                    }
                }
            }

        }
    }



    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }






    // MARK: parmUI
    func addParmControls() {
        if appStack.parmControls.count > 0 {
//            NSLog("PGLImageController should remove old parm buttons")
            removeParmControls()
        }
        for attribute in appStack.parms {
            // should use the attribute methods isPointUI() or isRectUI()..
            // testing only on attributeType  misses CIAttributeTypeOffset & CIVector combo in
            // CINinePartStretched attribute inputGrowAmount
            /*CINinePartStretched category CICategoryDistortionEffect NOT UI Parm attributeName= Optional("inputGrowAmount") attributeDisplayName= Optional("Grow Amount") attributeType=Optional("CIAttributeTypeOffset") attributeClass= Optional("CIVector")
             */
            // also var parms =  [String : PGLFilterAttribute]() // string index by attributeName
            // attribute is actuallly the value of the tuple in parms
            let parmAttribute = attribute.value
                if parmAttribute.isPointUI() {
                    addPositionControl(attribute: parmAttribute)
                }
                if parmAttribute.isRectUI() {
                    if let rectAttribute = parmAttribute as? PGLAttributeRectangle {
                            addRectControl(attribute: rectAttribute)
                            setRectTintAndCornerViews(attribute: rectAttribute)

                    //rectController!.view.isHidden = false   // constraints still work?
                    }
                }
            if parmAttribute.isTextInputUI() {
                addTextInputControl(attribute: parmAttribute)
            }
        }
    }

    func hideParmControls() {
        // restore from delete in R83.07
        // was it a testing change that was committed??

        //  R83.07 removed blank toolbar after filter pick on the iPhone. Storyboard changes: Main Filter Controller setting hidesBottomBarWhenPushed="YES". Same on ParmSettingsViewController, Parm Image Controller, Filter Image Controller, Stack Image Container Controller. Logging changes to track navigation
        Logger(subsystem: LogSubsystem, category: LogCategory).debug("\( String(describing: self) + "-" + #function)")
        hideSliders()
        panner?.isEnabled = false
        toggleViewControls(hide: true, uiTypeToShow: nil )
            // toggle all view controls to hide
        parmSlider?.isHidden = true

    }



    func showRectInput(aRectInputFilter: PGLRectangleFilter) {
        guard let thisRectController = rectController
        else { return }

        thisRectController.croppingFilter = aRectInputFilter
//        thisRectController.thisCropAttribute = aRectInputFilter.cropAttribute
        showCropTintViews(setIsHidden: false)
        
    }

    func toggleViewControls(hide: Bool, uiTypeToShow: AttrUIType?) {
        // should use the attribute methods isPointUI() or isRectUI()..
        // for hide = true all view controls should hide
        // if hide = false, then apply to parms of the same uiType
        // textInputUI should stay hidden if showing the pointUI
        // and likewise.
        //
        for nameAttribute in appStack.parms {
            let parmAttribute = nameAttribute.value
            let parmView = appStack.parmControls[nameAttribute.key]
            if hide {
                if parmAttribute.isPointUI() || parmAttribute.isTextInputUI() {
                    parmView?.isHidden = hide
                }
                if parmAttribute.isRectUI() {
                    if parmAttribute is PGLAttributeRectangle {
                        hideRectControl()
                    }
                }
            } else
            { // hide is false
                if (uiTypeToShow == nil) ||
                    (uiTypeToShow == parmAttribute.attributeUIType()) {
                        if parmAttribute.isRectUI() {
                            hideRectControl()
                        } else
                        {  parmView?.isHidden = hide
                        }
                }
            }

//        Logger(subsystem: LogSubsystem, category: LogCategory).debug("\( String(describing: self) + "-" + #function)")

        } // end for appStack.parms
    }

    func removeParmControls() {
        // should use the attribute methods isPointUI() or isRectUI()..
        for nameAttribute in appStack.parms {
            let parmAttribute = nameAttribute.value

            if parmAttribute.isPointUI() || parmAttribute.isTextInputUI() {

                let parmView = appStack.parmControls[nameAttribute.key]
                if parmAttribute.isTextInputUI() {
                    if let textInputField = parmView as? UITextField {
//                        NSLog("ImageController removeParmControls on textField -- end editing?")
//                    textInputField.endEditing(true)
                    // end editing should cause resignFirstResponder and keyboard disappears
                   textInputField.resignFirstResponder()
                    }
                }
                parmView?.removeFromSuperview()
                appStack.parmControls.removeValue(forKey: nameAttribute.key)
                }
//                    NSLog("PGLImageController #removeParmControls removed parm \(String(describing: nameAttribute.value.attributeName))" )

                if parmAttribute.isRectUI() {
                    if parmAttribute is PGLAttributeRectangle {
                            hideRectControl()
                        }

//                    NSLog("PGLImageController #removeParmControls is skipping parm \(String(describing: nameAttribute.value.attributeName))" )
                }
//                if parmAttribute.isTextInputUI() {
//                    let parmView = parmTextControls[nameAttribute.key]
//                    parmView?.removeFromSuperview()
//                    parmTextControls.removeValue(forKey: nameAttribute.key)
//                }

        }
        Logger(subsystem: LogSubsystem, category: LogCategory).debug("PGLImageController removeParmControls completed")

    }

    func addPositionControl(attribute: PGLFilterAttribute) {
        // may remove this method if the type conversion is not needed to get the
        // correct super or subclass implementation of #controlImageView()
        // combine with addRectControl

        if let positionVector = attribute.getVectorValue() {
            // fails if no vector
            let newSize = CGSize(width: 60.0, height: 60.0)
            var yPoint = positionVector.y

            // adjustment for point to effectView transforms
            
            let inViewHeight = view.bounds.height
            yPoint = inViewHeight - yPoint  // flip around the midpoint of the view


//              NSLog("PGLImageController #addPositionContorl positionVector = \(positionVector)")
            var mappedOrigin = attribute.mapVector2Point(vector: positionVector, viewHeight: inViewHeight, scale: myScaleFactor)

            // move mappedOrigin for size of the image
            // mappedOrigin point is ULO upper Left origin
            mappedOrigin.x = mappedOrigin.x + newSize.width/2 // shift to right
            mappedOrigin.y = mappedOrigin.y - newSize.height/2 // shift up in ULO

            let controlFrame = CGRect(origin: mappedOrigin, size: newSize)
            // newOrigin should be the center of the controlFrame

            let newView = UIImageView(image: crossPoint)
//            newView.animationImages?.append(reverseCrossPanimationImagesoint!)
//            newView.animationDuration = 1.0

            newView.frame =  controlFrame
            newView.center = mappedOrigin

            // initial disabled look
            // changed in #togglePosition(theControlView:
            // to enabled look
            newView.isOpaque = false
            newView.alpha = 0.5
            newView.tintColor = .systemBackground
            newView.isUserInteractionEnabled = true


            view.addSubview(newView)
            appStack.parmControls[attribute.attributeName!] = newView
            newView.isHidden = true
        }
        else {
            Logger(subsystem: LogSubsystem, category: LogCategory).error("PGLImageController #addPositionControl fails on no vector value ")}
    }

    func addTextInputControl(attribute: PGLFilterAttribute) {
        // similar to addPositionControl adds text input box for
            // CIAttributedTextImageGenerator inputText,
            // CIAztecCodeGenerator inputMessage
            // CICode128BarcodeGenerator  inputMessage
            // CIPDF417BarcodeGenerator  inputMessage
            // CIQRCodeGenerator  inputMessage
            // CITextImageGenerator inputText inputFontName
        //
        let fieldWidth = 200.0
        let fieldHeight = 30.0

        var centerPoint: CGPoint
        let textValue = attribute.getValue() as? String // need to put implementations in the above classes
        // put in the center of the control
        let imageControllerView = view


        centerPoint = (imageControllerView!.center)

        centerPoint.y = (centerPoint.y / 2) - (fieldHeight/2.0)
        centerPoint.x = (centerPoint.x / 2) - (fieldWidth/2.0)
        let boxSize = CGSize(width: fieldWidth, height: fieldHeight)
        let boxFrame = CGRect(origin: centerPoint, size: boxSize)

        let inputView = UITextField(frame: boxFrame)
        inputView.borderStyle = UITextField.BorderStyle.bezel
        inputView.placeholder = textValue
        inputView.backgroundColor = UIColor.systemBackground
//        inputView.isOpaque = true
        if traitCollection.userInterfaceIdiom == .phone {
            // on the iPHone layout
            inputView.delegate = self
        } else {
            inputView.delegate = parmController }
//        NSLog("addTextInputControl textDelegate = \(String(describing: inputView.delegate))")

        imageControllerView!.addSubview(inputView)
        appStack.parmControls[attribute.attributeName!] = inputView
            // on iPHone need to move up to avoid getting hidden by the keyboad
        let margins = view.layoutMarginsGuide
         NSLayoutConstraint.activate([
//            inputView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
//            inputView.topAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: margins.topAnchor, multiplier: 0.0),
            inputView.topAnchor.constraint(lessThanOrEqualTo: margins.topAnchor, constant: 60) ,
            inputView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.66, constant: 0)
                                    ])
        inputView.isHidden = true
//        NSLog("addTextInputControl attributeValue = \(textValue)")

        addTextChangeNotification(textAttributeName: attribute.attributeName!)
    }

    func addBooleanInputSwitch(attribute: PGLFilterAttribute){
        // similar to addPositionControl adds boolean slider input input Control for
        //        CIPDF417BarcodeGenerator  inputCompactStyle, inputAlwaysSpecifyCompaction
        //      CIAztecCodeGenerator inputCompactStyle,

        //
//        let attributeValue = attribute.getValue() as? Bool // need to put implementations in the above classes
//        // put in the center of the control
//        let centerPoint = (view.center)
//        let boxSize = CGSize(width: 80, height: 40)
//        let boxFrame = CGRect(origin: centerPoint, size: boxSize)
//
//        let inputView = UISwitch(frame: boxFrame)
        // frame A rectangle defining the frame of the UISwitch object. The size components of this rectangle are ignored.
//        inputView.addTarget(attribute, action: <#T##Selector#>, for: UIControl.Event.valueChanged)
        //#selector(PGLSelectParmController.panAction(_:))
//        view.addSubview(inputView)
//        parmControls[attribute.attributeName!] = inputView
//
//        inputView.isHidden = true
//        NSLog("PGLImageController #addBooleanInputSwitch ")

    }

    // MARK: rectangle
    var rectController: PGLRectangleController?

    @IBOutlet weak var topTintView: UIView!

    @IBOutlet weak var bottomTintView: UIView!
    @IBOutlet weak var leftTintView: UIView!

    @IBOutlet weak var rightTintView: UIView!


    func cropAction(rectAttribute: PGLAttributeRectangle) {

        // assumes RectController is setup
            let metalView = metalController!.view
        if let newFrame = rectController?.panEnded(startPoint: self.startPoint, newPoint: self.endPoint, inView:(metalView)!)
        {
            // panEnded handles both modes of resize or move of the pan action
            // handle the transform coordinates here. Tell the attribute to change the filter to new crop
            // have it save the old vector
            // tell the rectController to unhighlight the filterRect box..

            let glkScaleFactorTransform = myScaleTransform
            var yOffset = metalView!.frame.height
            yOffset = yOffset * -1.0  // negate
            let glkTranslateTransform  = (CGAffineTransform.init(translationX: 0.0, y: yOffset ))
            let glkScaleTransform = glkTranslateTransform.concatenating(CGAffineTransform.init(scaleX: 1.0, y: -1.0))
            let finalTransform = glkScaleTransform.concatenating(glkScaleFactorTransform)
        // start with the scale of the glkView - scaleFactor = 2.. then do the flip

            let mappedFrame = newFrame.applying(finalTransform)
            rectAttribute.applyCropRect(mappedCropRect: mappedFrame)
        }

    }


    func addRectControl(attribute: PGLAttributeRectangle) {
        // may remove this method if the type conversion is not needed to get the
        // correct super or subclass implementation of #controlImageView()
        // combine with addPositionControl


            // display the rect with corners for crop move and resize
        if rectController == nil {
            rectController =  storyboard!.instantiateViewController(withIdentifier: "RectangleController") as? PGLRectangleController
        }

    }
    func setRectTintAndCornerViews(attribute: PGLAttributeRectangle) {
        if rectController != nil
            {  let newInsetRectFrame = insetRect(fromRect: self.view.bounds)

            rectController!.view.frame = newInsetRectFrame
            rectController!.scaleTransform = myScaleTransform
                // .concatenating(glkScaleTransform) // for mapping the rect vector to the image coordinates
                // combines the scaleFactor of 2.0 with the ULO flip for applying the crop to the glkImage

            Logger(subsystem: LogSubsystem, category: LogCategory).debug("PGLImageController #setRectTintAndCornerViews rectController.scaleTransform = \(String(describing: self.rectController!.scaleTransform))")

            Logger(subsystem: LogSubsystem, category: LogCategory).debug("PGLImageController #setRectTintAndCornerViews rectController.view.frame inset from bounds = \(self.view)")
//            NSLog("PGLImageController #setRectTintAndCornerViews rectController.view.frame now = \(newInsetRectFrame)")
            let rectCropView = rectController!.view!
            view.addSubview(rectCropView)
            appStack.parmControls[attribute.attributeName!] = rectCropView
                //parmControls = [String : UIView]() - string index by attributeName
            rectCropView.isHidden = true

            // there are constraint errors reported from here..
             NSLayoutConstraint.activate([
                topTintView.bottomAnchor.constraint(equalTo: rectCropView.topAnchor),
                bottomTintView.topAnchor.constraint(equalTo: rectCropView.bottomAnchor),
                leftTintView.rightAnchor.constraint(equalTo: rectCropView.leftAnchor),
                rightTintView.leftAnchor.constraint(equalTo: rectCropView.rightAnchor)
                ] )
            for aTintView in tintViews {
                view.bringSubviewToFront(aTintView)
                // they are set to hidden in IB
            }

            // next is not needed??
            for aCorner in rectController!.controlViewCorners {
                if let thisCorner = aCorner {
                    rectCropView.bringSubviewToFront(thisCorner)
//                    NSLog("PGLImageController #addRectControls to front \(thisCorner)")

                }
                view.bringSubviewToFront(rectCropView)
            }
        }

    }
    func showCropTintViews(setIsHidden: Bool) {
        for aTintView in tintViews {
            aTintView.isHidden = setIsHidden
        }
        if rectController != nil {
//            NSLog("PGLImageController #showCropTintViews isHidden changing to \(setIsHidden)")
            rectController!.view.isHidden = setIsHidden
            rectController!.setCorners(isHidden: setIsHidden)

        }
        else {
            Logger(subsystem: LogSubsystem, category: LogCategory).error ("PGLImageController #showCropTintViews rectController = nil - corners NOT SET for isHidden = \(setIsHidden)")
        }
    }

    func hideRectControl() {
        showCropTintViews(setIsHidden: true)
        if rectController != nil {
            rectController!.view.isHidden = true
        }
    }
    func insetRect(fromRect: CGRect) -> CGRect {
        let inset: CGFloat = 100 // 100.0
        //        return  CGRect(origin: CGPoint.zero, size: fromRect.size).insetBy(dx: inset, dy: inset)
        return fromRect.insetBy(dx: inset, dy: inset)
    }

// MARK: Sliders
    func showSliderControl(attribute: PGLFilterAttribute)  {
        hideSliders() // start with all hidden

        switch attribute {
            case let aColorAttribute as PGLFilterAttributeColor:

                taggedSliders[SliderColor.Alpha.rawValue]?.setValue(Float(aColorAttribute.alpha), animated: false )
                taggedSliders[SliderColor.Blue.rawValue]?.setValue(Float(aColorAttribute.blue ), animated: false )
                taggedSliders[SliderColor.Green.rawValue]?.setValue(Float(aColorAttribute.green), animated: false )
                taggedSliders[SliderColor.Red.rawValue]?.setValue(Float(aColorAttribute.red), animated: false )

                for aSlider in sliders {
                    aSlider.isHidden = false
                    view.bringSubviewToFront(aSlider)
            }

            case _ as PGLFilterAttributeAngle:
                if let numberValue = attribute.getNumberValue() as? Float {
                    parmSlider?.maximumValue = attribute.sliderMaxValue! // init to 2pi Radians
                    parmSlider?.minimumValue = attribute.sliderMinValue!  // init to 0.0
                    parmSlider?.setValue( numberValue, animated: false )
                }
                parmSlider.isHidden = false
                 view.bringSubviewToFront(parmSlider)
//            case let rectAttribute as PGLFilterAttributeRectangle:
//                NSLog("Should not hit this case where addSlider control called for a rectangle attribute")
            case _ as PGLFilterAttributeAffine:
                parmSlider?.maximumValue = 2 *  Float.pi  // this is the rotation part of the Affine
                parmSlider?.minimumValue = 0.0
                parmSlider?.isHidden = false
                view.bringSubviewToFront(parmSlider)
            default: if let numberValue = attribute.getNumberValue()?.floatValue {
                    parmSlider?.maximumValue = attribute.sliderMaxValue ?? 100.0
                    parmSlider?.minimumValue = attribute.sliderMinValue ?? 0.0
                    parmSlider?.setValue( numberValue, animated: false )
                    }
                    else { // sort of assuming angle.. need to explore this else statement further
                        parmSlider?.maximumValue = 2 *  Float.pi  // assuming this is for angle radians - see Straighten Filter
                        parmSlider?.minimumValue = 0.0
                        // defaults value to 0.0

                    }

                parmSlider?.isHidden = false
                guard parmSlider != nil
                    else {return}
                view.bringSubviewToFront(parmSlider)
//            NSLog("PGLImageController addSliderControl \(attribute.description)")
//            NSLog("slider min = \(parmSlider.minimumValue) max = \(parmSlider.maximumValue) value = \(parmSlider.value)")

        }



    }

    func hideSliders() {
        if let mySliderControls = sliders {
            for aSlideControl in mySliderControls {
                aSlideControl.isHidden = true
            }
        }
    }

    @objc func buttonWasPressed(_ sender: UIButton , forEvent: UIEvent) {
        if let buttonIndex = appStack.parmControls.firstIndex(where: { $0.value.tag == sender.tag } )
       {
            let matchedAttributeName = appStack.parmControls[buttonIndex].key
            _ = appStack.parms[matchedAttributeName]
//        NSLog("PGLImageController #buttonWasPressed attribute = \(String(describing: matchedAttribute))")
        }
    }

}

extension PGLImageController: UIGestureRecognizerDelegate {

    // MARK: Sliders


    func colorSliderValueDidChange(_ sender: UISlider) {

        // from the imageController sliderValueDidChange
        //        NSLog("PGLSelectParmController #sliderValueDidChange to \(sender.value)")
        let senderIndex: Int = Int(sender.tag)
        if let colorAttribute = appStack.targetAttribute as? PGLFilterAttributeColor {
            if let aColor = SliderColor(rawValue: senderIndex) {
                let sliderValue = (CGFloat)(sender.value)
                colorAttribute.setColor(color: aColor , newValue: sliderValue  )
//                attributeValueChanged()
                view.setNeedsDisplay()
            }
        }
    }

    func sliderValueDidChange(_ sender: UISlider) {

        // slider in the imageController on the image view
        if let target = appStack.targetAttribute {
//          NSLog("PGLSelectParmController #sliderValueDidChange target = \(target) value = \(sender.value)")
            target.uiIndexTag = Int(sender.tag)
                // multiple controls for attribute distinguished by tag
                // color red,green,blue for single setColor usage

            target.set(sender.value)
        } 


//        attributeValueChanged()
        view.setNeedsDisplay()
    }

        // MARK: Gestures


        func setGestureRecogniziers() {
            if panner != nil {
                NSLog("PGLImageController  SKIP #setGestureRecogniziers, panner exists")
                return
                // it is already set
            }
            panner = UIPanGestureRecognizer(target: self, action: #selector(PGLImageController.panAction(_:)))
            if panner != nil {
                NSLog("PGLImageController #setGestureRecogniziers")
                view.addGestureRecognizer(panner!)
                panner!.isEnabled = false
            }

        }

        func removeGestureRecogniziers() {

            if panner != nil {
//                NSLog("PGLImageController #removeGestureRecogniziers")
                view.removeGestureRecognizer(panner!)
                panner?.removeTarget(self, action: #selector(PGLImageController.panAction(_:)) )
                panner = nil
            }

        }
    func panMoveChange( endingPoint: CGPoint, parm: PGLFilterAttribute) {

        // add move or resize mode logic
        // delta logic - the startPoint is just the previous change method endingPoint
        // also note that startPoint is an instance var. should be parm also, like the ending point??

        switch parm {
        case  _ as PGLAttributeRectangle:
             if rectController != nil {
                rectController!.movingChange(startPoint: startPoint, newPoint: endingPoint, inView: view)
                view.setNeedsLayout()

            }
        default:
            tappedControl?.center = endingPoint // this makes the screen update for point
//            parm.movingChange(startPoint: startPoint, newPoint: endingPoint, inView: (myimageController?.view)!)

             let viewHeight = view.bounds.height
            let flippedVertical = viewHeight - endingPoint.y
            parm.set(CIVector(x: endingPoint.x * myScaleFactor , y: flippedVertical * myScaleFactor))

        }
        // make the display show this
    }


    func panEnded( endingPoint: CGPoint, parm: PGLFilterAttribute) {


        // add move or resize mode logic
        // tap action should have set the rectController

//        parm.moveTo(startPoint: startPoint, newPoint: endingPoint, inView: (myimageController?.view)!)
            // PGLFilterAttributeRectangle should have empty implementation of moveTo
            // it moves on the OK action not the pan ended

         let viewHeight = view.bounds.height
//            let flippedVertical = viewHeight - endingPoint.y
            let newVector = parm.mapPoint2Vector(point: endingPoint, viewHeight: viewHeight, scale: myScaleFactor)
            parm.set(newVector)
            // or parm.set(oldVector)

//        attributeValueChanged()
//        startPoint = CGPoint.zero // reset
//        endPoint = CGPoint.zero
//        NSLog("PGLSelectParmController #panEnded startPoint,endPoint reset to CGPoint.zero")

    }

    @objc func panAction(_ sender: UIPanGestureRecognizer) {


        // should enable only when a point parm is selected.
        let gesturePoint = sender.location(in: view)
        // this changing as an ULO - move down has increased Y

//        NSLog("panAction changed gesturePoint = \(gesturePoint) " )

        // expected that one is ULO and the other is LLO point
        let tappedAttribute = appStack.targetAttribute

        switch sender.state {

        case .began: startPoint = gesturePoint
            endPoint = startPoint // should be the same at began
//         NSLog("panAction began gesturePoint = \(gesturePoint)")
//         NSLog("panAction began tappedControl?.frame.origin  = \(String(describing: tappedControl?.frame.origin))")
                if selectedParmControlView != nil {
                    tappedControl = selectedParmControlView
//                 NSLog("panAction began startPoint = \(startPoint)")
                    if (tappedAttribute as? PGLAttributeRectangle) != nil {
                        if let activeRectController = rectController {
                            let tapLocation = sender.location(in: selectedParmControlView)  // not the same as the location in the myimageController.view
                            if activeRectController.hitTestCorners(location: tapLocation, controlView: selectedParmControlView!) != nil {
//                                NSLog("PGLSelectParmController #panAction found hit corner = \(tappedCorner)")

                            }
                        }
                    }


                }

        case .ended:
                endPoint = gesturePoint
                if tappedAttribute != nil {panEnded(endingPoint:  endPoint, parm: tappedAttribute!) }
                tappedControl = nil

        case .changed:
                    startPoint = endPoint // of last changed message .. just process the delta
                    endPoint = gesturePoint
                    tappedControl?.center = gesturePoint
                    if tappedAttribute != nil {panMoveChange(endingPoint:  endPoint, parm: tappedAttribute!) }

//           NSLog("panAction changed NOW tappedControl?.frame.origin  = \(String(describing: tappedControl?.frame.origin))")
            case .cancelled, .failed:
                tappedControl = nil

            case .possible: break
            default: break

        }
    }



}

extension UIImage {
  class func image(from layer: CALayer) -> UIImage? {
    UIGraphicsBeginImageContextWithOptions(layer.bounds.size,
  layer.isOpaque, UIScreen.main.scale)

    defer { UIGraphicsEndImageContext() }

    // Don't proceed unless we have context
    guard let context = UIGraphicsGetCurrentContext() else {
      return nil
    }

    layer.render(in: context)
    /* UIGraphicsGetImageFromCurrentImageContext()
       You should call this function only when a bitmap-based graphics context is the current graphics context. If the current context is nil or was not created by a call to UIGraphicsBeginImageContext(_:), this function returns nil.
        */

    return UIGraphicsGetImageFromCurrentImageContext()
  }
}
