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
let  PGLOutputImageChange = NSNotification.Name(rawValue: "PGLOutputImageChange")
let  PGLUserAlertNotice = NSNotification.Name(rawValue: "PGLUserAlertNotice")

let ExportAlbumId = "ExportAlbumId"
let ExportAlbum = "ExportAlbum"

let showHelpPageAtStartupKey = "displayStartHelp"

class PGLImageController: UIViewController, UIDynamicAnimatorDelegate, UINavigationBarDelegate, UIAdaptivePresentationControllerDelegate, UIPopoverPresentationControllerDelegate {


    // controller in detail view - shows the image as filtered - knows the current filter

// MARK: Property vars


    var filterValuesHaveChanged = false

    var videoPreviewViewBounds = CGRect.init()
    var myScale: CGFloat = 1.0
    var myScaleFactor: CGFloat = 1.0
    var myScaleTransform: CGAffineTransform = CGAffineTransform.identity

    var filterStack: () -> PGLFilterStack?  = { PGLFilterStack() } // a function is assigned to this var that answers the filterStack
    var appStack: PGLAppStack!


    var parms =  [String : PGLFilterAttribute]() // string index by attributeName

    var parmControls = [String : UIView]() // string index by attributeName
        // holds point and textfield input controls
        // var parmTextControls = [String : UITextField]() // string index by attributeName
    var parmController: PGLSelectParmController?
    var metalController: PGLMetalController?

   let debugLogDrawing = false
    let crossPoint = UIImage(systemName: "plus.circle.fill")
//    let reverseCrossPoint = UIImage(systemName: "plus.circle")

    var notifications = [Any]() // an opaque type is returned from addObservor

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

    @IBOutlet var sliders: [UISlider]!



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

    }

    func showStackControllerAction() {
        // other part of split should navigate back to the stack controller
        // after the Random button is clicked
        let goToStack = Notification(name: PGLLoadedDataStack)
        NotificationCenter.default.post(goToStack)

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

    func presentSaveDialog(saveDialogController: PGLSaveDialogController){
        // assumes shouldSaveAs mode is correctly set in the controller

        saveDialogController.modalPresentationStyle = .popover
        saveDialogController.preferredContentSize = CGSize(width: 350, height: 300.0)
        
        guard let popOverPresenter = saveDialogController.popoverPresentationController
        else { return }
        popOverPresenter.canOverlapSourceViewRect = false // or barButtonItem
        popOverPresenter.delegate = self
        // popOverPresenter.popoverLayoutMargins // default is 10 points inset from device edges
//        popOverPresenter.sourceView = view
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
//        popOverPresenter.sourceView = view
        popOverPresenter.barButtonItem = helpBtn
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

        confirmReplaceFilterInput(sender)

        }

    

    func displayPrivacyPolicy(_ sender: UIBarButtonItem) {
        let infoPrivacyController = storyboard!.instantiateViewController(
            withIdentifier: "infoPrivacy") as! PGLInfoPrivacyController

        let navController = UINavigationController(rootViewController: infoPrivacyController)
                                 present(navController, animated: true)
    }

    // MARK: trash button action
    func confirmReplaceFilterInput(_ sender: UIBarButtonItem)  {

        let discardAction = UIAlertAction(title: "Discard",
                  style: .destructive) { (action) in
                    // Respond to user selection of the action
                    let newStack = PGLFilterStack()

                    self.appStack.resetToTopStack(newStack: newStack)

                    self.updateNavigationBar()
            // next back out of the parm controller since the filter is removed

            if ( self.parmController?.isViewLoaded ?? false ) {
                // or .isBeingPresented?
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


    fileprivate func postCurrentFilterChange() {
        let updateFilterNotification = Notification(name:PGLCurrentFilterChange)
        NotificationCenter.default.post(updateFilterNotification)
    }

    func postStackChange() {

        let stackNotification = Notification(name:PGLStackChange)
        NotificationCenter.default.post(stackNotification)
    }

//@objc func updateDisplay() {
//
//
//    }



    func doImageCollectionOpen(assetInfo: PGLAlbumSource) {

      if let theTop = navigationController?.topViewController {
//        NSLog("PGLImageController #doImageCollectionOpen on \(theTop) ")
        }
        if appStack.isImageControllerOpen {

        performSegue(withIdentifier: "showCollection", sender: assetInfo)
                // does not use should performSegue..
                  // alternate path to the assetGrid
        } else {
            // notify that the
        }



    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if segue.identifier == "showCollection" {
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
                            pictureGrid.title = info.sectionSource.localizedTitle

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
    }

    override func viewDidLoad() {
        // conversion to Metal based on Core Image Programming Guide
        // https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/CoreImaging/ci_tasks/ci_tasks.html#//apple_ref/doc/uid/TP30001185-CH3-SW5
        // see Listing 1-7  Setting up a Metal view for Core Image rendering
        super.viewDidLoad()
//      view has been typed as MTKView in the PGLView subclass
//        and the view assigned in the setter of effectView var


        guard let myAppDelegate =  UIApplication.shared.delegate as? AppDelegate
            else {
            Logger(subsystem: LogSubsystem, category: LogCategory).fault( "PGLImageController viewDidLoad fatalError(AppDelegate not loaded")
                return
        }

        appStack = myAppDelegate.appStack
        filterStack = { self.appStack.outputFilterStack() }

//        NSLog("PGLImageController #viewdidLoad")

        let myCenter =  NotificationCenter.default
        let queue = OperationQueue.main
        self.view.isHidden = true // use neutral screen not black of the CIImage.empty
        
        var aNotification = myCenter.addObserver(forName: PGLStackChange, object: nil , queue: queue) {[weak self]
            myUpdate in
            guard let self = self else { return } // a released object sometimes receives the notification
                          // the guard is based upon the apple sample app 'Conference-Diffable'
//            NSLog("PGLImageController  notificationBlock PGLStackChange")


            self.updateNavigationBar()
            if !self.keepParmSlidersVisible {
                self.hideParmControls()
            }

            self.view.isHidden = true
            // makes the image go blank after the trash button loads a new stack.
            // set visible again when new images are selected

        }
        notifications.append(aNotification)

        aNotification =  myCenter.addObserver(forName: PGLCurrentFilterChange , object: nil , queue: queue) { [weak self]
            myUpdate in
            guard let self = self else { return } // a released object sometimes receives the notification
                          // the guard is based upon the apple sample app 'Conference-Diffable'
            self.filterValuesHaveChanged = true
            if !self.keepParmSlidersVisible {
                self.hideParmControls()

            }
            if (self.view.isHidden ) {
                    self.view.isHidden = false }
                       // needed to refresh the view after the trash creates a new stack.

        }
        notifications.append(aNotification)

        aNotification = myCenter.addObserver(forName: PGLOutputImageChange, object: nil , queue: queue) { [weak self]
            myUpdate in
            guard let self = self else { return } // a released object sometimes receives the notification
                                     // the guard is based upon the apple sample app 'Conference-Diffable'
//           NSLog("PGLImageController  notification PGLOutputImageChange")
            self.filterValuesHaveChanged = true
            //            self.hideParmControls()
            //this causes parm controls to disseapear during imageUpdate.. at 60 fps.. not good :)

        }
        notifications.append(aNotification)

        aNotification = myCenter.addObserver(forName: PGLAttributeAnimationChange , object: nil , queue: queue) { [weak self ]
            myUpdate in
            guard let self = self else { return } // a released object sometimes receives the notification
                          // the guard is based upon the apple sample app 'Conference-Diffable'
            //           NSLog("PGLImageController  notification PGLAttributeAnimationChange")
            self.filterValuesHaveChanged = true

        }
        notifications.append(aNotification)

        aNotification = myCenter.addObserver(forName: PGLUserAlertNotice, object: nil , queue: queue) {[weak self]
            myUpdate in
            guard let self = self else { return } // a released object sometimes receives the notification
            if let userDataDict = myUpdate.userInfo {
                if let anAlertController = userDataDict["alertController"] as? UIAlertController {
                    self.displayUser(alert: anAlertController)
                }
            }
        }
        notifications.append(aNotification)

        aNotification = myCenter.addObserver(forName: PGLStackSaveNotification , object: nil , queue: queue) { [weak self ]
            myUpdate in
            guard let self = self else { return}
            if let userDataDict = myUpdate.userInfo {
                if let userValues = userDataDict["dialogData"] as? PGLStackSaveData {
                    // put the new names into the stack
                    guard let targetStack = self.appStack.firstStack()
                        else { return }
                    targetStack.stackName = userValues.stackName!
                    targetStack.stackType = userValues.stackType!
                    targetStack.exportAlbumName = userValues.albumName
                    targetStack.shouldExportToPhotos = userValues.storeToPhoto
//                    DispatchQueue.main.async {
//                        NSLog("PGLImageController notification PGLStackSaveNotification start in main sync ")
                        self.saveStack(newSaveAs: userValues.shouldSaveAs)
                        // save stack will create a utility queue to execute.. but should not
                        // kill the utility queue process when this notification callback process ends.
//                    }
                    self.updateNavigationBar()
                }
            }
        }
        notifications.append(aNotification)


        aNotification = myCenter.addObserver(forName: PGLImageCollectionOpen, object: nil , queue: OperationQueue.main) { [weak self]
        myUpdate in
        guard let self = self else { return } // a released object sometimes receives the notification
                      // the guard is based upon the apple sample app 'Conference-Diffable'
//         NSLog("PGLImageController has  PGLImageCollectionOpen -calls doImageCollectionOpen")
        
        if (self.view.isHidden) {self.view.isHidden = false }
            // needed to refresh the view after the trash creates a new stack.

        if let assetInfo = ( myUpdate.userInfo?["assetInfo"]) as? PGLAlbumSource {
            self.doImageCollectionOpen(assetInfo: assetInfo) }
            }

        if let myMetalControllerView = storyboard!.instantiateViewController(withIdentifier: "MetalController") as? PGLMetalController {
            // does the metalView extend under the navigation bar?? change constraints???
            
            myMetalControllerView.view.frame = self.view.bounds
            if let theMetalView = myMetalControllerView.view {
                view.addSubview(theMetalView)
                metalController = myMetalControllerView  // hold the ref
                myScaleFactor = theMetalView.contentScaleFactor
                myScaleTransform = CGAffineTransform(scaleX: myScaleFactor, y: myScaleFactor )
            //            myScaleTransform = CGAffineTransform.identity
            }
        }
        notifications.append(aNotification)



        filterValuesHaveChanged = true
//        updateDisplay()
        updateNavigationBar()

        tintViews.append(contentsOf: [topTintView, bottomTintView, leftTintView, rightTintView])

        let contextMenu = UIMenu(title: "",
                    children: [

                        UIAction(title: "Save..", image:UIImage(systemName: "pencil")) {
                            action in
                                // self.saveStackAlert(self.moreBtn)
                            self.saveStackActionBtn(self.moreBtn)
                                    },
                        UIAction(title: "Save As..", image:UIImage(systemName: "pencil.circle")) {
                            action in
                            self.saveStackAsActionBtn(self.moreBtn)
                                    },
                        UIAction(title: "Privacy.. ", image:UIImage(systemName: "info.circle")) {
                            action in
                            self.displayPrivacyPolicy(self.moreBtn)
                                    },
                        UIAction(title: "Compact Library", image:UIImage(systemName: "pencil")) {
                            action in
                            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate
                            else { return }
                            appDelegate.dataWrapper.build14DeleteOrphanStacks()
                                    }


        ])
            moreBtn.menu = contextMenu

        let theShowHelp =  AppUserDefaults.bool(forKey: showHelpPageAtStartupKey)
        if theShowHelp {
            // if the key does not exist then bool answers false
            helpBtnAction(helpBtn)
            // PGLHelpPageController will set to false after showing help

        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
         appStack.isImageControllerOpen = true
    }

    func viewDidDisappear(animated: Bool) {
        appStack.isImageControllerOpen = false // selection of new image or image list is started
        removeGestureRecogniziers()
        super.viewDidDisappear(animated)

        for anObserver in  notifications {
                       NotificationCenter.default.removeObserver(anObserver)
                   }
        notifications = [Any]() // reset
    }



    func hideParmControls() {
        // called from the PGLParmTableViewController viewDidDisappear
        hideSliders()
        removeParmControls()
        parmSlider?.isHidden = true

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: public protocol to vars

    func setParms(newFilterParms: [PGLFilterAttribute]) {

        // Sender?
        // set parms with the attributeName as the dictionary key for the filterAttribute
        // what about clearing old  buttons  in updateParmControls?
        parms =  [String : PGLFilterAttribute]()
        for anAttribute in newFilterParms {
            parms[anAttribute.attributeName!] = anAttribute
        }

        updateParmControls()
    }

    // moved or new method for iPhone
    // the Parm controller may not be loaded in
    // the secondaryViewOnly mode - only the imageController is loaded

    func highlight(viewNamed: String) {

        // a switch statement might be cleaner
        // both UIImageView and UIControls need to be hidden or shown
        Logger(subsystem: LogSubsystem, category: LogCategory).notice("highlight viewNamed \(viewNamed)")
        for aParmControlTuple in parmControls {
            if aParmControlTuple.key == viewNamed {
                // show this view
                Logger(subsystem: LogSubsystem, category: LogCategory).debug("highlight view isHidden = false, hightlight = true")
                if let imageControl = (aParmControlTuple.value) as? UIImageView {
                    imageControl.isHidden = false
                    imageControl.isHighlighted = true
                    Logger(subsystem: LogSubsystem, category: LogCategory).debug("highlight UIImageView isHidden = false, hightlight = true")
                } else {if let viewControl = (aParmControlTuple.value) as? UITextField {
                    viewControl.isHidden = false
                    viewControl.isHighlighted = true
                    viewControl.becomeFirstResponder()
                    Logger(subsystem: LogSubsystem, category: LogCategory).debug("highlight UITextField isHidden = false, hightlight = true")
                    }

                }

            } else { // hide other views

                if let imageControl = (aParmControlTuple.value) as? UIImageView {
                    imageControl.isHidden = true
                    imageControl.isHighlighted = false
                    Logger(subsystem: LogSubsystem, category: LogCategory).notice("highlight HIDE UImageView \(aParmControlTuple.key)")
                } else {if let viewControl = (aParmControlTuple.value) as? UITextField {
                    NSLog("highlight END TextField editing \(aParmControlTuple.key)")
                    viewControl.endEditing(true)
                    viewControl.resignFirstResponder()
                    viewControl.isHidden = true
                    viewControl.isHighlighted = false
                    Logger(subsystem: LogSubsystem, category: LogCategory).notice("highlight HIDE UIControl \(aParmControlTuple.key)")
                    }
                }
            }
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // moved to  PGLImageController -
         panner?.isEnabled = false // only enable pan gesture on certain cases

//        NSLog("PGLSelectParmController # tableView(..didSelectRowAt tappedAttribute = \(tappedAttribute!.attributeDisplayName)")
        guard let modelAttribute = appStack.targetAttribute else
            { return }


        switch modelAttribute.attributeUIType() {
        case AttrUIType.pointUI , AttrUIType.rectUI:
//            var croppingFilter: PGLRectangleFilter?

            panner?.isEnabled = true
            guard let thisAttributeControlView = parmControls[modelAttribute.attributeName ?? "forceReturn"] else
                { return }
             selectedParmControlView = thisAttributeControlView
            if let thisAttributeName = modelAttribute.attributeName {
                highlight(viewNamed: thisAttributeName)
                parmSlider.isHidden = true
                hideSliders()
                if let thisCropAttribute = modelAttribute as? PGLAttributeRectangle {
                    guard let croppingFilter = appStack.currentFilter as? PGLRectangleFilter
                    else { return }

                    croppingFilter.cropAttribute = thisCropAttribute
                    guard let activeRectController = rectController
                        else {return }
                    activeRectController.thisCropAttribute = thisCropAttribute
                    showRectInput(aRectInputFilter: croppingFilter)


                    }

            }
      case AttrUIType.sliderUI , AttrUIType.integerUI  :
            // replaced by the slider in the tablePaneCell
            // do not show the slider in the image

           addSliderControl(attribute: modelAttribute)
           highlight(viewNamed: modelAttribute.attributeName!)
            // enable the slider

        case AttrUIType.textInputUI :
//                imageController!.addTextInputControl(attribute:  modelAttribute)
            // added already in updateParmControls

                highlight(viewNamed: modelAttribute.attributeName!)
            addTextChangeNotification(textAttributeName: modelAttribute.attributeName!)
            parmSlider.isHidden = true
            hideSliders()

        case AttrUIType.fontUI :
            parmSlider.isHidden = true
            hideSliders()
            showFontPicker(self)

        case AttrUIType.timerSliderUI:
            // the PGLFilterAttributeNumber has to answer the sliderCell for this to run.. currently commented out 5/16/19

            if let selectedSliderCell = tableView.cellForRow(at: indexPath) as? PGLTableCellSlider {
                selectedSliderCell.sliderControl.isEnabled = true
            }
            hideSliders()
//        case AttrUIType.imagePickUI :
            // did the photo or filter cell get touched?
          //  pickImage(tappedAttribute!)
            // now called by swipe action "Pick"

        default:
            highlight(viewNamed: "")
        }
       // this method completes before the processses invoked above run..
        // updates need to be invoked in the completion routines
    }

    func addTextChangeNotification(textAttributeName: String) {

//        NSLog("PGLSelectParmController addTextChangeNotification for \(textAttributeName)")
        let myCenter =  NotificationCenter.default
        let queue = OperationQueue.main
        guard let textField = parmControls[ textAttributeName ] as? UITextField else
            {return }
        let textNotifier = myCenter.addObserver(forName: UITextField.textDidChangeNotification, object: textField , queue: queue) {[weak self]
            myUpdate in
            guard let self = self else { return } // a released object sometimes receives the notification
                          // the guard is based upon the apple sample app 'Conference-Diffable'
//            NSLog("PGLSelectParmController  notificationBlock UITextField.textDidChangeNotification")
            if let target = self.appStack.targetAttribute {
                if target.isTextInputUI()  {
                    // shows changes as they are typed.. no commit reason
                // put the new value into the parm
                    target.set(textField.text as Any)

            }
        }

        }
        notifications.append(textNotifier)
        // this notification is removed with all the notifications in viewWillDisappear

    }

// MARK: MTKViewDelegate drawing

 
// MARK: - GLKViewDelegate and GLKViewController delegate methods



    // MARK: parmUI
    func updateParmControls() {
        if parmControls.count > 0 {
//            NSLog("PGLImageController should remove old parm buttons")
            removeParmControls()
        }
        for attribute in parms {
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

    func showRectInput(aRectInputFilter: PGLRectangleFilter) {
        guard let thisRectController = rectController
        else { return }

        thisRectController.croppingFilter = aRectInputFilter
//        thisRectController.thisCropAttribute = aRectInputFilter.cropAttribute
        showCropTintViews(setIsHidden: false)
        
    }

    func removeParmControls() {
        // should use the attribute methods isPointUI() or isRectUI()..
        for nameAttribute in parms {
            let parmAttribute = nameAttribute.value

            if parmAttribute.isPointUI() || parmAttribute.isTextInputUI() {

                let parmView = parmControls[nameAttribute.key]
                if parmAttribute.isTextInputUI() {
                    if let textInputField = parmView as? UITextField {
//                        NSLog("ImageController removeParmControls on textField -- end editing?")
//                    textInputField.endEditing(true)
                    // end editing should cause resignFirstResponder and keyboard disappears
//                   textInputField.resignFirstResponder()
                    }
                }
                    parmView?.removeFromSuperview()
                    parmControls.removeValue(forKey: nameAttribute.key)
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
            let mappedOrigin = attribute.mapVector2Point(vector: positionVector, viewHeight: inViewHeight, scale: myScaleFactor)



            let controlFrame = CGRect(origin: mappedOrigin, size: newSize)
            // newOrigin should be the center of the controlFrame

            let newView = UIImageView(image: crossPoint)
//            newView.animationImages?.append(reverseCrossPanimationImagesoint!)
//            newView.animationDuration = 1.0

            newView.frame =  controlFrame
            newView.center = mappedOrigin

            newView.isOpaque = true
//            newView.alpha = 0.6 alpha not used when isOpaque == true
//            newView.tintColor = .systemFill
//            newView.backgroundColor = .systemBackground
            newView.isUserInteractionEnabled = true


            view.addSubview(newView)
            parmControls[attribute.attributeName!] = newView
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
        let textValue = attribute.getValue() as? String // need to put implementations in the above classes
        // put in the center of the control
        let centerPoint = (view.center)
        let boxSize = CGSize(width: 250, height: 40)
        let boxFrame = CGRect(origin: centerPoint, size: boxSize)

        let inputView = UITextField(frame: boxFrame)
        inputView.borderStyle = UITextField.BorderStyle.bezel
        inputView.placeholder = textValue
        inputView.backgroundColor = UIColor.systemBackground
//        inputView.isOpaque = true
        inputView.delegate = parmController
        view.addSubview(inputView)
        parmControls[attribute.attributeName!] = inputView
         NSLayoutConstraint.activate([
            inputView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            inputView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            inputView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.66, constant: 0)
                                    ])
        inputView.isHidden = true
//        NSLog("addTextInputControl attributeValue = \(textValue)")
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
            parmControls[attribute.attributeName!] = rectCropView
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


    func addSliderControl(attribute: PGLFilterAttribute)  {
        hideSliders() // start with all hidden

        switch attribute {
            case let aColorAttribute as PGLFilterAttributeColor:

                sliders[SliderColor.Alpha.rawValue].setValue(Float(aColorAttribute.alpha), animated: false )
                sliders[SliderColor.Blue.rawValue].setValue(Float(aColorAttribute.blue ), animated: false )
                sliders[SliderColor.Green.rawValue].setValue(Float(aColorAttribute.green), animated: false )
                sliders[SliderColor.Red.rawValue].setValue(Float(aColorAttribute.red), animated: false )

                for aSlider in sliders {
                    aSlider.isHidden = false
                    view.bringSubviewToFront(aSlider)
            }

            case _ as PGLFilterAttributeAngle:
                if let numberValue = attribute.getNumberValue() as? Float {
                    parmSlider.maximumValue = attribute.sliderMaxValue! // init to 2pi Radians
                    parmSlider.minimumValue = attribute.sliderMinValue!  // init to 0.0
                    parmSlider.setValue( numberValue, animated: false )
                }
                parmSlider.isHidden = false
                 view.bringSubviewToFront(parmSlider)
//            case let rectAttribute as PGLFilterAttributeRectangle:
//                NSLog("Should not hit this case where addSlider control called for a rectangle attribute")
            case _ as PGLFilterAttributeAffine:
                parmSlider.maximumValue = 2 *  Float.pi  // this is the rotation part of the Affine
                parmSlider.minimumValue = 0.0
                parmSlider.isHidden = false
                view.bringSubviewToFront(parmSlider)
            default: if let numberValue = attribute.getNumberValue()?.floatValue {
                    parmSlider.maximumValue = attribute.sliderMaxValue ?? 100.0
                    parmSlider.minimumValue = attribute.sliderMinValue ?? 0.0
                    parmSlider.setValue( numberValue, animated: false )
                    }
                    else { // sort of assuming angle.. need to explore this else statement further
                        parmSlider.maximumValue = 2 *  Float.pi  // assuming this is for angle radians - see Straighten Filter
                        parmSlider.minimumValue = 0.0
                        // defaults value to 0.0

                    }

                parmSlider.isHidden = false
                view.bringSubviewToFront(parmSlider)
//            NSLog("PGLImageController addSliderControl \(attribute.description)")
//            NSLog("slider min = \(parmSlider.minimumValue) max = \(parmSlider.maximumValue) value = \(parmSlider.value)")

        }



    }

    func hideSliders() {
        for aSlideControl in sliders {
            aSlideControl.isHidden = true
        }
    }
    @objc func buttonWasPressed(_ sender: UIButton , forEvent: UIEvent) {
       if let buttonIndex = parmControls.firstIndex(where: { $0.value.tag == sender.tag } )
       {
        let matchedAttributeName = parmControls[buttonIndex].key
        let matchedAttribute = parms[matchedAttributeName]
//        NSLog("PGLImageController #buttonWasPressed attribute = \(String(describing: matchedAttribute))")
        }
    }

}

extension PGLImageController: UIGestureRecognizerDelegate, UIFontPickerViewControllerDelegate {

    // MARK: Sliders
//    @IBAction func parmSliderChange(_ sender: UISlider) {
//
//        // later move the logic of sliderValueDidChange to here..
////        sliderValueDidChange(sender)
//        // slider in the parmController tableView cell
//        // Need to ensure that the cell containing the slider control is highlighted
//        // i.e. tappedAttribute is the parmSliderInputCell
//        // timer slider is enabled when the cell is selected
//        // see DidSelectRowAt for the TimerSliderUI case where it is enable
//
//        if let target = appStack.targetAttribute {
//            Logger(subsystem: LogSubsystem, category: LogCategory).debug("PGLSelectParmController #parmSliderChange  value = \(sender.value)")
//            target.uiIndexTag = Int(sender.tag)
//                // multiple controls for attribute distinguished by tag
//                // color red,green,blue for single setColor usage
//            let adjustedRate = sender.value //  / 1000
//            target.set(adjustedRate)
//        } else {
//            Logger(subsystem: LogSubsystem, category: LogCategory).error( "PGLSelectParmController parmSliderChange fatalError( tappedAttribute is nil, value can not be changed")
//            return
//        }
//        view.setNeedsDisplay()
//    }

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
        } else {
            NSLog("PGLSelectParmController sliderValueDidChange fatalError( tappedAttribute is nil, value can not be changed") }


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
                NSLog("PGLImageController #removeGestureRecogniziers")
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

        // MARK:  UIFontPickerViewControllerDelegate
            func showFontPicker(_ sender: Any) {

                    let fontConfig = UIFontPickerViewController.Configuration()
                    fontConfig.includeFaces = false
                    let fontPicker = UIFontPickerViewController(configuration: fontConfig)
                    fontPicker.delegate = self
                    self.present(fontPicker, animated: true, completion: nil)
                }

        func fontPickerViewControllerDidPickFont(_ viewController: UIFontPickerViewController) {

            if let target = appStack.targetAttribute {
                if target.isFontUI() {
                    let theFont = viewController.selectedFontDescriptor
                    target.set(theFont?.postscriptName as Any)
                }

            }
        }

    // MARK: UITextFieldDelegate
        // called from the textFields of the ImageController
        func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {

            // are there any senders of this?

            // input text from the imageController
    //        NSLog("ParmController textFieldDidEndEditing ")
            if let target = appStack.targetAttribute {
                if target.isTextInputUI() && reason == .committed {
                // put the new value into the parm
                target.set(textField.text as Any)

            }
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
