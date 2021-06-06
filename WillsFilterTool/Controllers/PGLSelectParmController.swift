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

class PGLSelectParmController: UIViewController, UITableViewDelegate, UITableViewDataSource,
             UINavigationControllerDelegate , UIGestureRecognizerDelegate, UISplitViewControllerDelegate, UITextFieldDelegate,
                UIFontPickerViewControllerDelegate
// PHPickerViewControllerDelegate
{

    // UITableViewController
//    var parmStackData: () -> PGLFilterStack?  = { PGLFilterStack() }
    // a function is assigned to this var that answers the filterStack
    var myMasterSplitController: PGLSplitViewController?
    var appStack: PGLAppStack!

    var currentFilter: PGLSourceFilter?  {
        didSet {
            let allAttributes = ((currentFilter?.attributes)!)
            filterLabel.text = appStack.getViewerStack().filterNumLabel(maxLen: nil) // don't truncate

            filterParms[sectionImages] = allAttributes.filter{ $0.isImageUI() }  //isImageInput
            filterParms[sectionParms]  = allAttributes.filter{ !($0.isImageUI()) } //isImageInput
            filterParms[sectionOther] = [PGLFilterAttribute]()  // no constructor for others
             parmsListHasChanged()
        }
    }

    var filterParms: [[PGLFilterAttribute]] = [[PGLFilterAttribute](), [PGLFilterAttribute](),[PGLFilterAttribute]()]
//    var imageAttributes = [PGLFilterAttribute]()  // attributes for an image - input, background, mask etc..
//    var parmAttributes = [PGLFilterAttribute]()  // not an image - all other parms
//    var valueAttributes = [PGLFilterAttribute]()  // supporting value attributes for parent attibutes

    var tappedAttribute: PGLFilterAttribute?
    let sectionImages = 0
    let sectionParms = 1
    let sectionOther = 2

    var imageController: PGLImageController?
    var usePGLImagePicker = true // false will use the WWDC20 PHPickerViewController image selection
    // waiting for improvments in PHPickerViewController to use albumId to
    // show last user selection
    
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


    var notifications = [Any]() // an opaque type is returned from addObservor


    // MARK: View change
    fileprivate func setImageController() {
        if let glkNavController =  (splitViewController?.viewControllers[1]) as? UINavigationController {
            imageController = glkNavController.visibleViewController as? PGLImageController
            if imageController != nil {
                imageController!.parmController = self

                scaleFactor = imageController!.myScaleFactor // the metalView scaleFactor typically = 2.0
            }
            else {
                Logger(subsystem: LogSubsystem, category: LogCategory).error ("PGLSelectParmController did not set var myimageController")}
        }
    }





    // MARK: View Lifecycle
    override func viewDidLoad() {
        Logger(subsystem: LogSubsystem, category: LogCategory).notice ("PGLSelectParmController #viewDidLoad start")
        super.viewDidLoad()

        splitViewController?.delegate = self

        guard let myAppDelegate =  UIApplication.shared.delegate as? AppDelegate
            else { Logger(subsystem: LogSubsystem, category: LogCategory).fault("PGLSelectParmController viewDidLoad fatalError(AppDelegate not loaded")
            return
        }
        appStack = myAppDelegate.appStack
        navigationItem.title = "Parms"//viewerStack.stackName

        setImageController()

//        NSLog ("PGLSelectParmController #viewDidLoad completed")
        navigationController?.isToolbarHidden = true

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
            setImageController()}
        if let myView = imageController?.view
            { // could be navigation issue
            setGestureRecogniziers(targetView: myView) // matches viewDidDisappear removeGesture
        } else {
            // need to abort this loading... navigation issue -
            // how to abort or recover?
            Logger(subsystem: LogSubsystem, category: LogCategory).fault("PGLSelectParmController viewWillAppear imageController.view not set")
        }
        let myCenter =  NotificationCenter.default
        let queue = OperationQueue.main
        var aNotification = myCenter.addObserver(forName: PGLCurrentFilterChange, object: nil , queue: queue) {[weak self]
                    myUpdate in
                    guard let self = self else { return } // a released object sometimes receives the notification
                                  // the guard is based upon the apple sample app 'Conference-Diffable'
//                    NSLog("PGLSelectParmController  notificationBlock PGLCurrentFilterChange")
                    self.updateDisplay()
                }
        notifications.append(aNotification)

        aNotification = myCenter.addObserver(forName: PGLLoadedDataStack, object: nil , queue: queue) {[weak self]
            myUpdate in
            guard let self = self else { return } // a released object sometimes receives the notification
                          // the guard is based upon the apple sample app 'Conference-Diffable'
            self.navigationController?.popViewController(animated: true)

        }
        
        notifications.append(aNotification)

                //PGLAttributeAnimationChange
              aNotification =  myCenter.addObserver(forName: PGLAttributeAnimationChange, object: nil, queue: queue) { [weak self]
                    myUpdate in
                    guard let self = self else { return } // a released object sometimes receives the notification
                                  // the guard is based upon the apple sample app 'Conference-Diffable'
//                   NSLog("PGLSelectParmController  notificationBlock PGLAttributeAnimationChange")
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
            notifications.append(aNotification)

        aNotification = myCenter.addObserver(forName: PGLReloadParmCell, object: nil , queue: queue) {[weak self]
            myUpdate in
            guard let self = self else { return } // a released object sometimes receives the notification
                          // the guard is based upon the apple sample app 'Conference-Diffable'
            if let attribute = myUpdate.object as? PGLFilterAttribute {
                if let cellPath = attribute.uiIndexPath {
                    self.parmsTableView.reloadRows(at: [cellPath], with: .automatic)
                    }
            }
        }
        notifications.append(aNotification)

        updateDisplay()
        setChevronState()
//         NSLog("PGLSelectParmController#viewWillAppear end ")
    }



    override func viewWillDisappear(_ animated: Bool) {
        // remove the parm views and the gesture recogniziers
        if let theImageControllerView = imageController?.view {
            removeGestureRecogniziers(targetView: theImageControllerView) // matches viewWillAppear setGesture
            imageController?.hideParmControls() // actually will remove the views
            }
        for anObserver in  notifications {
                       NotificationCenter.default.removeObserver(anObserver)
                   }
        notifications = [Any]() // reset
        navigationController?.isToolbarHidden = false

    }

    override func viewDidDisappear(_ animated: Bool) {
        view = nil
//        currentFilter = nil
        tappedAttribute = nil
        appStack = nil

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
        imageController?.hideParmControls()
        appStack.moveActiveAhead() // changes to child if needed
        setChevronState()
        postCurrentFilterChange()

    }
    // MARK: Gestures
    var startPoint = CGPoint.zero
    var endPoint = CGPoint.zero
    var panner: UIPanGestureRecognizer?
//    var tapper: UITapGestureRecognizer?
//    var myScreenEdgePanGestureRecognizer:  UIScreenEdgePanGestureRecognizer?

    func setGestureRecogniziers(targetView: UIView) {
//        NSLog("PGLSelectParmController #setGestureRecogniziers")
        panner = UIPanGestureRecognizer(target: self, action: #selector(PGLSelectParmController.panAction(_:)))
        if panner != nil {
            targetView.addGestureRecognizer(panner!)
            panner!.isEnabled = false
        }

    }

    func removeGestureRecogniziers(targetView: UIView) {
//        NSLog("PGLSelectParmController #removeGestureRecogniziers")
//        panner = UIPanGestureRecognizer(target: self, action: #selector(PGLSelectParmController.panAction(_:)))
        if panner != nil {
            targetView.removeGestureRecognizer(panner!)
            panner?.removeTarget(self, action: #selector(PGLSelectParmController.panAction(_:)))
            panner = nil
        }
    }

    var selectedParmControlView: UIView?
    var tappedControl: UIView?


    @objc func panAction(_ sender: UIPanGestureRecognizer) {
        // should enable only when a point parm is selected.
        let gesturePoint = sender.location(in:  imageController?.view)
        // this changing as an ULO - move down has increased Y

//        NSLog("panAction changed gesturePoint = \(gesturePoint) " )

        // expected that one is ULO and the other is LLO point

        switch sender.state {

        case .began: startPoint = gesturePoint
            endPoint = startPoint // should be the same at began
//         NSLog("panAction began gesturePoint = \(gesturePoint)")
//         NSLog("panAction began tappedControl?.frame.origin  = \(String(describing: tappedControl?.frame.origin))")
                if selectedParmControlView != nil {
                    tappedControl = selectedParmControlView
//                 NSLog("panAction began startPoint = \(startPoint)")
                    if (tappedAttribute as? PGLAttributeRectangle) != nil {
                        if let rectController = imageController?.rectController {
                            let tapLocation = sender.location(in: selectedParmControlView)  // not the same as the location in the myimageController.view
                            if rectController.hitTestCorners(location: tapLocation, controlView: selectedParmControlView!) != nil {
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
        NotificationCenter.default.post(updateFilterNotification)
    }

    func panEnded( endingPoint: CGPoint, parm: PGLFilterAttribute) {
        // add move or resize mode logic
        // tap action should have set the rectController

//        parm.moveTo(startPoint: startPoint, newPoint: endingPoint, inView: (myimageController?.view)!)
            // PGLFilterAttributeRectangle should have empty implementation of moveTo
            // it moves on the OK action not the pan ended

        if let viewHeight = imageController?.view.bounds.height  {
//            let flippedVertical = viewHeight - endingPoint.y
            let newVector = parm.mapPoint2Vector(point: endingPoint, viewHeight: viewHeight, scale: scaleFactor)
            parm.set(newVector)
            // or parm.set(oldVector)
            }
        attributeValueChanged()
//        startPoint = CGPoint.zero // reset
//        endPoint = CGPoint.zero
//        NSLog("PGLSelectParmController #panEnded startPoint,endPoint reset to CGPoint.zero")

    }
    
    func panMoveChange( endingPoint: CGPoint, parm: PGLFilterAttribute) {
        // add move or resize mode logic
        // delta logic - the startPoint is just the previous change method endingPoint
        // also note that startPoint is an instance var. should be parm also, like the ending point??

        switch parm {
        case  _ as PGLAttributeRectangle:
             if let rectController = imageController?.rectController {
                rectController.movingChange(startPoint: startPoint, newPoint: endingPoint, inView: view)
                view.setNeedsLayout()
                
            }
        default:
            tappedControl?.center = endingPoint // this makes the screen update for point
//            parm.movingChange(startPoint: startPoint, newPoint: endingPoint, inView: (myimageController?.view)!)

            if let viewHeight = imageController?.view.bounds.height {
                let flippedVertical = viewHeight - endingPoint.y
                parm.set(CIVector(x: endingPoint.x * scaleFactor , y: flippedVertical * scaleFactor))
                }
        }
        // make the display show this
    }

    func parmsListHasChanged() {
        // notify the tableview & detailimageController to refresh
        Logger(subsystem: LogSubsystem, category: LogCategory).notice("PGLSelectParmController #parmsListHasChanged - reloadData() start")
        parmsTableView.reloadData()
//        navigationController?.toolbar.setNeedsDisplay()
        //notify the detailimageController that the parms have changed and should show on the image
//          NSLog("parmsListHasChanged - reloadData() end")
        if imageController != nil {
            imageController?.setParms(newFilterParms: filterParms[sectionParms])
        }

    }

    func imageViewParmControls() -> [String : UIView] {
        // answers dictionary indexed index by attributeName
        return imageController?.parmControls ?? [String : UIView]()
    }

    func parmControl(named: String) -> UIView? {
        return imageController?.parmControls[named]
    }

    func attributeValueChanged() {
        // put the value of the tappedAttribute into the cell detail text

        if let displayCell = parmsTableView.cellForRow(at: selectedCellIndexPath!),
            let aParmAttribute = tappedAttribute {
            if let aNumberUI = aParmAttribute as? PGLVectorNumeric3UI {
                aNumberUI.postUIChange(attribute: aNumberUI.zValueParent ?? aParmAttribute  )
                // parent should show value changes of the subUI cell
            }
//            NSLog("PGLSelectParmController #attributeValueChanged \(displayCell)")
            showTextValueInCell(aParmAttribute, displayCell)
        }


    }
    func highlight(viewNamed: String) {
        // a switch statement might be cleaner
        // both UIImageView and UIControls need to be hidden or shown
        Logger(subsystem: LogSubsystem, category: LogCategory).notice("highlight viewNamed \(viewNamed)")
        for aParmControlTuple in imageViewParmControls() {
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

    @IBAction func parmSliderChange(_ sender: UISlider) {
        // later move the logic of sliderValueDidChange to here..
//        sliderValueDidChange(sender)
        // slider in the parmController tableView cell
        if let target = tappedAttribute {
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


        attributeValueChanged()
        imageController?.view.setNeedsDisplay()
    }
//    func setRotation(_ sender: UISlider) {
//        if let affineAttribute = tappedAttribute as? PGLFilterAttributeAffine {
//            affineAttribute.setRotation(radians: sender.value)
//        }
//    }
    func colorSliderValueDidChange(_ sender: UISlider) {
        // from the imageController sliderValueDidChange
        //        NSLog("PGLSelectParmController #sliderValueDidChange to \(sender.value)")
        let senderIndex: Int = Int(sender.tag)
        if let colorAttribute = tappedAttribute as? PGLFilterAttributeColor {
            if let aColor = SliderColor(rawValue: senderIndex) {
                let sliderValue = (CGFloat)(sender.value)
                colorAttribute.setColor(color: aColor , newValue: sliderValue  )
                attributeValueChanged()
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


        attributeValueChanged()
        imageController?.view.setNeedsDisplay()
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
        if let target = tappedAttribute {
            if target.isFontUI() {
                let theFont = viewController.selectedFontDescriptor
                target.set(theFont?.postscriptName as Any)
            }

        }
    }

// MARK: UITextFieldDelegate
    // called from the textFields of the ImageController
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        // input text from the imageController
//        NSLog("ParmController textFieldDidEndEditing ")
        if let target = tappedAttribute {
            if target.isTextInputUI() && reason == .committed {
            // put the new value into the parm
            target.set(textField.text as Any)

        }
        }
    }



    // add listener for notification of text change

    func addTextChangeNotification(textAttributeName: String) {
//        NSLog("PGLSelectParmController addTextChangeNotification for \(textAttributeName)")
        let myCenter =  NotificationCenter.default
        let queue = OperationQueue.main
        guard let textField = parmControl(named: textAttributeName) as? UITextField else
            {return }
        let textNotifier = myCenter.addObserver(forName: UITextField.textDidChangeNotification, object: textField , queue: queue) {[weak self]
            myUpdate in
            guard let self = self else { return } // a released object sometimes receives the notification
                          // the guard is based upon the apple sample app 'Conference-Diffable'
//            NSLog("PGLSelectParmController  notificationBlock UITextField.textDidChangeNotification")
            if let target = self.tappedAttribute {
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


    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // the return button is pressed
        return true
    }

    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return true
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
        case sectionOther:
            return "Other"
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
        case sectionOther  :
                rowCount = filterParms[sectionOther].count
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
//        NSLog("PGLSelectParmController didHighlightRowAt \(String(describing: tappedAttribute!.attributeName)) \(String(describing: currentFilter!.filterName))")
    }



    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

         panner?.isEnabled = false // only enable pan gesture on certain cases

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
//            var croppingFilter: PGLRectangleFilter?

            panner?.isEnabled = true
            selectedParmControlView = parmControl(named: (tappedAttribute!.attributeName)!)
            if let thisAttributeName = tappedAttribute!.attributeName {
                highlight(viewNamed: thisAttributeName)
                imageController?.parmSlider.isHidden = true
                imageController?.hideSliders()
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

           imageController!.addSliderControl(attribute: tappedAttribute!)
           highlight(viewNamed: tappedAttribute!.attributeName!)
            // enable the slider

        case AttrUIType.textInputUI :
//                imageController!.addTextInputControl(attribute:  tappedAttribute!)
            // added already in updateParmControls

                highlight(viewNamed: tappedAttribute!.attributeName!)
            addTextChangeNotification(textAttributeName: tappedAttribute!.attributeName!)
            imageController?.parmSlider.isHidden = true
            imageController?.hideSliders()

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
        if let rectController = self.imageController?.rectController {
            let metalView = imageController!.metalController!.view
            let newFrame = rectController.panEnded(startPoint: self.startPoint, newPoint: self.endPoint, inView:(metalView)!)  // or imageController.metalController.view ?
            // panEnded handles both modes of resize or move of the pan action
            // handle the transform coordinates here. Tell the attribute to change the filter to new crop
            // have it save the old vector
            // tell the rectController to unhighlight the filterRect box..

            let glkScaleFactorTransform = imageController!.myScaleTransform
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
        
//        NSLog("segue from \(segue.identifier)")

        if segue.identifier == "goToImageCollection" {
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
        if segue.identifier == "goToFilterViewBranchStack" {
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

    func pickFilter( _ attribute: PGLFilterAttribute) {
        // real action handled by the seque to the filterManager.
        // updates to the values occur on the reload after the filterManager

//        Logger(subsystem: LogSubsystem, category: LogCategory).notice("PGLSelectParmController #pickFilter for attribute = \(attribute)")
        
    }

    func pickImage( _ attribute: PGLFilterAttribute) {
        // triggers segue to detail of the collection.
        // "Show" segue
        // goToImageCollection
        Logger(subsystem: LogSubsystem, category: LogCategory).notice("PGLSelectParmController #pickImage")
        if usePGLImagePicker {
            performSegue(withIdentifier: "goToImageCollection", sender: attribute)
        }
//        else {
            // waiting for improvments in PHPickerViewController to use albumId to
            // show last user selection
//            let photoLibrary = PHPhotoLibrary.shared()
//                   var configuration = PHPickerConfiguration(photoLibrary: photoLibrary)
//                if (currentFilter?.isTransitionFilter() ??  false ) {
//                            configuration.selectionLimit = 0
//                    }
//                   let picker = PHPickerViewController(configuration: configuration)
//                   picker.delegate = self
//                   present(picker, animated: true)
//        }
    }


//    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
//        picker.dismiss(animated: true)
//        // waiting for improvments in PHPickerViewController to use albumId to
//        // show last user selection
//        // obsolete - remove...
//        // now user pick is set in PGLUserAssetSelection.setUserPick
//        //   setUserPick invoked in PGLImagesSelectContainer.viewWillDissappear..
//        //   i.e. when the back navigation occurs
//        let identifiers = results.compactMap(\.assetIdentifier)
//
//        let selectedImageList = PGLImageList(localAssetIDs: identifiers, albumIds: [] )
//
//        guard let targetAttribute = tappedAttribute else {
//            return
//        }
//        currentFilter?.setUserPick(attribute: targetAttribute, imageList: selectedImageList)
//
//    }





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
    
    @IBOutlet weak var sliderControl: UISlider!

func showTextValueInCell(){
        // this class does not show the value of the attribute
        // it displays the value of the slider.
        //
//        detailTextLabel?.text = String(describing: sliderControl.value)
    }
    
}

 
