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
             UISplitViewControllerDelegate,
            PHPickerViewControllerDelegate

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
            filterParms[sectionParms]  = allAttributes.filter{ !($0.isImageUI()) } //isImageInput
//            filterParms[sectionOther] = [PGLFilterAttribute]()  // no constructor for others
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
    
    var usePGLImagePicker = (UITraitCollection.current.userInterfaceIdiom == .pad)
        // false will use the WWDC20 PHPickerViewController image selection
        // true - iPad uses PGLImagePicker which tracks the album source of the picked image

//    var picker: PHPickerViewController?
    
    var scaleFactor: CGFloat = 2.0

//    let arrowRightCirclFill = UIImage(systemName: "arrow.right.circle.fill")
//    let shiftBtnDown = UIImage(systemName: "arrow.right.circle")

    @IBOutlet weak var parmsTableView: UITableView! {
        didSet{
            parmsTableView.dataSource = self
            parmsTableView.delegate = self
        }
    }

    var timerParm: PGLTimerRateAttributeUI?

    var selectedCellIndexPath: IndexPath?


    @IBAction func backButtonAction(_ sender: UIBarButtonItem) {
//        let actionAccepted = Notification(name: PGLImageNavigationBack )
//               NotificationCenter.default.post(actionAccepted)
        if (traitCollection.horizontalSizeClass == .compact)
        { // now in the twoContainer mode on the iphone
            // navigation pop needs to trigger the parent popViewController
            // so that it moves back to the stack controller
            guard let myNav = self.navigationController else { return }

            guard let myParent = myNav.topViewController as? PGLParmImageController
                else { myNav.popViewController(animated: true )
                        return
            }
            guard let myStackController = myNav.viewControllers[1] as? PGLStackController else {
                myNav.popViewController(animated: true )
                return
            }
            self.navigationController?.popToViewController(myStackController, animated: true)
        }
        else {
            // move back to the stack controller
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
            navigationController?.isToolbarHidden = true } // was true
        // don't hide if iPhone
     

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
                  Logger(subsystem: LogSubsystem, category: LogNavigation).info("PGLSelectParmController  notificationBlock PGLAttributeAnimationChange")
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


//        let deviceIdom = traitCollection.userInterfaceIdiom
//        if deviceIdom == .pad {
////            imageController?.removeGestureRecogniziers()
//            // the imageController may have pan controls showing.
//
//            imageController?.hideParmControls() // just hides the UI controls
//        } else {
//
////                imageController?.keepParmSlidersVisible = true
//            // this is now controlled by the highlight action and the select
//            // which triggers navigation to the imageController for
//            // manipulation of the parm values with a slider or point.
//
//        }
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

    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func postStackChange() {

           let stackNotification = Notification(name:PGLStackChange)
           NotificationCenter.default.post(stackNotification)
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
//    var startPoint = CGPoint.zero
//    var endPoint = CGPoint.zero
//    var panner: UIPanGestureRecognizer?
//    var tapper: UITapGestureRecognizer?
//    var myScreenEdgePanGestureRecognizer:  UIScreenEdgePanGestureRecognizer?

//    func setGestureRecogniziers(targetView: UIView) {
////        NSLog("PGLSelectParmController #setGestureRecogniziers")
//        panner = UIPanGestureRecognizer(target: self, action: #selector(PGLSelectParmController.panAction(_:)))
//        if panner != nil {
//            targetView.addGestureRecognizer(panner!)
//            panner!.isEnabled = false
//        }
//
//    }
//
//    func removeGestureRecogniziers(targetView: UIView) {
////        NSLog("PGLSelectParmController #removeGestureRecogniziers")
////        panner = UIPanGestureRecognizer(target: self, action: #selector(PGLSelectParmController.panAction(_:)))
//        if panner != nil {
//            targetView.removeGestureRecognizer(panner!)
//            panner?.removeTarget(self, action: #selector(PGLSelectParmController.panAction(_:)))
//            panner = nil
//        }
//    }

    var selectedParmControlView: UIView?
    var tappedControl: UIView?


//    @objc func panAction(_ sender: UIPanGestureRecognizer) {
//
//        // moved to ImageController REMOVE this
//
//        // should enable only when a point parm is selected.
//        let gesturePoint = sender.location(in:  imageController?.view)
//        // this changing as an ULO - move down has increased Y
//
////        NSLog("panAction changed gesturePoint = \(gesturePoint) " )
//
//        // expected that one is ULO and the other is LLO point
//
//        switch sender.state {
//
//        case .began: startPoint = gesturePoint
//            endPoint = startPoint // should be the same at began
////         NSLog("panAction began gesturePoint = \(gesturePoint)")
////         NSLog("panAction began tappedControl?.frame.origin  = \(String(describing: tappedControl?.frame.origin))")
//                if selectedParmControlView != nil {
//                    tappedControl = selectedParmControlView
////                 NSLog("panAction began startPoint = \(startPoint)")
//                    if (tappedAttribute as? PGLAttributeRectangle) != nil {
//                        if let rectController = imageController?.rectController {
//                            let tapLocation = sender.location(in: selectedParmControlView)  // not the same as the location in the myimageController.view
//                            if rectController.hitTestCorners(location: tapLocation, controlView: selectedParmControlView!) != nil {
////                                NSLog("PGLSelectParmController #panAction found hit corner = \(tappedCorner)")
//
//                            }
//                        }
//                    }
//
//
//                }
//
//        case .ended:
//                endPoint = gesturePoint
//                if tappedAttribute != nil {panEnded(endingPoint:  endPoint, parm: tappedAttribute!) }
//                tappedControl = nil
//
//        case .changed:
//                    startPoint = endPoint // of last changed message .. just process the delta
//                    endPoint = gesturePoint
//                    tappedControl?.center = gesturePoint
//                    if tappedAttribute != nil {panMoveChange(endingPoint:  endPoint, parm: tappedAttribute!) }
//
////           NSLog("panAction changed NOW tappedControl?.frame.origin  = \(String(describing: tappedControl?.frame.origin))")
//            case .cancelled, .failed:
//                tappedControl = nil
//
//            case .possible: break
//            default: break
//
//        }
//    }

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

//    func panEnded( endingPoint: CGPoint, parm: PGLFilterAttribute) {
//        ""
//        // REMOVE
//        // add move or resize mode logic
//        // tap action should have set the rectController
//
////        parm.moveTo(startPoint: startPoint, newPoint: endingPoint, inView: (myimageController?.view)!)
//            // PGLFilterAttributeRectangle should have empty implementation of moveTo
//            // it moves on the OK action not the pan ended
//
//        if let viewHeight = imageController?.view.bounds.height  {
////            let flippedVertical = viewHeight - endingPoint.y
//            let newVector = parm.mapPoint2Vector(point: endingPoint, viewHeight: viewHeight, scale: scaleFactor)
//            parm.set(newVector)
//            // or parm.set(oldVector)
//            }
//        attributeValueChanged()
////        startPoint = CGPoint.zero // reset
////        endPoint = CGPoint.zero
////        NSLog("PGLSelectParmController #panEnded startPoint,endPoint reset to CGPoint.zero")
//
//    }
    
//    func panMoveChange( endingPoint: CGPoint, parm: PGLFilterAttribute) {
//
//        // add move or resize mode logic
//        // delta logic - the startPoint is just the previous change method endingPoint
//        // also note that startPoint is an instance var. should be parm also, like the ending point??
//
//        switch parm {
//        case  _ as PGLAttributeRectangle:
//             if let rectController = imageController?.rectController {
//                rectController.movingChange(startPoint: startPoint, newPoint: endingPoint, inView: view)
//                view.setNeedsLayout()
//
//            }
//        default:
//            tappedControl?.center = endingPoint // this makes the screen update for point
////            parm.movingChange(startPoint: startPoint, newPoint: endingPoint, inView: (myimageController?.view)!)
//
//            if let viewHeight = imageController?.view.bounds.height {
//                let flippedVertical = viewHeight - endingPoint.y
//                parm.set(CIVector(x: endingPoint.x * scaleFactor , y: flippedVertical * scaleFactor))
//                }
//        }
//        // make the display show this
//    }

    func parmsListHasChanged() {
        // notify the tableview & detailimageController to refresh
        Logger(subsystem: LogSubsystem, category: LogCategory).notice("PGLSelectParmController #parmsListHasChanged - reloadData() start")
        parmsTableView.reloadData()
//        navigationController?.toolbar.setNeedsDisplay()
        //notify the detailimageController that the parms have changed and should show on the image
//          NSLog("parmsListHasChanged - reloadData() end")

        appStack.currentFilter = currentFilter
        appStack.setParms(newFilterParms: filterParms[sectionParms])
       imageController?.updateParmControls()
            // MARK: appStackParmRefactor
           


    }

    func imageViewParmControls() -> [String : UIView] {
        // answers dictionary indexed index by attributeName

        return appStack.parmControls
    }

    func parmControl(named: String) -> UIView? {

        return appStack.parmControls[named]
    }

//    func attributeValueChanged() {
//
//        // put the value of the tappedAttribute into the cell detail text
//        // refactor comment - NOT used remove
////        if let displayCell = parmsTableView.cellForRow(at: selectedCellIndexPath!),
////            let aParmAttribute = tappedAttribute {
////            if let aNumberUI = aParmAttribute as? PGLVectorNumeric3UI {
////                aNumberUI.postUIChange(attribute: aNumberUI.zValueParent ?? aParmAttribute  )
////                // parent should show value changes of the subUI cell
////            }
//////            NSLog("PGLSelectParmController #attributeValueChanged \(displayCell)")
////            showTextValueInCell(aParmAttribute, displayCell)
////        }
//
//
//    }


    @IBAction func parmSliderChange(_ sender: UISlider) {

        // later move the logic of sliderValueDidChange to here..
//        sliderValueDidChange(sender)
        // slider in the parmController tableView cell
        // Need to ensure that the cell containing the slider control is highlighted
        // i.e. tappedAttribute is the parmSliderInputCell
        // timer slider is enabled when the cell is selected
        // see DidSelectRowAt for the TimerSliderUI case where it is enable

        if let target = appStack.targetAttribute {
            Logger(subsystem: LogSubsystem, category: LogCategory).debug("PGLSelectParmController #parmSliderChange  value = \(sender.value)")
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

        Logger(subsystem: LogSubsystem, category: LogCategory).info("PGLSelectParmController cellForRowAt indexPath = \(indexPath)")
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
            imageController?.hideParmControls()
            if let myPanner = imageController?.panner {
                myPanner.isEnabled = true
            }

            selectedParmControlView = parmControl(named: (tappedAttribute!.attributeName)!)
                imageController?.selectedParmControlView = selectedParmControlView
            if let thisAttributeName = tappedAttribute!.attributeName {
                highlight(viewNamed: thisAttributeName)

                if let thisCropAttribute = tappedAttribute as? PGLAttributeRectangle {
                    guard let croppingFilter = currentFilter as? PGLRectangleFilter
                    else { return }

                    croppingFilter.cropAttribute = thisCropAttribute
                    guard let activeRectController = imageController?.rectController
                        else {return }
                    activeRectController.thisCropAttribute = thisCropAttribute
                    imageController?.showRectInput(aRectInputFilter: croppingFilter)


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
                        self.appStack.pushChildStack((self.tappedAttribute?.inputStack)!)
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

        if segueId == "goToImageCollection" {
            guard let targetImageParm = sender as? PGLFilterAttributeImage
            else {return}
            tappedAttribute = targetImageParm
            if let imageCollectionController = segue.destination as? PGLImageCollectionMasterController {
                imageCollectionController.inputFilterAttribute = (tappedAttribute as! PGLFilterAttributeImage) // model object
                imageCollectionController.fetchTopLevel()
                if(!(tappedAttribute?.inputCollection?.isEmpty() ?? false) ) {
                    // if the inputCollection has images then
                    // imageCollectionController should select them
                    // inputCollection may have multiple albums as input.. highlight all

                }
            }

        }
        if segueId == "goToFilterViewBranchStack" {
//            if let nextFilterController = (segue.destination as? UINavigationController)?.visibleViewController  as? PGLFilterViewManager
            if segue.destination is PGLFilterTableController
                {
                if tappedAttribute == nil { Logger(subsystem: LogSubsystem, category: LogCategory).error ("tappedAttribute is NIL")}
                else{
                    if tappedAttribute!.hasFilterStackInput() {
                        appStack.pushChildStack(tappedAttribute!.inputStack!)
                    }
                    else {
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
            if segue.destination is PGLFilterTableController { appStack.popToParentStack() }
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

    func pickImage( _ attribute: PGLFilterAttribute) {
        // triggers segue to detail of the collection.
        // "Show" segue
        // goToImageCollection


        Logger(subsystem: LogSubsystem, category: LogCategory).notice("PGLSelectParmController #pickImage")
        if usePGLImagePicker {
            performSegue(withIdentifier: "goToImageCollection", sender: attribute)
        }
        else {
//             waiting for improvments in PHPickerViewController to use albumId to
//             show last user selection
//            if picker == nil
//                { picker = initPHPickerView() }
            let picker = initPHPickerView()

            //PHPickerViewController documentation says 'You can present a picker object only once; you can’t reuse it across sessions'
            // there must be a ref back into this process from the picker.. use the same picker
            // if in the same view works BUT
            // navigation from the effects (filter) causes the error
//                  Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason: 'Picker's configuration is not a valid configuration.'

            if picker != nil {
                present(picker!, animated: true) }


        }
    }

    func initPHPickerView() -> PHPickerViewController? {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        if (currentFilter?.isTransitionFilter() ??  false ) {
            configuration.selectionLimit = 0
        } else {
            configuration.selectionLimit = 1
        }
                // Set the selection behavior to respect the user’s selection order.
        configuration.filter = .images
        configuration.preferredAssetRepresentationMode = .automatic
        configuration.selection = .ordered

        // 2022-03-30 give up trying to show the old selection in the PHPickerViewController.
        //  keeps throwing crashes with 'invalid preselected asset identifiers
        //   {( "595AF8D6-A8B9-4505-A7EA-AE6FBEAA9B6E/L0/001")}

//        let targetAttribute = self.tappedAttribute

//        var existingSelectionIDs: [String] = targetAttribute?.inputCollection?.assetIDs ?? [String]()
//        existingSelectionIDs.removeAll( where: {
//                 $0.hasPrefix("(null)/")   // "(null)/L0/001" is error string
//            })
//        configuration.preselectedAssetIdentifiers = existingSelectionIDs
        // config will hold onto the existingSelection if the user opens it again

        let myPicker = PHPickerViewController(configuration: configuration)
        myPicker.delegate = self
        return myPicker
    }


    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        // waiting for improvments in PHPickerViewController to use albumId to
        // show last user selection

        //   setUserPick invoked in PGLImagesSelectContainer.viewWillDissappear..
        //   i.e. when the back navigation occurs

        // logic that seems to work with out a 'NSInternalInconsistencyException', reason: 'Invalid parameter not satisfying: assetUUID'
        // for each object in the fetchResult  execute the  PHImageManager.default().requestImage
        // then create the PGLAsset and the PGLImageList
        // creating PGLAsset and PGLImageList first and using the asset has the failure



        let identifiers = results.compactMap(\.assetIdentifier)
//        let itemProviders = results.map(\.itemProvider)

        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
        NSLog("didFinish identifiers = \(identifiers) in fetchResult \(fetchResult)")


        var images = [CIImage]()
        var pickedCIImage: CIImage?

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.isSynchronous = true

        for aFetchedImageObject in fetchResult.objects {
            PHImageManager.default().requestImage(for: aFetchedImageObject  , targetSize: TargetSize, contentMode: .aspectFit, options: options, resultHandler: { image, info in
                    if let error =  info?[PHImageErrorKey]
                     { NSLog( "PGLImageList imageFrom error = \(error)") }
                    else {
                        guard let theImage = image else { return  }
                        if let convertedImage = CoreImage.CIImage(image: theImage ) {
                            let theOrientation = CGImagePropertyOrientation(theImage.imageOrientation)
                            if PGLImageList.isDeviceASimulator() {
                                    pickedCIImage = convertedImage.oriented(CGImagePropertyOrientation.downMirrored)
                                } else {

                                    pickedCIImage = convertedImage.oriented(theOrientation) }
                            }
                        if pickedCIImage != nil {
                            images.append(pickedCIImage!)
                        }
                    }
            } )
        }
        var assets = [PGLAsset]()
        for index in 0 ..< identifiers.count {
            let anNewPGLAsset = PGLAsset(sourceAsset: fetchResult.object(at: index))
            assets.append(anNewPGLAsset)
            }
        guard let targetAttribute = self.tappedAttribute
            else {  return }

        let selectedImageList = PGLImageList(localPGLAssets: assets)
            // with the PKPickerViewController.. the asset.LocalIdentifier gets niled on the second use
            // it should have carried into the localPGLAssets assigment but .. something happens internally
            // also set the imageList assetIDs directly to match the images array
        selectedImageList.assetIDs = identifiers
        selectedImageList.setImages(ciImageArray: images)

        self.currentFilter?.setUserPick(attribute: targetAttribute, imageList: selectedImageList)


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
        
        // clean up.. do not keep  ref to the picker
        picker.delegate = nil



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

 
