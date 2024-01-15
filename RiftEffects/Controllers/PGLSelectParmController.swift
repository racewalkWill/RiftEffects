//
//  PGLSelectParmController.swift
//  PictureGlance
//
//  Created by Will on 8/13/17.
//  Copyright © 2017 Will. All rights reserved.
//

import UIKit
import simd
import PhotosUI
import os


enum ImageParm: Int {
    case notAnImageParm = -1 // superclass of PGLFilterAttributeImage will use this...
    case inputPhoto = 0  // input from imageList of one or more images
    case inputChildStack = 1 // input from a child stack
    case inputPriorFilter = 2  // previous filter in the stack is input
    case missingInput = 3
}


let  PGLAttributeAnimationChange = NSNotification.Name(rawValue: "PGLAttributeAnimationChange")
let  PGLReloadParmCell = NSNotification.Name(rawValue: "PGLReloadParmCell")

class PGLSelectParmController: PGLCommonController,
            UITableViewDelegate, UITableViewDataSource,
             UINavigationControllerDelegate ,
             UIGestureRecognizerDelegate,
             UISplitViewControllerDelegate


{

    // UITableViewController
//    var parmStackData: () -> PGLFilterStack?  = { PGLFilterStack() }
    // a function is assigned to this var that answers the filterStack
//    var myMasterSplitController: PGLSplitViewController?


    var currentFilter: PGLSourceFilter?  {
        didSet {
            let allAttributes = ((currentFilter?.attributes)!)
            filterLabel.text = appStack.getViewerStack().filterNumLabel(maxLen: nil) // don't truncate

            filterParms[sectionImages] = allAttributes.filter{ $0.isImageUI() }  //isImageInput
            var nonImageParms = allAttributes.filter{ !($0.isImageUI()) } //isImageInput

            loadTimerCells(parms: &nonImageParms)
                // adds a timerUICell for any parm running animation

            filterParms[sectionParms] = nonImageParms
            // filterParms[sectionOther] = [PGLFilterAttribute]()
                // other section is currently not used

            if !(currentFilter === appStack.currentFilter)  {
                // identity test not value compare
                parmsListHasChanged()
                    // this triggers setting of the current filter
                    // into the appStack model
            }

        }
    }

    var filterParms: [[PGLFilterAttribute]] = [[PGLFilterAttribute](), [PGLFilterAttribute]()]
                                               // ,[PGLFilterAttribute]()] not using the 'other section
//    var imageAttributes = [PGLFilterAttribute]()  // attributes for an image - input, background, mask etc..
//    var parmAttributes = [PGLFilterAttribute]()  // not an image - all other parms
//    var valueAttributes = [PGLFilterAttribute]()  // supporting value attributes for parent attibutes

    var tappedAttribute: PGLFilterAttribute?
    let sectionImages = 0
    let sectionParms = 1
    let sectionOther = 2

    var imageController: PGLImageController?
    
    var imagePicker: PGLImageListPicker?

        // (UITraitCollection.current.userInterfaceIdiom == .pad)
        // false will use the WWDC20 PHPickerViewController image selection
        // true - iPad uses PGLImagePicker which tracks the album source of the picked image

//    var picker: PHPickerViewController?
    
    var scaleFactor: CGFloat = 2.0

//    let arrowRightCirclFill = UIImage(systemName: "arrow.right.circle.fill")
//    let shiftBtnDown = UIImage(systemName: "arrow.right.circle")

//MARK: IBActions Outlets
    @IBOutlet weak var parmsTableView: UITableView! {
        didSet{
            parmsTableView.dataSource = self
            parmsTableView.delegate = self
        }
    }

    var timerParm: PGLTimerRateAttributeUI?

    var selectedCellIndexPath: IndexPath?

    @IBOutlet weak var progressView: UIProgressView!
    

    @IBAction func backButtonAction(_ sender: UIBarButtonItem) {
//        let actionAccepted = Notification(name: PGLImageNavigationBack )
//               NotificationCenter.default.post(actionAccepted)
        if (traitCollection.horizontalSizeClass == .compact)
        { // now in the twoContainer mode on the iphone
            // navigation pop needs to trigger the parent popViewController
            // so that it moves back to the stack controller
            guard let myNav = self.navigationController else { return }

            guard myNav.topViewController is PGLParmImageController
                else { Logger(subsystem: LogSubsystem, category: LogNavigation).info( "\("#popViewController " + String(describing: self))")
                    myNav.popViewController(animated: true )
                        return
            }
            guard let myStackController = myNav.viewControllers[1] as? PGLStackController else {
                Logger(subsystem: LogSubsystem, category: LogNavigation).info( "\("#popViewController " + String(describing: self))")
                myNav.popViewController(animated: true )
                return
            }
            Logger(subsystem: LogSubsystem, category: LogNavigation).info( "\("#popViewController " + String(describing: myStackController))")
            self.navigationController?.popToViewController(myStackController, animated: true)
        }
        else {
            // move back to the stack controller
            Logger(subsystem: LogSubsystem, category: LogNavigation).info( "\("#popViewController " + String(describing: self))")
            self.navigationController?.popViewController(animated: true) }

    }
    @IBOutlet weak var shiftBtn: UIBarButtonItem!

    @IBOutlet weak var filterShiftLabel: UIBarButtonItem!
    
    @IBOutlet weak var filterLabel: UILabel!
    
   

    @IBOutlet weak var upChevron: UIBarButtonItem!

    @IBOutlet weak var downChevron: UIBarButtonItem!


    @IBAction func openChildStackAction(_ sender: UIBarButtonItem) {
        if (tappedAttribute?.hasFilterStackInput())! {
            performSegue(withIdentifier: "filterSegue", sender: tappedAttribute)
            // needs work.. add this in the prepare for segue
        }
    }

    @IBAction func showImageController(_ sender: UIBarButtonItem) {
        splitViewController?.show(.secondary)

    }


    @IBAction func normalizeBtnClick(_ sender: UIButton) {
        // PGLConvolution filters - normalize the weights vector
        if let convolutionFilter = currentFilter as? PGLConvolutionFilter {
            convolutionFilter.normalizeWeights()
            view.setNeedsDisplay()
            imageController?.view.setNeedsDisplay()
        }
    }




    // MARK: View change
    fileprivate func setImageController() {
//        let primaryController  = splitViewController?.viewController(for: .primary)
//        let supplementaryController =  splitViewController?.viewController(for: .supplementary)
        if let myTwoContainerParent = parent as? PGLParmImageController {
            // an iPhone layout where there are two imageControllers one in the twoContainer
            // the other in the splitView secondary column
            imageController = myTwoContainerParent.containerImageController

        } else {
            let secondaryController  = splitViewController?.viewController(for: .secondary)
            let navController = secondaryController as? UINavigationController
            imageController = navController?.visibleViewController as? PGLImageController
        }

        if imageController != nil {
                imageController!.parmController = self
                scaleFactor = imageController!.myScaleFactor // the metalView scaleFactor typically = 2.0
        }
    }





    // MARK: View Lifecycle
    override func viewDidLoad() {
        Logger(subsystem: LogSubsystem, category: LogNavigation).info("\( String(describing: self) + "-" + #function)")
        super.viewDidLoad()

        splitViewController?.delegate = self


        navigationItem.title = "Parms"//viewerStack.stackName


//        NSLog ("PGLSelectParmController #viewDidLoad completed")
        if traitCollection.userInterfaceIdiom == .pad {
//            navigationController?.isToolbarHidden = true
            // commented out because this makes the stackController toolbar
            // hidden.. for some strange reason!
        } // was true
        // don't hide if iPhone
     
//        let lib = PHAsset.fetchAssets(withLocalIdentifiers: ["empty"], options: nil)

    }


    fileprivate func updateDisplay() {
        // does not do much... remove  ?

        // See currentFilter didSet - didSet then triggers the parm updates and adding controls for the parms to the glkView
        // dependent on current filter.
        Logger(subsystem: LogSubsystem, category: LogCategory).debug ("PGLSelectParmController #updateDisplay start ")
        let viewerStack = appStack.getViewerStack()
        if viewerStack.isEmptyStack() { return }
            // nothing to do .. no filter selected or added

        currentFilter = viewerStack.currentFilter()


        setShiftBtnState()
            // if only one filter then shift to this filter does not change anything
//         NSLog ("PGLSelectParmController #updateDisplay end ")


    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        reloadImageCellIcons()
        // PGLRedrawParmControllerOpenNotification
        let updateNotification = Notification(name:PGLRedrawParmControllerOpenNotification)
        NotificationCenter.default.post(name: updateNotification.name, object: nil, userInfo: ["parmControllerIsOpen" : true as AnyObject])

    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Logger(subsystem: LogSubsystem, category: LogCategory).debug("PGLSelectParmController#viewWillAppear start ")
        if imageController == nil {
            setImageController()
        }
//        imageController?.setGestureRecogniziers()
//        if let myView = imageController?.view
//            { // could be navigation issue
//
//            setGestureRecogniziers(targetView: myView) // matches viewDidDisappear removeGesture
//        } else {
//            // need to abort this loading... navigation issue -
//            // how to abort or recover?
//            Logger(subsystem: LogSubsystem, category: LogCategory).fault("PGLSelectParmController viewWillAppear imageController.view not set")
//        }
        let myCenter =  NotificationCenter.default
        let queue = OperationQueue.main
        var aNotification = myCenter.addObserver(forName: PGLCurrentFilterChange, object: nil , queue: queue) {[weak self]
                    myUpdate in
                    guard let self = self else { return } // a released object sometimes receives the notification
                                  // the guard is based upon the apple sample app 'Conference-Diffable'
            Logger(subsystem: LogSubsystem, category: LogNavigation).info("PGLSelectParmController  notificationBlock PGLCurrentFilterChange")
                    self.updateDisplay()
                }
        notifications[PGLCurrentFilterChange] = aNotification

        aNotification = myCenter.addObserver(forName: PGLLoadedDataStack, object: nil , queue: queue) {[weak self]
            myUpdate in
            guard let self = self else { return } // a released object sometimes receives the notification
                          // the guard is based upon the apple sample app 'Conference-Diffable'
            Logger(subsystem: LogSubsystem, category: LogNavigation).info("PGLSelectParmController  notificationBlock PGLLoadedDataStack")
            self.navigationController?.popViewController(animated: true)

        }
        
        notifications[PGLLoadedDataStack] = aNotification

                //PGLAttributeAnimationChange
              aNotification =  myCenter.addObserver(forName: PGLAttributeAnimationChange, object: nil, queue: queue) { [weak self]
                    myUpdate in
                    guard let self = self else { return } // a released object sometimes receives the notification
                                  // the guard is based upon the apple sample app 'Conference-Diffable'
//                  Logger(subsystem: LogSubsystem, category: LogNavigation).info("PGLSelectParmController  notificationBlock PGLAttributeAnimationChange")
                    if let attribute = myUpdate.object as? PGLFilterAttribute {
                        // find the cell for the attribute and update the display
                        // is the attribute for the current filter?
                        if attribute.aSourceFilter === self.currentFilter! {
                        if let cellPath = attribute.uiIndexPath {
                            if let animationCell = self.parmsTableView.cellForRow(at: cellPath) {
                                self.showTextValueInCell(attribute, animationCell)
                                animationCell.setNeedsDisplay() // should cause detail text to update from the attribute
                                }
                            }
                        }
                    }
                }
            notifications[PGLAttributeAnimationChange] = aNotification

        aNotification = myCenter.addObserver(forName: PGLReloadParmCell, object: nil , queue: queue) {[weak self]
            myUpdate in
            guard let self = self else { return } // a released object sometimes receives the notification
                          // the guard is based upon the apple sample app 'Conference-Diffable'
            Logger(subsystem: LogSubsystem, category: LogNavigation).info("PGLSelectParmController  notificationBlock PGLReloadParmCell")
            if let attribute = myUpdate.object as? PGLFilterAttribute {
                if let cellPath = attribute.uiIndexPath {
                    self.parmsTableView.reloadRows(at: [cellPath], with: .automatic)
                    }
            }
        }
        notifications[PGLReloadParmCell] = aNotification

        updateDisplay()
        setChevronState()
        if traitCollection.userInterfaceIdiom == .phone {
            imageController?.keepParmSlidersVisible = false

        }
//         NSLog("PGLSelectParmController#viewWillAppear end ")
    }



    override func viewWillDisappear(_ animated: Bool) {
        // remove the parm views and the gesture recogniziers

        imageController?.hideParmControls() // just hides the UI controls
        for (name , observer) in  notifications {
                       NotificationCenter.default.removeObserver(observer, name: name, object: nil)
                   }
        notifications = [:] // reset
//        navigationController?.isToolbarHidden = false

    }

    override func viewDidDisappear(_ animated: Bool) {
        view = nil
//        currentFilter = nil
        tappedAttribute = nil

        // don't update the model targetAttribute.. the imageController needs it.
        let updateNotification = Notification(name:PGLRedrawParmControllerOpenNotification)
        NotificationCenter.default.post(name: updateNotification.name, object: nil, userInfo: ["parmControllerIsOpen" : false as AnyObject])
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    // MARK: NavigationBar

    @IBAction func shiftBtnAction(_ sender: UIBarButtonItem) {
        appStack.toggleShowFilterImage()
        setShiftBtnState()
        // setChevronState called in setShiftBtnState()

    }


    @IBAction func filterShiftLabelAction(_ sender: UIBarButtonItem) {
        // dispatch to shiftBtn..
        shiftBtnAction(sender)
    }

    @IBAction func upChevronAction(_ sender: UIBarButtonItem) {
            imageController?.keepParmSlidersVisible = false
                imageController?.hideParmControls()
               appStack.moveActiveBack()
                setChevronState()
               postCurrentFilterChange()
        
    }

    func setShiftBtnState() {
        shiftBtn.isEnabled = (appStack.flatRowCount() > 1)
        filterShiftLabel.isEnabled = shiftBtn.isEnabled
        if (appStack.showFilterImage) {
            filterShiftLabel.title = StackDisplayMode.Single.rawValue
        } else {
            filterShiftLabel.title = StackDisplayMode.All.rawValue
        }
        setChevronState()

    }

    func setChevronState() {
        if !appStack.showFilterImage {
            upChevron.isEnabled = false
            downChevron.isEnabled = false
            return }

        let rowCount = appStack.flatRowCount()
        if (rowCount <= 1) {
            // disable both chevrons
            upChevron.isEnabled = false
            downChevron.isEnabled = false
            return
        }

        let theSelectedRow = appStack.activeFilterCellRow()
            switch theSelectedRow {
                case 0 :
                    // on first.. can't go further
                    upChevron.isEnabled = false
                    downChevron.isEnabled = true
                case rowCount - 1 :
                    // on last filter can't go further
                    upChevron.isEnabled = true
                    downChevron.isEnabled = false
                default:
                    // in the middle enable both
                    upChevron.isEnabled = true
                    downChevron.isEnabled = true
            }
    }

    @IBAction func downChevronAction(_ sender: UIBarButtonItem) {
        imageController?.keepParmSlidersVisible = false
        imageController?.hideParmControls()
        appStack.moveActiveAhead() // changes to child if needed
        setChevronState()
        postCurrentFilterChange()

    }
    // MARK: Gestures


    var selectedParmControlView: UIView?
    var tappedControl: UIView?



    fileprivate func setDissolveWrapper() {
        // install a detector input to the tappedAttribute.
        // needs input image of this filter and a detector
        // detector holds the parm to set point values
        // this filter should also keep the detectors for forwarding of increment and dt time changes
        //                let detector = PGLDetector(ciFilter: PGLFaceCIFilter())
        // create the wrapper filter
//        "PGLSelectParmController #setDissolveWrapper start"
        guard let selectedFilter = currentFilter
            else {return}
        let wrapperDesc = PGLFilterDescriptor("CIDissolveTransition", PGLDissolveWrapperFilter.self)!
        let wrapperFilter = wrapperDesc.pglSourceFilter() as! PGLDissolveWrapperFilter

        let faceDetector =  DetectorFramework.Active.init(ciFilter: selectedFilter.localFilter)

        faceDetector.setCIContext(detectorContext: appStack.getViewerStack().imageCIContext)

        faceDetector.filterAttribute = tappedAttribute

        selectedFilter.setWrapper(outputFilter: wrapperFilter, detector: faceDetector)

        currentFilter?.hasAnimation = false  //  current filter is NOT animating. The wrapper is

    }



    // MARK: ImageController actions
    fileprivate func postCurrentFilterChange() {
        let updateFilterNotification = Notification(name: PGLCurrentFilterChange)
//        NotificationCenter.default.post(updateFilterNotification)
        NotificationCenter.default.post(name: updateFilterNotification.name, object: nil, userInfo: ["sender" : self as AnyObject])


    }


    


    func parmsListHasChanged() {
        // notify the tableview & detailimageController to refresh
        Logger(subsystem: LogSubsystem, category: LogCategory).notice("PGLSelectParmController #parmsListHasChanged - reloadData() start")
        parmsTableView.reloadData()
//        navigationController?.toolbar.setNeedsDisplay()
        //notify the detailimageController that the parms have changed and should show on the image
//          NSLog("parmsListHasChanged - reloadData() end")

        appStack.currentFilter = currentFilter
        appStack.setParms(newFilterParms: filterParms[sectionParms])
       imageController?.addParmControls()
            // MARK: appStackParmRefactor
           


    }

    func imageViewParmControls() -> [String : UIView] {
        // answers dictionary indexed index by attributeName

        return appStack.parmControls
    }

    func parmControl(named: String) -> UIView? {

        return appStack.parmControls[named]
    }



    @IBAction func parmSliderChange(_ sender: UISlider) {

        // later move the logic of sliderValueDidChange to here..
//        sliderValueDidChange(sender)
        // slider in the parmController tableView cell
        // Need to ensure that the cell containing the slider control is highlighted
        // i.e. tappedAttribute is the parmSliderInputCell
        // timer slider is enabled when the cell is selected
        // see DidSelectRowAt for the TimerSliderUI case where it is enable

        if let target = appStack.targetAttribute {

            target.uiIndexTag = Int(sender.tag)
                // multiple controls for attribute distinguished by tag
                // color red,green,blue for single setColor usage
            let adjustedRate = sender.value //  / 1000
            target.set(adjustedRate)
        } else {
            Logger(subsystem: LogSubsystem, category: LogCategory).error( "PGLSelectParmController parmSliderChange fatalError( tappedAttribute is nil, value can not be changed")
            return
        }
//        attributeValueChanged()
        imageController?.view.setNeedsDisplay()
    }
    func setRotation(_ sender: UISlider) {
        if let affineAttribute = tappedAttribute as? PGLFilterAttributeAffine {
            affineAttribute.setRotation(radians: sender.value)
        }
    }
    func colorSliderValueDidChange(_ sender: UISlider) {

        // from the imageController sliderValueDidChange
        //        NSLog("PGLSelectParmController #sliderValueDidChange to \(sender.value)")
        let senderIndex: Int = Int(sender.tag)
        if let colorAttribute = tappedAttribute as? PGLFilterAttributeColor {
            if let aColor = SliderColor(rawValue: senderIndex) {
                let sliderValue = (CGFloat)(sender.value)
                colorAttribute.setColor(color: aColor , newValue: sliderValue  )
//                attributeValueChanged()
                imageController?.view.setNeedsDisplay()
            }
        }
    }

    func sliderValueDidChange(_ sender: UISlider) {

        // slider in the imageController on the image view
        if let target = tappedAttribute {
//          NSLog("PGLSelectParmController #sliderValueDidChange target = \(target) value = \(sender.value)")
            target.uiIndexTag = Int(sender.tag)
                // multiple controls for attribute distinguished by tag
                // color red,green,blue for single setColor usage
         
            target.set(sender.value)
        } else {
            NSLog("PGLSelectParmController sliderValueDidChange fatalError( tappedAttribute is nil, value can not be changed") }


//        attributeValueChanged()
        imageController?.view.setNeedsDisplay()
    }




    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        //  return the number of sections
       
       return filterParms.count

    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case sectionImages:
                return "Images"
        case sectionParms:
                return "Parms"
//        case sectionOther:
//            return "Other"
        default:
                return "Speed"
        }
       

    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // return the number of rows
        var rowCount = 0
        switch section {
        case    sectionImages:
                rowCount = filterParms[sectionImages].count  // filter cell is moves to swipe action
        case sectionParms:
                rowCount = filterParms[sectionParms].count

            // why does update after the vary fail with this logic???
//                let baseRows = filterParms[sectionParms].count
//                let timerRows = (filterParms[sectionParms].filter { $0.hasAnimation()}).count
//                return baseRows + timerRows
            // end why ???
//        case sectionOther  :
//                rowCount = filterParms[sectionOther].count
        default: rowCount = 0
        }
//        NSLog("PGLSelectParmController numberOfRowsInSection section =\(section) = \(rowCount)")
        return rowCount
    }

    func getTappedAttribute(indexPath: IndexPath) -> PGLFilterAttribute? {
        return filterParms[indexPath.section][indexPath.row]

    }

    fileprivate func showTextValueInCell(_ parmAttribute: PGLFilterAttribute, _ cell: UITableViewCell) {
        // normally the attribute value is shown
        // but subclass PGLTableCellSlider of UITableViewCell
        // will show the value of the slider.
        if let sliderCell = cell as? PGLTableCellSlider {
                sliderCell.showTextValueInCell() }
            else {
                cell.detailTextLabel?.text = parmAttribute.valueString() }
        
        

    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // 4/18/19 attribute will supply the cell identifier to use
        // 2/24/20  not clear why this is called after seque to the PGLImageCollectionMasterController

//        Logger(subsystem: LogSubsystem, category: LogCategory).info("PGLSelectParmController cellForRowAt indexPath = \(indexPath)")
        tappedAttribute = getTappedAttribute(indexPath: indexPath)
        appStack.targetAttribute = tappedAttribute
            // pass to the model refectoring

//        NSLog("PGLSelectParmController cellForRowAt tappedAttribute = \(tappedAttribute)")
        let cellIdentifier = tappedAttribute?.uiCellIdentifier() ??  "parmNoDetailCell"
//      NSLog("PGLSelectParmController cellForRowAt cellIdentifier = \(cellIdentifier)")
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
//        NSLog("PGLSelectParmController cellForRowAt cell = \(cell)")
        tappedAttribute?.setUICellDescription(cell)
        tappedAttribute?.uiIndexPath = indexPath
        if tappedAttribute?.inputParmType() == ImageParm.inputPriorFilter {
            cell.accessoryType = .none
            // input from prior cell always overrides any other image input
            // can't change or choose image.. remove the disclosure indicator of the cell
        } else {
            if tappedAttribute?.inputParmType() != ImageParm.notAnImageParm {
                cell.accessoryType = .detailDisclosureButton
            }
        }
        return cell

    }

    func loadTimerCells( parms: inout [PGLFilterAttribute]) {
        // look for cells attributes that have animation running
        // perform the .addCell from the trailingSwipeActionsConfigurationForRowAt
        var timerRowsCount = 0
        for rowIndex in ( 0..<parms.count) {
            let aParm = parms[rowIndex]
            if ( aParm.hasAnimation()) {
                if let newVaryAttribute = aParm.varyTimerAttribute() {
                    let aParmRow = rowIndex + timerRowsCount
                        // may have added other timer rows too
                    let newRow = (aParmRow + 1)
                    parms.insert(newVaryAttribute, at: newRow )

                    timerRowsCount += timerRowsCount

                }
            }
        }
    }

    // MARK: UITableViewDelegate





//    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
//
//    }


    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        Logger(subsystem: LogSubsystem, category: LogCategory).notice("accessoryButtonTappedForRowWith indexPath = \(indexPath)")

        tappedAttribute = filterParms[indexPath.section][indexPath.row]  // ERROR is it image or parmAttributes
        appStack.targetAttribute = tappedAttribute
            // set the model attribute for the imageController use

        Logger(subsystem: LogSubsystem, category: LogCategory).notice("PGLSelectParmController accessoryButtonTappedForRowWith tappedAttribute = \(String(describing: self.tappedAttribute))")

        if let attributeClassTapped = tappedAttribute?.attributeClass {
            switch attributeClassTapped {
            case "CIImage": pickImage(tappedAttribute!) // same case as tested by #isImageUI method

//            case "NSNumber":
//            case "CIVector":
//            case "CIColor":
//            case "NSData":
//            case "NSValue":
//            case "NSObject":
//            case "NSString":

                default: Logger(subsystem: LogSubsystem, category: LogCategory).error("attributeClass behavior not implemented for attribute = \(String(describing: self.tappedAttribute))")
            }
        }
    }
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
//        NSLog("PGLSelectParmController tableView didHighlightRowAt: \(indexPath)")
        selectedCellIndexPath = indexPath
        tappedAttribute = getTappedAttribute(indexPath: indexPath)
        appStack.targetAttribute = tappedAttribute
            // pass to the model object refactoring
        if traitCollection.userInterfaceIdiom == .phone {
            imageController?.keepParmSlidersVisible = true
        }

//        NSLog("PGLSelectParmController didHighlightRowAt \(String(describing: tappedAttribute!.attributeName)) \(String(describing: currentFilter!.filterName))")
    }



    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {


        // moved to  PGLImageController -
        imageController?.panner?.isEnabled = false
//         panner?.isEnabled = false // only enable pan gesture on certain cases

//        NSLog("PGLSelectParmController # tableView(..didSelectRowAt tappedAttribute = \(tappedAttribute!.attributeDisplayName)")
        if tappedAttribute == nil { return }
//        if tappedAttribute!.inputParmType() == ImageParm.filter  {
//            // confirm that user wants to break the connection to an input
//            confirmReplaceFilterInput()
//        }
        guard imageController != nil else {
            Logger(subsystem: LogSubsystem, category: LogCategory).error( "PGLImageController ERROR in didSelectRow - imageController is nil")
            return  }

        switch tappedAttribute!.attributeUIType() {
        case AttrUIType.pointUI , AttrUIType.rectUI:

            selectedParmControlView = parmControl(named: (tappedAttribute!.attributeName)!)
                imageController?.selectedParmControlView = selectedParmControlView
            if let thisAttributeName = tappedAttribute!.attributeName {
                imageController?.hideParmControls()
                highlight(viewNamed: thisAttributeName)
                imageController?.toggleViewControls(hide: false,uiTypeToShow: tappedAttribute?.attributeUIType() )
                if let thisCropAttribute = tappedAttribute as? PGLAttributeRectangle {
                    guard let croppingFilter = currentFilter as? PGLRectangleFilter
                    else { return }

                    croppingFilter.cropAttribute = thisCropAttribute
                    guard let activeRectController = imageController?.rectController
                        else {return }
                    activeRectController.thisCropAttribute = thisCropAttribute
                    imageController?.showRectInput(aRectInputFilter: croppingFilter)


                    }
            if let myPanner = imageController?.panner {
                myPanner.isEnabled = true
            }

            }
      case AttrUIType.sliderUI , AttrUIType.integerUI  :
            // replaced by the slider in the tablePaneCell
            // do not show the slider in the image
            imageController?.hideParmControls()
           imageController!.showSliderControl(attribute: tappedAttribute!)


        case AttrUIType.textInputUI :

            imageController?.hideParmControls()
            highlight(viewNamed: tappedAttribute!.attributeName!)




        case AttrUIType.fontUI :
            imageController?.parmSlider.isHidden = true
            imageController?.hideSliders()
            showFontPicker(self)

        case AttrUIType.timerSliderUI:
            // the PGLFilterAttributeNumber has to answer the sliderCell for this to run.. currently commented out 5/16/19

            if let selectedSliderCell = tableView.cellForRow(at: indexPath) as? PGLTableCellSlider {
                selectedSliderCell.sliderControl.isEnabled = true
            }
            imageController?.hideSliders()

//        case AttrUIType.imagePickUI :
            // did the photo or filter cell get touched?
          //  pickImage(tappedAttribute!)
            // now called by swipe action "Pick"

        default:
            highlight(viewNamed: "")
        }

       // this method completes before the processses invoked above run..
        // updates need to be invoked in the completion routines

    // if iPhone then navigate to the imageController to see the parm control

        if (imageController?.keepParmSlidersVisible ?? false) {
            // keepParmSlidersVisible means running on the iPhone

            if tappedAttribute!.attributeUIType() != AttrUIType.timerSliderUI {
                // timerSliderUI is on the parm controller not on the image controller
                // if not timerSliderUI then show the imageController so the parm value can be set

//                splitViewController?.show(.secondary)
                // with the TwoContainer controller do not need to go to imageController
                // it is already showing.
                // 
                
            }
        }

    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if let oldSliderCell = tableView.cellForRow(at: indexPath) as? PGLTableCellSlider {
            oldSliderCell.sliderControl.isEnabled = false
        }
    }
    


    // MARK: Swipe Actions

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // swipe actions  by cell type
        // images support a filter input
        // most other support a Vary & Cancel actions
        // vectors need an OK to complete the vary action
        // rectangles need an OK to complete the location & size of the rect input

        var contextActions = [UIContextualAction]()
        let cellDataAttribute =  filterParms[indexPath.section][indexPath.row]

        let newActionCells = cellDataAttribute.cellAction()
            // newActionCells may be segue, message command, addCell
            // some may have both the message and addCell
        if newActionCells.isEmpty { return nil } //timerCells don't have a vary

        for anActionCell in newActionCells {
            switch anActionCell.cellAction() {
            case .segue:
                let myAction = UIContextualAction(style: .normal, title: anActionCell.swipeLabel) { [weak self] (_, _, completion) in
                    guard let self = self
                        else { return  }
                    // this case for a new cell in the interface
                    self.tappedAttribute = cellDataAttribute
                    Logger(subsystem: LogSubsystem, category: LogCategory).notice("PGLSelectParmController trailingSwipeActionsConfigurationForRowAt tappedAttribute = \(String(describing: self.tappedAttribute))")
                    self.imageController?.hideSliders()

                    if self.tappedAttribute?.inputParmType() == ImageParm.inputChildStack {
                        self.tappedAttribute?.setChildStackMode(inAppStack: self.appStack)
                    }

                    self.performSegue(withIdentifier: cellDataAttribute.segueName() ?? "NoSegue", sender: cellDataAttribute)
                    // this will segue to the filter Stack...should go stackControler.

                    completion(true)
                }
                contextActions.append(myAction)
            case .command:
                let myAction = UIContextualAction(style: .normal, title: anActionCell.swipeLabel) { [weak self] (_, _, completion) in
                    guard let self = self
                        else { return  }
                    if anActionCell.performAction2 {
                        cellDataAttribute.performAction2(self)
                    } else { cellDataAttribute.performAction(self)}
                    self.imageController?.hideSliders()
                    completion(true)
                }
                contextActions.append(myAction)
            case .addCell:
                let myAction = UIContextualAction(style: .normal, title: anActionCell.swipeLabel) { [weak self] (_, _, completion) in
                    // this case for a new cell in the interface
                    guard let self = self
                                           else { return  }
                    self.filterParms[indexPath.section].insert(anActionCell.newSubUIAttribute!, at: (indexPath.row + 1))
                    tableView.insertRows(at: [indexPath], with: .automatic)                // Let the action know it was a success
                    tableView.reloadData()
                    self.imageController?.hideSliders()
                    completion(true)
                }
                 contextActions.append(myAction)
            case .addANDcommand:
                // this case for a new cell in the interface
                let myAction = UIContextualAction(style: .normal, title: anActionCell.swipeLabel) { [weak self] (_, _, completion) in
                    // this case for a new cell in the interface
                    guard let self = self
                                           else { return  }
                    if !cellDataAttribute.hasAnimation() { // already running..
                        self.filterParms[indexPath.section].insert(anActionCell.newSubUIAttribute!, at: (indexPath.row + 1))
                    tableView.insertRows(at: [indexPath], with: .automatic)                // Let the action know it was a success
                    // vary will add uiCell and start the timerAnimation

                        if anActionCell.performDissolveWrapper
                            {
                            Logger(subsystem: LogSubsystem, category: LogCategory).info("PGLSelectParmController #trailingSwipe completion starts #setDissolveWrapper")
                                self.setDissolveWrapper() }
                        else {
                            Logger(subsystem: LogSubsystem, category: LogCategory).info( "PGLSelectParmController #trailingSwipe completion starts performAction")
                                cellDataAttribute.performAction(self)  // run the command

                        }
                        self.imageController?.hideSliders()
                    tableView.reloadData()
                    }
                    completion(true)
                }
                contextActions.append(myAction)
            case .cancel:
                let myAction = UIContextualAction(style: .normal, title: anActionCell.swipeLabel) { [weak self] (_, _, completion) in
                    // cancel needs to remove the timerRate uiCell
                    guard let self = self
                                           else { return  }
                    let cancelPath = IndexPath(row: indexPath.row + 1, section: indexPath.section)
                    let rowCount = self.filterParms[cancelPath.section].count
                    // timer row may not have reloaded..
                    // remove the indented timerRow below this row if it exists
                    if ( rowCount > indexPath.row + 1) {
                         let nextRow = self.filterParms[cancelPath.section][cancelPath.row]
                            if (nextRow.attributeUIType() == AttrUIType.timerSliderUI) {

                                self.filterParms[indexPath.section].remove(at: indexPath.row + 1)
                            tableView.deleteRows(at: [cancelPath], with: .automatic)
                            }
                         }
//                    cellDataAttribute.performAction(self)  // stop the timer which is running even without the timerSliderRow
                        // bad implementation - hidden cancel logic in the vary for Vectors to stop the timers


                    cellDataAttribute.performActionOff() // just stop

                    self.imageController?.hideSliders()
                    tableView.reloadData()
                }
                 contextActions.append(myAction)

            case .unknown:
                Logger(subsystem: LogSubsystem, category: LogCategory).error( "PGLSelectParmController tableView trailingSwipe action fatalError(unknown cell action")
                

            }

        }
        return UISwipeActionsConfiguration(actions: contextActions)
    }

    func cropAction(rectAttribute: PGLAttributeRectangle) {
        imageController?.cropAction(rectAttribute: rectAttribute)
    }

    func hideRectController() {
        if (self.imageController?.rectController) != nil {
            imageController!.hideRectControl()

        }
    }

  


    // MARK: - Segue Navigation
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

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        let segueId = segue.identifier
        Logger(subsystem: LogSubsystem, category: LogNavigation).info("\( String(describing: self) + "-" + #function) + \(String(describing: segueId))")

//        if segueId == "goToImageCollection" {
//            guard let targetImageParm = sender as? PGLFilterAttributeImage
//            else {return}
//            tappedAttribute = targetImageParm
//            if let imageCollectionController = segue.destination as? PGLImageCollectionMasterController {
//                imageCollectionController.inputFilterAttribute = (tappedAttribute as! PGLFilterAttributeImage) // model object
//                imageCollectionController.fetchTopLevel()
//                if(!(tappedAttribute?.inputCollection?.isEmpty() ?? false) ) {
//                    // if the inputCollection has images then
//                    // imageCollectionController should select them
//                    // inputCollection may have multiple albums as input.. highlight all
//
//                }
//            }
//
//        }
        if segueId == "goToFilterViewBranchStack" {
//            if let nextFilterController = (segue.destination as? UINavigationController)?.visibleViewController  as? PGLFilterViewManager
            if segue.destination is PGLMainFilterController
                {
                if tappedAttribute == nil { Logger(subsystem: LogSubsystem, category: LogCategory).error ("tappedAttribute is NIL")}
                else{
                    if tappedAttribute!.hasFilterStackInput() {
                        Logger(subsystem: LogSubsystem, category: LogCategory).info ("pushChildStack - has input")

                        appStack.pushChildStack(tappedAttribute!.inputStack!)
                    }
                    else {
                        Logger(subsystem: LogSubsystem, category: LogCategory).info ("addChildStack - no input")
                        appStack.addChildStackTo(parm: tappedAttribute!) }
                    // Notice the didSet in inputStack: it hooks output of stack to input of the attribute



                }
            }
        return // new
        }

        if segue.identifier == "goToParentParmStack" {
            if segue.destination is PGLSelectParmController { appStack.popToParentStack() }
            postCurrentFilterChange()
        }

        if segue.identifier == "goToParentFilterStack" {
            if segue.destination is PGLMainFilterController { appStack.popToParentStack() }
            postCurrentFilterChange()
        }

    }


    // MARK: Pick Image

//    func pickFilter( _ attribute: PGLFilterAttribute) {
//        // real action handled by the seque to the filterManager.
//        // updates to the values occur on the reload after the filterManager
//
////        Logger(subsystem: LogSubsystem, category: LogCategory).notice("PGLSelectParmController #pickFilter for attribute = \(attribute)")
//
//    }

    func requestAccessReadWrite() -> PHAuthorizationStatus? {
        var myPhotoAccessAuthority: PHAuthorizationStatus?
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            myPhotoAccessAuthority = status

//            Logger(subsystem: LogSubsystem, category: LogNavigation).info("\( String(describing: self) + "-" + #function)")

            }
            // .notDetermined, .denied, .authorized:. .limited:
        return myPhotoAccessAuthority
        }
    
    func pickImage( _ attribute: PGLFilterAttribute) {
        // triggers segue to detail of the collection.
        // "Show" segue
        // goToImageCollection

        let readWriteStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch readWriteStatus {
            case .notDetermined:
                guard let userPermission = requestAccessReadWrite()
                else {
//                    userPhotoAccessAlert()
                       return }
                switch userPermission {
                    case .authorized, .limited :
                        return  // user must open the image pick again
                    // continue to the open picker
                    default:
                        // .notDetermined, .denied, .restricted:
//                        userPhotoAccessAlert()
                        // user must open the image pick again
                    return
                }
            case .denied, .restricted:

                userPhotoAccessAlert()
                return

            case .authorized, .limited :
                // continue to open the picker
                break
            default:
                Logger(subsystem: LogSubsystem, category: LogCategory).error("PGLSelectParmController pickImage fails for unknown authorization status")
                return
                    // unknown new status may be added in a later iOS release
        }
        Logger(subsystem: LogSubsystem, category: LogCategory).notice("PGLSelectParmController #pickImage")

        guard let targetAttribute = self.tappedAttribute as? PGLFilterAttributeImage
            else {  return }

        imagePicker = PGLImageListPicker(targetList: targetAttribute.inputCollection ,controller: self)
        guard let pickerViewController = imagePicker?.set(targetAttribute: targetAttribute)
            else { return }

        if let myParentSplitView = splitViewController {
            /// for getting the cancel/add buttons to work better in the out of process PHPickerView
            myParentSplitView.present(pickerViewController, animated: true) }
        else {
            self.present(pickerViewController, animated: true)
        }

    }

    func userPhotoAccessAlert() {
        let alert = UIAlertController(title: "Rift-Effex Photo Access", message: "Rift-Effex does not have Photo Library access permission. The app is unable to display photos. To change the Photo permission go to Settings -> Privacy -> Photos -> Rift-Effex", preferredStyle: .alert)
        // should set up translation string area

        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in

        }))
        let openSettingsAction = UIAlertAction(title: "Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                // Ask the system to open that URL.
                UIApplication.shared.open(url, options: [:])
                }
            }
        alert.addAction(openSettingsAction)
        self.present(alert, animated: true )
    }

// MARK: PHPickerViewController







    func isFullPhotoLibraryAccess() -> Bool {
        var isFullLibraryAccess = false
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            switch status {
                case .authorized:
                    // The user authorized this app to access Photos data.
                    isFullLibraryAccess = true
                case .notDetermined ,.restricted ,.denied, .limited :
                // one of the following conditions
                // The user hasn't determined this app's access.
                // The system restricted this app's access.
                // The user explicitly denied this app's access.
                // The user authorized this app for limited Photos access.

                    isFullLibraryAccess = false

            @unknown default:
                    isFullLibraryAccess = false
            }
        }
        return isFullLibraryAccess
    }


    func pickerCompletion(pickerController:PHPickerViewController, pickedImageList: PGLImageList) {
        guard let targetAttribute = self.tappedAttribute
            else {  return }
        self.currentFilter?.setUserPick(attribute: targetAttribute, imageList: pickedImageList)


        if let cellPath = targetAttribute.uiIndexPath {
            self.parmsTableView.reloadRows(at: [cellPath], with: .automatic) }
        // gets the parm cell icon updated for an input image
        else { self.parmsTableView.reloadData() }

        if (traitCollection.userInterfaceIdiom) == .phone &&
            (traitCollection.horizontalSizeClass == .compact) {
                // this case just go back to the twoContainer view
        } else {
            // ipad three column
            splitViewController?.show(.secondary)  }
        postCurrentFilterChange() // triggers PGLImageController to set view.isHidden to false
        let updateNotification = Notification(name:PGLRedrawFilterChange)
        NotificationCenter.default.post(name: updateNotification.name, object: nil, userInfo: ["filterHasChanged" : true as AnyObject])
        // clean up.. do not keep  ref to the picker
        pickerController.delegate = nil

    }

        func reloadImageCellIcons() {
            var imageParmCellPaths = [IndexPath]()
            for index in 0..<filterParms[sectionImages].count {
                imageParmCellPaths.append(IndexPath(row: index,section: sectionImages))
            }
            self.parmsTableView.reloadRows(at: imageParmCellPaths, with: .automatic)

        }

//    func loadLimitedImageList(pickerController: PHPickerViewController, results: [PHPickerResult]) -> PGLImageList {
//            // can not use fetchResults from identifiers in limited library mode
//            // assets can not be loaded into the PGLImageList
//            // just load a PGLImageList with the images and the identifiers
//
//            // following code based on Apple example app PHPickerDemo
//        let identifiers = results.compactMap(\.assetIdentifier)
//        let itemProviders = results.map(\.itemProvider)
//
//        Logger(subsystem: LogSubsystem, category: LogSubsystem).info("\( String(describing: self) + "-" + #function)")
//
//        var pickedCIImage: CIImage?
//
//        let selectedImageList = PGLImageList(localIdentifiers: identifiers)
//
//        for item in itemProviders {
//            pickedCIImage = nil // reset on each loop
//            if item.canLoadObject(ofClass: UIImage.self)  {
//                item.loadObject(ofClass: UIImage.self) {[weak self] image, error in
//                    DispatchQueue.main.sync {
//                        if let theImage = image as? UIImage {
//                            if let convertedImage = CoreImage.CIImage(image: theImage ) {
//                                let theOrientation = CGImagePropertyOrientation(theImage.imageOrientation)
//                                if PGLImageList.isDeviceASimulator() {
//                                    pickedCIImage = convertedImage.oriented(CGImagePropertyOrientation.downMirrored)
//                                } else {
//
//                                    pickedCIImage = convertedImage.oriented(theOrientation) }
//                            }
//                            if pickedCIImage != nil {
//                                    // resize to TargetSize same as  imageFrom(selectedAsset:)
//                                    // and loadImageListFromPicker
//                                    //                            if let imageSizedToTarget = self?.resizeToTargetSize(image: pickedCIImage!){
//                                    //                                selectedImageList.appendImage(aCiImage: imageSizedToTarget) }
//                                    //                            else {
//                                    //                                selectedImageList.appendImage(aCiImage: pickedCIImage!)
//                                    //                            }
//                                selectedImageList.appendImage(aCiImage: pickedCIImage!)
//                                Logger(subsystem: LogSubsystem, category: LogSubsystem).info("\( String(describing: self) + "-" + #function) appended ciImage to an imageList")
//                                Logger(subsystem: LogSubsystem, category: LogCategory).debug("pickedCIImage \(pickedCIImage!.debugDescription)")
//
//                            }
//                        }
//                    }
//                }
//            }
//        }
//    }

    func resizeToTargetSize(image: CIImage) -> CIImage {
            // resize to TargetSize same as  imageFrom(selectedAsset:)
            // and loadImageListFromPicker
            // iPhone for imagePicker path...

        let sourceSize = image.extent
        let scaleBy =  TargetSize.height / sourceSize.height
        let aspectRatio = Double(TargetSize.width) / Double(TargetSize.height)

        let resizedImage  = image.applyingFilter("CILanczosScaleTransform", parameters: [kCIInputAspectRatioKey : aspectRatio ,
                    kCIInputScaleKey: scaleBy])
        return resizedImage
    }


    func finishAndUpdate() {
        dismiss(animated: false, completion: nil)
        postCurrentFilterChange()
    }
}

// these extensions from the CGImagePropertyOrientation documentation
// shows how to convert values of the two forms of image orientation (UI and CG/CI)
extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        default: self = .up
        }
    }


}

extension CGImagePropertyOrientation: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
               case .up: return ".up"
               case .upMirrored: return "upMirrored"
               case .down: return ".down"
               case .downMirrored: return ".downMirrored"
               case .left: return ".left"
               case .leftMirrored: return ".leftMirrored"
               case .right: return "right"
               case .rightMirrored: return ".rightMirrored"
               default: return "default .up"
               }
    }
}
extension UIImage.Orientation {
    init(_ cgOrientation: UIImage.Orientation) {
        switch cgOrientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        default: self = .up
        }
    }
}

extension UIImage.Orientation: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
               case .up: return ".up"
               case .upMirrored: return "upMirrored"
               case .down: return ".down"
               case .downMirrored: return ".downMirrored"
               case .left: return ".left"
               case .leftMirrored: return ".leftMirrored"
               case .right: return "right"
               case .rightMirrored: return ".rightMirrored"
               default: return "default .up"
               }
    }
}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}

class PGLTableCellSlider: UITableViewCell {
    
    @IBOutlet weak var sliderControl: UISlider! {
        didSet {
            sliderControl.isEnabled = false
            // enable when the cell is highlighted or selected
        }
    }



func showTextValueInCell(){
        // this class does not show the value of the attribute
        // it displays the value of the slider.
        //
//        detailTextLabel?.text = String(describing: sliderControl.value)
    }
    
}

 
