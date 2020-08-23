//
//  PGLSelectParmController.swift
//  PictureGlance
//
//  Created by Will on 8/13/17.
//  Copyright © 2017 Will. All rights reserved.
//

import UIKit
import simd

enum ImageParm: Int {
    case photo = 0
    case filter = 1
}

enum ParmInput: String {
    case Photo = "Photo"  // implicit raw value of "Photo"
    case Filter = "Filter"
}

let  PGLAttributeAnimationChange = NSNotification.Name(rawValue: "PGLAttributeAnimationChange")

class PGLSelectParmController: UIViewController, UITableViewDelegate, UITableViewDataSource,
             UINavigationControllerDelegate , UIGestureRecognizerDelegate, UISplitViewControllerDelegate
{
    // UITableViewController
//    var parmStackData: () -> PGLFilterStack?  = { PGLFilterStack() }
    // a function is assigned to this var that answers the filterStack
    var myMasterSplitController: PGLSplitViewController?
    var appStack: PGLAppStack!

    var currentFilter: PGLSourceFilter?  {
        didSet {
           let allAttributes = ((currentFilter?.attributes) as! [PGLFilterAttribute])
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

    var scaleFactor: CGFloat = 2.0

    let arrowRightCirclFill = UIImage(systemName: "arrow.right.circle.fill")
    let shiftBtnDown = UIImage(systemName: "arrow.right.circle")

    @IBOutlet weak var parmsTableView: UITableView! {
        didSet{
            parmsTableView.dataSource = self
            parmsTableView.delegate = self
        }
    }

    var timerParm: PGLTimerRateAttributeUI?

    var selectedCellIndexPath: IndexPath?


    @IBOutlet weak var shiftBtn: UIBarButtonItem!

    @IBOutlet weak var toolBarFilterBtn: UIBarButtonItem!



    @IBOutlet weak var filterLabel: UILabel!
    
   

    @IBOutlet weak var upChevron: UIBarButtonItem!

    @IBOutlet weak var downChevron: UIBarButtonItem!


    @IBAction func openChildStackAction(_ sender: UIBarButtonItem) {
        if (tappedAttribute?.hasFilterStackInput())! {
            performSegue(withIdentifier: "filterSegue", sender: tappedAttribute)
            // needs work.. add this in the prepare for segue
        }
    }

    @IBOutlet weak var openParentStack: UIBarButtonItem!

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
                NSLog ("PGLSelectParmController did not set var myimageController")}
        }
    }

    override func viewDidLoad() {
         NSLog ("PGLSelectParmController #viewDidLoad start")
        super.viewDidLoad()

        // Preserves selection between presentations UITableViewController
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()

        // splitController logic
        splitViewController?.delegate = self

        guard let myAppDelegate =  UIApplication.shared.delegate as? AppDelegate
            else { fatalError("AppDelegate not loaded")}
        appStack = myAppDelegate.appStack


        setImageController()

        NSLog ("PGLSelectParmController #viewDidLoad completed")
        navigationController?.isToolbarHidden = false

    }

    
    fileprivate func updateDisplay() {
        // See currentFilter didSet - didSet then triggers the parm updates and adding controls for the parms to the glkView
        // dependent on current filter.
         NSLog ("PGLSelectParmController #updateDisplay start ")
        let viewerStack = appStack.getViewerStack()
        currentFilter = viewerStack.currentFilter()
        navigationItem.title = viewerStack.stackName
        toolBarFilterBtn.title = viewerStack.filterNumLabel(maxLen: 20)
        setShiftBtnState()
            // if only one filter then shift to this filter does not change anything
         NSLog ("PGLSelectParmController #updateDisplay end ")


    }

    func setShiftBtnState() {
                shiftBtn.isEnabled = (appStack.stackRowCount() > 1)
                if (appStack.showFilterImage) {
        //            shiftBtn.image = arrowRightCirclFill
                    shiftBtn.tintColor = .systemBlue
                } else {
        //              shiftBtn.image = arrowRightCirclFill
                    shiftBtn.tintColor =  .systemGray4
                }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NSLog("PGLSelectParmController#viewWillAppear start ")
        if imageController == nil {
            setImageController()}
        setGestureRecogniziers(targetView: (imageController?.view)!) // matches viewDidDisappear removeGesture
        let myCenter =  NotificationCenter.default
        let queue = OperationQueue.main
        var aNotification = myCenter.addObserver(forName: PGLCurrentFilterChange, object: nil , queue: queue) {[weak self]
                    myUpdate in
                    guard let self = self else { return } // a released object sometimes receives the notification
                                  // the guard is based upon the apple sample app 'Conference-Diffable'
                    NSLog("PGLSelectParmController  notificationBlock PGLCurrentFilterChange")
                    self.updateDisplay()
                }
        notifications.append(aNotification)

        

                //PGLAttributeAnimationChange
              aNotification =  myCenter.addObserver(forName: PGLAttributeAnimationChange, object: nil, queue: queue) { [weak self]
                    myUpdate in
                    guard let self = self else { return } // a released object sometimes receives the notification
                                  // the guard is based upon the apple sample app 'Conference-Diffable'
//                    NSLog("PGLSelectParmController  notificationBlock PGLAttributeAnimationChange")
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
        updateDisplay()
        setChevronState()
         NSLog("PGLSelectParmController#viewWillAppear end ")
    }



    override func viewWillDisappear(_ animated: Bool) {
        // remove the parm views and the gesture recogniziers
        removeGestureRecogniziers(targetView: (imageController?.view)!) // matches viewWillAppear setGesture
        imageController?.hideParmControls() // actually will remove the views

        for anObserver in  notifications {
                       NotificationCenter.default.removeObserver(anObserver)
                   }
        notifications = [Any]() // reset

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
    }

    @IBAction func upChevronAction(_ sender: UIBarButtonItem) {
                imageController?.hideParmControls()
               appStack.outputFilterStack().moveActiveBack()
                setChevronState()
               postCurrentFilterChange()
        
    }

    func setChevronState() {
       let myOutputStack = appStack.outputFilterStack()
        if (myOutputStack.activeFilters.count <= 1) {
            // disable both chevrons
            upChevron.isEnabled = false
            downChevron.isEnabled = false
            return
        }
        if myOutputStack.firstFilterIsActive() {
            // on first.. can't go further
            upChevron.isEnabled = false
            downChevron.isEnabled = true
        } else { // check last
            if myOutputStack.lastFilterIsActive() {
                // on last filter can't go further
                upChevron.isEnabled = true
                downChevron.isEnabled = false
            } else {
                // in the middle enable both
                upChevron.isEnabled = true
                downChevron.isEnabled = true
            }
        }
    }

    @IBAction func downChevronAction(_ sender: UIBarButtonItem) {
        imageController?.hideParmControls()
        appStack.outputFilterStack().moveActiveAhead()
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

//        tapper = UITapGestureRecognizer(target: self , action: #selector(PGLSelectParmController.tapAction(_:)))
//        if tapper != nil {
//            tapper?.numberOfTapsRequired = 2 // double tap to activate detectors
//            targetView.addGestureRecognizer(tapper!)
//            tapper!.isEnabled = true
//        }
         // trial effort to get the screen edge to work... did not..
//         myScreenEdgePanGestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action:#selector(PGLSelectParmController.handleScreenEdgePan))
//        myScreenEdgePanGestureRecognizer?.delegate = self
        // Configure the gesture recognizer and attach it to the view.

    }

    func removeGestureRecogniziers(targetView: UIView) {
//        NSLog("PGLSelectParmController #removeGestureRecogniziers")
//        panner = UIPanGestureRecognizer(target: self, action: #selector(PGLSelectParmController.panAction(_:)))
        if panner != nil {
            targetView.removeGestureRecognizer(panner!)
            panner?.removeTarget(self, action: #selector(PGLSelectParmController.panAction(_:)))
            panner = nil
        }

//        tapper = UITapGestureRecognizer(target: self , action: #selector(PGLSelectParmController.tapAction(_:)))
//        if tapper != nil {
//            targetView.removeGestureRecognizer(tapper!)
//            tapper?.removeTarget(self, action: #selector(PGLSelectParmController.tapAction(_:)))
//            tapper = nil
//        }


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
         NSLog("panAction began gesturePoint = \(gesturePoint)")
         NSLog("panAction began tappedControl?.frame.origin  = \(String(describing: tappedControl?.frame.origin))")
                if selectedParmControlView != nil {
                    tappedControl = selectedParmControlView
                 NSLog("panAction began startPoint = \(startPoint)")
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




//        wrapperFilter.internalFilter = currentFilter


        currentFilter?.hasAnimation = false  //  current filter is NOT animating. The wrapper is
        //                currentFilter?.animate(attributeTarget: tappedAttribute!)
        // don't animate the point...
        // the dissolve wrapper handles it
        // the dissolve wrapper gets the
        // increment signal.

        // now the tricky part..
//        currentFilter?.wrapper = wrapperFilter
        // wrapper filter gets an input image on increment from animation
//        wrapperFilter.increment()
        tappedAttribute?.varyState = .DissolveWrapper
    }

//    @objc func tapAction(_ sender: UITapGestureRecognizer) {
    // setDissolveWrapped moved to a cell action for pointUI cells 'Faces' cell
    // comment out the tapAction
//       NSLog("PGLSelectParmController #tapAction Start")
//        if sender.state == .ended {
//            _ = sender.location(in: selectedParmControlView)
//            if tappedAttribute?.isPointUI() ?? false {
//                setDissolveWrapper() // setup all the inputs
//
//                    // if detector is removed.. remove also from the detectors array of the filter.
//
//                attributeValueChanged()
//                postStackChange()
//            }
////            NSLog("PGLSelectParmController #tapAction tapLocation in the rectView = \(tapLocation)")
//
//
//        }
//    }

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
            let flippedVertical = viewHeight - endingPoint.y
            let newVector = parm.mapPoint2Vector(point: endingPoint, viewHeight: viewHeight, scale: scaleFactor)
            parm.set(newVector)
            // or parm.set(oldVector)
            }
        attributeValueChanged()
//        startPoint = CGPoint.zero // reset
//        endPoint = CGPoint.zero
        NSLog("PGLSelectParmController #panEnded startPoint,endPoint reset to CGPoint.zero")

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
        NSLog("parmsListHasChanged - reloadData() start")
        parmsTableView.reloadData()
//        navigationController?.toolbar.setNeedsDisplay()
        //notify the detailimageController that the parms have changed and should show on the image
          NSLog("parmsListHasChanged - reloadData() end")
        if imageController != nil {
            imageController?.setParms(newFilterParms: filterParms[sectionParms])
        }

    }

    func imageViewParmControls() -> [String : UIImageView] {
        // answers dictionary indexed index by attributeName
        return imageController?.parmControls ?? [String : UIImageView]()
    }

    func parmControl(named: String) -> UIImageView? {
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
        for aParmControlTuple in imageViewParmControls() {
            if aParmControlTuple.key == viewNamed {
              aParmControlTuple.value.isHidden = false
                 aParmControlTuple.value.isHighlighted = true

            } else {
                aParmControlTuple.value.isHighlighted = false
                aParmControlTuple.value.isHidden = true
            }

        }
    }

    @IBAction func parmSliderChange(_ sender: UISlider) {
        // later move the logic of sliderValueDidChange to here..
//        sliderValueDidChange(sender)
        // slider in the parmController tableView cell
        if let target = tappedAttribute {
           NSLog("PGLSelectParmController #parmSliderChange target = \(target) value = \(sender.value)")
            target.uiIndexTag = Int(sender.tag)
                // multiple controls for attribute distinguished by tag
                // color red,green,blue for single setColor usage
            let adjustedRate = sender.value / 1000
            target.set(adjustedRate)
        } else { fatalError("tappedAttribute is nil, value can not be changed") }


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
        } else { fatalError("tappedAttribute is nil, value can not be changed") }


        attributeValueChanged()
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
//        let isParmRow = indexPath.section == sectionParms
//        if (isParmRow)
//            {if (parmAttributes.isEmpty)
//                    {return nil }
//                else {return parmAttributes[indexPath.row ] } }
//            else
//            {return imageAttributes[indexPath.row ] }
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

         NSLog("PGLSelectParmController cellForRowAt indexPath = \(indexPath)")
        tappedAttribute = getTappedAttribute(indexPath: indexPath)
//        NSLog("PGLSelectParmController cellForRowAt tappedAttribute = \(tappedAttribute)")
        let cellIdentifier = tappedAttribute?.uiCellIdentifier() ??  "parmNoDetailCell"
//      NSLog("PGLSelectParmController cellForRowAt cellIdentifier = \(cellIdentifier)")
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
//        NSLog("PGLSelectParmController cellForRowAt cell = \(cell)")
        tappedAttribute?.setUICellDescription(cell)
        tappedAttribute?.uiIndexPath = indexPath
        return cell

    }

    // MARK: UITableViewDelegate





//    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
//
//    }


    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        NSLog("accessoryButtonTappedForRowWith indexPath = \(indexPath)")

        tappedAttribute = filterParms[indexPath.section][indexPath.row]  // ERROR is it image or parmAttributes
        NSLog("PGLSelectParmController accessoryButtonTappedForRowWith tappedAttribute = \(String(describing: tappedAttribute))")

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

            default: NSLog("attributeClass behavior not implemented for attribute = \(String(describing: tappedAttribute))")
            }
        }
    }
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        NSLog("PGLSelectParmController tableView didHighlightRowAt: \(indexPath)")
        selectedCellIndexPath = indexPath
        tappedAttribute = getTappedAttribute(indexPath: indexPath)
        NSLog("PGLSelectParmController didHighlightRowAt tappedAttribute = \(String(describing: tappedAttribute))")
    }



    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

         panner?.isEnabled = false // only enable pan gesture on certain cases

        NSLog("PGLSelectParmController # tableView(..didSelectRowAt tappedAttribute = \(tappedAttribute!.attributeDisplayName)")
        if tappedAttribute == nil { return }
//        if tappedAttribute!.inputParmType() == ImageParm.filter  {
//            // confirm that user wants to break the connection to an input
//            confirmReplaceFilterInput()
//        }
      
        switch tappedAttribute!.attributeUIType() {
        case AttrUIType.pointUI , AttrUIType.rectUI:
            var croppingFilter: PGLRectangleFilter?

            panner?.isEnabled = true
            selectedParmControlView = parmControl(named: (tappedAttribute!.attributeName)!)
            if let thisAttributeName = tappedAttribute!.attributeName {
                highlight(viewNamed: thisAttributeName)
                imageController?.parmSlider.isHidden = true
                imageController?.hideSliders()
                if let thisCropAttribute = tappedAttribute as? PGLAttributeRectangle {
                    croppingFilter = currentFilter as? PGLRectangleFilter
                    if croppingFilter != nil {
                        croppingFilter!.cropAttribute = thisCropAttribute

                            // outputExtent closure evaluated in outputImage of the PGLRectangleFilter
                        
                        if  imageController?.rectController != nil {
                            imageController!.rectController!.croppingFilter = croppingFilter
                            imageController!.rectController!.thisCropAttribute = thisCropAttribute
                            imageController!.showCropTintViews(isHidden: false)
                        }


                    } else {
                        NSLog("PGLSelectParmController # tableView(..didSelectRowAt) has PGLFilterAttributeRectangle but fails as PGLCropFilter") }
                } else { // a point
                    // is a detector needed to set the point?
                    // maybe a double tap on the row or double tap on the point? triggers dialog on detector install?

                }
            }
      case AttrUIType.sliderUI , AttrUIType.integerUI  :
            // replaced by the slider in the tablePaneCell
            // do not show the slider in the image

           imageController!.addSliderControl(attribute: tappedAttribute!)
           highlight(viewNamed: tappedAttribute!.attributeName!)
            // enable the slider

        case AttrUIType.timerSliderUI:
            // the PGLFilterAttributeNumber has to answer the sliderCell for this to run.. currently commented out 5/16/19

            if let selectedSliderCell = tableView.cellForRow(at: indexPath) as? PGLTableCellSlider {
                selectedSliderCell.sliderControl.isEnabled = true
            }
            imageController?.hideSliders()
        case AttrUIType.imagePickUI :
            // did the photo or filter cell get touched?
            pickImage(tappedAttribute!)

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
    
//    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
//
//        tappedAttribute = getTappedAttribute(indexPath: indexPath)
//
//        let action = UITableViewRowAction(style: .normal, title: "OK") { (action, path) in
//            NSLog("handler for the row action \(String(describing: action.title)) and \(path)")
//            // all this is too much code.. in the wrong class?
//
//            switch self.tappedAttribute {
//                    case let tappedAttribute as PGLFilterAttributeRectangle:
//                        // if rectController is set then it knows the move or resize mode and the
//                        // resize corner.
//                        // dispatch to rectController
//                        self.cropAction(rectAttribute: tappedAttribute)
//                    case let tappedAttribute as PGLFilterAttributeVector:
//                        tappedAttribute.setVectorEndPoint()
////            case let tappedAttribute as PGLRotateAffineUI:
//
//            default: break
//                    }
//
//        }
//        let action2 = UITableViewRowAction(style: .normal, title: "Cancel") { (action, path) in
//            NSLog("handler for the row action \(String(describing: action.title)) and \(path)")
//            switch self.tappedAttribute {
//            case let tappedAttribute as PGLFilterAttributeNumber :
//
//                self.currentFilter?.attribute(removeAnimationTarget: tappedAttribute)
//            case let tappedAttribute as PGLFilterAttributeVector:
//                tappedAttribute.endVectorPan()
//                self.currentFilter?.attribute(removeAnimationTarget: tappedAttribute)
//                // if animationTime is already running this stops it
//            case let tappedAttribute as PGLRotateAffineUI:
//                self.currentFilter?.attribute(removeAnimationTarget: tappedAttribute)
//            default: self.tappedAttribute?.restoreOldValue()
//            }
//        }
//        let action3 =  UITableViewRowAction(style: .normal, title: "Vary") { (action, path) in
//            NSLog("handler for the row action \(String(describing: action.title)) and \(path)")
//            switch self.tappedAttribute {
//            case let tappedAttribute as PGLFilterAttributeNumber :
//                    self.currentFilter?.attribute(animateTarget: tappedAttribute)
//            case let tappedAttribute as PGLFilterAttributeVector:
//                tappedAttribute.setVectorStartPoint()
//                self.currentFilter?.attribute(animateTarget: tappedAttribute)
//            case let tappedAttribute as PGLFilterAttributeAffine :
//                self.currentFilter?.attribute(animateTarget: tappedAttribute)
//            case let tappedAttribute as PGLRotateAffineUI :
//                self.currentFilter?.attribute(animateTarget: tappedAttribute)
//            default: break
//            }
//            // add indented timer control under this one to control rate of change
////            self.addTimerRateParm(parent: self.tappedAttribute!, path: path)
//
//        }
//        return [action, action2, action3]
//    }

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
                    NSLog("PGLSelectParmController trailingSwipeActionsConfigurationForRowAt tappedAttribute = \(String(describing: self.tappedAttribute))")
                    self.imageController?.hideSliders()

                    self.performSegue(withIdentifier: cellDataAttribute.segueName() ?? "NoSegue", sender: cellDataAttribute)

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
                                NSLog("PGLSelectParmController #trailingSwipe completion starts #setDissolveWrapper")
                                self.setDissolveWrapper() }
                            else {
                               NSLog( "PGLSelectParmController #trailingSwipe completion starts performAction")
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
                    cellDataAttribute.performAction(self)  // stop the timer which is running even without the timerSliderRow
                    self.imageController?.hideSliders()
                    tableView.reloadData()
                }
                 contextActions.append(myAction)

            case .unknown:
                fatalError("unknown cell action")

            }

        }
        return UISwipeActionsConfiguration(actions: contextActions)
    }

//    func addTimerRateParm(parent: PGLFilterAttribute, path: IndexPath) {
//
//        timerParm = PGLTimerRateAttributeUI(pglFilter: parent.aSourceFilter, attributeDict: parent.initDict, inputKey: parent.attributeName!)
//        let newRowPath = IndexPath(row: path.row + 1  , section: path.section)
//            // this makes timerParm take the place of the row + 1 cell
//        parmAttributes.insert(timerParm!, at: newRowPath.row)
//       parmsTableView.beginUpdates()
//
//      parmsTableView.insertRows(at: [newRowPath], with: UITableView.RowAnimation.left)
//       parmsTableView.endUpdates()
//        parmsTableView.reloadData()
//
//
//    }
//    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt: IndexPath) -> UISwipeActionsConfiguration? {
//        let thisAttribute = filterParms[leadingSwipeActionsConfigurationForRowAt.row]
//        switch thisAttribute.attributeClass {
//            //        case "CIImage": pickImage(tappedAttribute!) // same case as tested by #isImageUI method
//
//        case "NSNumber": let varyAction = UIContextualAction(style: .normal, title: "Vary", handler: { _,_,_ in self.currentFilter?.attribute(animateTarget: self.tappedAttribute!)})
//        return UISwipeActionsConfiguration(actions: [varyAction])
//
//            //            case "CIVector":
//            //            case "CIColor":
//            //            case "NSData":
//            //            case "NSValue":
//            //            case "NSObject":
//            //            case "NSString":
//
//        default:  return nil
//        }
//    }

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

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return false
    }
    */


    // MARK: - Segue Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        NSLog("segue from \(segue.identifier)")

        if segue.identifier == "goToImageCollection" {
            
            if let imageCollectionController = segue.destination as? PGLImageCollectionMasterController {
                imageCollectionController.inputFilterAttribute = tappedAttribute as! PGLFilterAttributeImage // model object
                imageCollectionController.fetchTopLevel()
                if(!(tappedAttribute?.inputCollection?.isEmpty() ?? false) ?? false ) {
                    // if the inputCollection has images then
                    // imageCollectionController should select them
                    // inputCollection may have multiple albums as input.. highlight all

                }
            }
        }
        if segue.identifier == "goToFilterViewBranchStack" {
//            if let nextFilterController = (segue.destination as? UINavigationController)?.visibleViewController  as? PGLFilterViewManager
           if let nextFilterController = segue.destination as? PGLFilterTableController
                {
                if tappedAttribute == nil { NSLog ("tappedAttribute is NIL")}
                else{
                    if tappedAttribute!.hasFilterStackInput() {
                        appStack.pushChildStack(tappedAttribute!.inputStack!)
                    }
                    else {
                        appStack.addChildStackTo(parm: tappedAttribute!) }
                    // Notice the didSet in inputStack: it hooks output of stack to input of the attribute



                }
            }
        }

        if segue.identifier == "goToParentParmStack" {
            if let nextParmController = segue.destination as? PGLSelectParmController { appStack.popToParentStack() }
        }

        if segue.identifier == "goToParentFilterStack" {
            if let nextFilterController = segue.destination as? PGLFilterTableController { appStack.popToParentStack() }

        }
        postCurrentFilterChange()
    }


    // MARK: Pick Image

    func pickFilter( _ attribute: PGLFilterAttribute) {
        // real action handled by the seque to the filterManager.
        // updates to the values occur on the reload after the filterManager

        NSLog("PGLSelectParmController #pickFilter for attribute = \(attribute)")
        
    }

    func pickImage( _ attribute: PGLFilterAttribute) {
        // triggers segue to detail of the collection.
         }





    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

    }



    func finishAndUpdate() {
        dismiss(animated: false, completion: nil)
        postCurrentFilterChange()


    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: false, completion: nil)
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

 
