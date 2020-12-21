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

let ExportAlbumId = "ExportAlbumId"
let ExportAlbum = "ExportAlbum"

class PGLImageController: UIViewController, UIDynamicAnimatorDelegate, UINavigationBarDelegate {


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



    // MARK: control Vars


    @IBOutlet weak var parmSlider: UISlider!


    @IBAction func sliderValueEvent(_ sender: UISlider) {
         parmController?.sliderValueDidChange(sender)
    }

    // MARK: Navigation Buttons/Actions

    @IBOutlet var sliders: [UISlider]!


    @IBOutlet weak var saveBtn: UIBarButtonItem!


    @IBOutlet weak var openBtn: UIBarButtonItem!




    // MARK: navBtn Actions

    @IBAction func saveStackActionBtn(_ sender: UIBarButtonItem) {

            saveStackAlert(sender)

    }

    var tintViews = [UIView]()

    func saveStackAlert(_ sender: UIBarButtonItem) {
        var defaultName = String()
        var defaultType = String()
        var defaultAlbumName: String?
        let alertController = UIAlertController(title: NSLocalizedString("Save", comment: ""),
                       message: nil ,
                       preferredStyle: .alert)
        if let targetStack = self.appStack.firstStack() {
            if targetStack.storedStack != nil {
                 defaultName = targetStack.storedStack?.title ?? ""
                defaultType = targetStack.storedStack?.type ?? ""
                defaultAlbumName = targetStack.exportAlbumName // maybe nil
            }
        }
        alertController.addTextField { textField in
            if defaultName.count > 0 {
                textField.text = defaultName
            } else {
            textField.placeholder = NSLocalizedString("Name", comment: "")
            }

        }

        alertController.addTextField { textField in
            if defaultType.count > 0 {
                textField.text = defaultType
            } else {
              textField.placeholder = NSLocalizedString("Type", comment: "")
            }
        }

             alertController.addTextField { textField in
                if  (defaultAlbumName?.count ?? 0 ) > 0 {
                     textField.text = defaultAlbumName }

                 else {
                     textField.placeholder = NSLocalizedString("Optional - export to Photo Album", comment: "")
                 }
         }





        let saveAction = UIAlertAction(title: "Save",
                                style: .default) { (action) in
                           if let targetStack = self.appStack.firstStack() {
                           let titleField = alertController.textFields!.first!
                           let typeField = alertController.textFields![1]
                           let exportAlbumField = alertController.textFields![2]
                           if let title = titleField.text, !title.isEmpty {
                                  // Respond to user selection of the action
                                  targetStack.stackName = title

                               if let myType = typeField.text, !myType.isEmpty {
                                   targetStack.stackType = myType
                                   AppUserDefaults.set(myType, forKey: StackTypeKey)
                               }
                               if let albumName = exportAlbumField.text, !albumName.isEmpty {

                                   targetStack.exportAlbumName = albumName

                               }
                               NSLog("saveAction calls saveToPhotosLibrary")
                            self.appStack.saveStack(metalRender: self.metalController!.metalRender)


                               }
                      }


        }

       let cancelAction = UIAlertAction(title: "Cancel",
                 style: .cancel) { (action) in
                  // do nothing

       }
       alertController.addAction(saveAction)
        alertController.addAction(cancelAction)

       // On iPad, action sheets must be presented from a popover.
       alertController.popoverPresentationController?.barButtonItem = sender
       self.present(alertController, animated: true) {
          // The alert was presented
       }
}



    @IBAction func openStackActionBtn(_ sender: UIBarButtonItem) {
//        let showOpenStackView = true  // change for old or new openDialog
//        if showOpenStackView {
            let saveVC = storyboard!.instantiateViewController(
                withIdentifier: "openStackController")
            let navController = UINavigationController(rootViewController: saveVC)
                                     present(navController, animated: true)

        }

    @IBAction func newStackActionBtn(_ sender: UIBarButtonItem) {
        // confirm user action if current stack is not saved
        // from the trash action button -
        // new means the old one is discarded

        confirmReplaceFilterInput(sender)

        }

    func confirmReplaceFilterInput(_ sender: UIBarButtonItem)  {

        let discardAction = UIAlertAction(title: "Discard",
                  style: .destructive) { (action) in
                    // Respond to user selection of the action
                    let newStack = PGLFilterStack()
                    newStack.setStartupDefault() // not sent in the init.. need a starting point
                    self.appStack.resetToTopStack(newStack: newStack)
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
        NSLog("PGLImageController #doImageCollectionOpen on \(theTop) ")
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
                            NSLog("PGLImageController prepare destination but OPEN..")
                            // use navController and cancel the segue???

                            pictureGrid.userAssetSelection = aUserAssetSelection
                        }
                        else {
                            let userSelectionInfo = PGLUserAssetSelection(assetSources: info)
                            // create a new userSelection
                            pictureGrid.userAssetSelection = userSelectionInfo
                            pictureGrid.title = info.sectionSource.localizedTitle

                            NSLog("PGLImageController #prepare for segue showCollection")
                        }
                            }
                    }
                }
    }

    func updateNavigationBar() {

    }


    // MARK: viewController lifecycle
    
    override func viewLayoutMarginsDidChange() {
//        NSLog("PGLImageController # viewLayoutMarginsDidChange")
        if  (splitViewController?.isCollapsed)! {
            splitViewController?.preferredDisplayMode = UISplitViewController.DisplayMode.oneBesideSecondary
        }

//        hideParmControls()
    }
    override func viewWillLayoutSubviews() {

     navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
        // turns on the full screen toggle button on the left nav bar
        // Do not change the configuration of the returned button.
        // The split view controller updates the button’s configuration and appearance automatically based on the current display mode
        // and the information provided by the delegate object.
        // mode is controlled by targetDisplayModeForAction(in svc: UISplitViewController) -> UISplitViewController.DisplayMode

       navigationItem.leftItemsSupplementBackButton = true
    }


    override func viewDidLoad() {
        // conversion to Metal based on Core Image Programming Guide
        // https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/CoreImaging/ci_tasks/ci_tasks.html#//apple_ref/doc/uid/TP30001185-CH3-SW5
        // see Listing 1-7  Setting up a Metal view for Core Image rendering
        super.viewDidLoad()
//      view has been typed as MTKView in the PGLView subclass
//        and the view assigned in the setter of effectView var


        guard let myAppDelegate =  UIApplication.shared.delegate as? AppDelegate
            else { fatalError("AppDelegate not loaded")}

        appStack = myAppDelegate.appStack
        filterStack = { self.appStack.outputFilterStack() }

        NSLog("PGLImageController #viewdidLoad")

        let myCenter =  NotificationCenter.default
        let queue = OperationQueue.main
        self.view.isHidden = true // use neutral screen not black of the CIImage.empty
        
        myCenter.addObserver(forName: PGLStackChange, object: nil , queue: queue) {[weak self]
            myUpdate in
            guard let self = self else { return } // a released object sometimes receives the notification
                          // the guard is based upon the apple sample app 'Conference-Diffable'
//            NSLog("PGLImageController  notificationBlock PGLStackChange")
            self.updateNavigationBar()
            self.hideParmControls()

            self.view.isHidden = true
            // makes the image go blank after the trash button loads a new stack.
            // set visible again when new images are selected

        }

        myCenter.addObserver(forName: PGLCurrentFilterChange , object: nil , queue: queue) { [weak self]
            myUpdate in
            guard let self = self else { return } // a released object sometimes receives the notification
                          // the guard is based upon the apple sample app 'Conference-Diffable'
            self.filterValuesHaveChanged = true
            self.hideParmControls()
            if (self.view.isHidden ) {
                    self.view.isHidden = false }
                       // needed to refresh the view after the trash creates a new stack.

        }

        myCenter.addObserver(forName: PGLOutputImageChange, object: nil , queue: queue) { [weak self]
            myUpdate in
            guard let self = self else { return } // a released object sometimes receives the notification
                                     // the guard is based upon the apple sample app 'Conference-Diffable'
//           NSLog("PGLImageController  notification PGLOutputImageChange")
            self.filterValuesHaveChanged = true
            //            self.hideParmControls()
            //this causes parm controls to disseapear during imageUpdate.. at 60 fps.. not good :)

        }

        myCenter.addObserver(forName: PGLAttributeAnimationChange , object: nil , queue: queue) { [weak self ]
            myUpdate in
            guard let self = self else { return } // a released object sometimes receives the notification
                          // the guard is based upon the apple sample app 'Conference-Diffable'
            //           NSLog("PGLImageController  notification PGLAttributeAnimationChange")
            self.filterValuesHaveChanged = true

        }

       myCenter.addObserver(forName: PGLImageCollectionOpen, object: nil , queue: OperationQueue.main) { [weak self]
        myUpdate in
        guard let self = self else { return } // a released object sometimes receives the notification
                      // the guard is based upon the apple sample app 'Conference-Diffable'
         NSLog("PGLImageController has  PGLImageCollectionOpen -calls doImageCollectionOpen")
        
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



        filterValuesHaveChanged = true
//        updateDisplay()
        updateNavigationBar()

        tintViews.append(contentsOf: [topTintView, bottomTintView, leftTintView, rightTintView])

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
         appStack.isImageControllerOpen = true
    }

    func viewDidDisappear(animated: Bool) {
        appStack.isImageControllerOpen = false // selection of new image or image list is started
        super.viewDidDisappear(animated)

         NotificationCenter.default.removeObserver(self, name: PGLStackChange, object: self)
         NotificationCenter.default.removeObserver(self, name: PGLOutputImageChange, object: self)
         NotificationCenter.default.removeObserver(self, name: PGLImageCollectionOpen, object: self)
         NotificationCenter.default.removeObserver(self, name: PGLCurrentFilterChange,  object: self)
        NotificationCenter.default.removeObserver(self, name:  PGLAttributeAnimationChange,  object: self)


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
        // set parms with the attributeName as the dictionary key for the filterAttribute
        // what about clearing old  buttons  in updateParmControls?
        parms =  [String : PGLFilterAttribute]()
        for anAttribute in newFilterParms {
            parms[anAttribute.attributeName!] = anAttribute
        }

        updateParmControls()
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
                        if rectController == nil {
                            addRectControl(attribute: rectAttribute) }
                        else {
                            rectController!.view.isHidden = false   // constraints still work?
                        }
                    }
                }
            if parmAttribute.isTextInputUI() {
                addTextInputControl(attribute: parmAttribute)
            }
        }
    }

    func removeParmControls() {
        // should use the attribute methods isPointUI() or isRectUI()..
        for nameAttribute in parms {
            let parmAttribute = nameAttribute.value

            if parmAttribute.isPointUI() || parmAttribute.isTextInputUI() {

                let parmView = parmControls[nameAttribute.key]
                if parmAttribute.isTextInputUI() {
                    if let textInputField = parmView as? UITextField {

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
        NSLog("PGLImageController removeParmControls completed")

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
            newView.frame =  controlFrame
            newView.center = mappedOrigin

            newView.isOpaque = true
            newView.alpha = 0.6
//            newView.tintColor = .systemFill
//            newView.backgroundColor = .systemBackground
            newView.isUserInteractionEnabled = true


            view.addSubview(newView)
            parmControls[attribute.attributeName!] = newView
            newView.isHidden = true
        }
        else {
            NSLog("PGLImageController #addPositionControl fails on no vector value in \(attribute)")}
    }

    func addTextInputControl(attribute: PGLFilterAttribute) {
        // similar to addPositionControl adds text input box for
            // CIAttributedTextImageGenerator inputText,
            // CIAztecCodeGenerator inputMessage
            // CICode128BarcodeGenerator  inputMessage
            // CIPDF417BarcodeGenerator  inputMessage
            // CIQRCodeGenerator  inputMessage inputCorrectionLevel
            // CITextImageGenerator inputText inputFontName
        //
        let textValue = attribute.getValue() as? String // need to put implementations in the above classes
        // put in the center of the control
        let centerPoint = (view.center)
        let boxSize = CGSize(width: 200, height: 40)
        let boxFrame = CGRect(origin: centerPoint, size: boxSize)

        let inputView = UITextField(frame: boxFrame)
        inputView.borderStyle = UITextField.BorderStyle.bezel
        inputView.placeholder = textValue
//        inputView.textColor = UIColor.secondaryLabel
//        inputView.isOpaque = true
        inputView.delegate = parmController
        view.addSubview(inputView)
        parmControls[attribute.attributeName!] = inputView
        inputView.isHidden = true
        NSLog("addTextInputControl attributeValue = \(textValue)")
    }

    var rectController: PGLRectangleController?

    @IBOutlet weak var topTintView: UIView!

    @IBOutlet weak var bottomTintView: UIView!
    @IBOutlet weak var leftTintView: UIView!

    @IBOutlet weak var rightTintView: UIView!




    func addRectControl(attribute: PGLAttributeRectangle) {
        // may remove this method if the type conversion is not needed to get the
        // correct super or subclass implementation of #controlImageView()
        // combine with addPositionControl


            // display the rect with corners for crop move and resize
       rectController =  storyboard!.instantiateViewController(withIdentifier: "RectangleController") as? PGLRectangleController
        if rectController != nil
        {  let newInsetRectFrame = insetRect(fromRect: self.view.bounds)

            rectController!.view.frame = newInsetRectFrame
            rectController!.scaleTransform = myScaleTransform
                // .concatenating(glkScaleTransform) // for mapping the rect vector to the image coordinates
                // combines the scaleFactor of 2.0 with the ULO flip for applying the crop to the glkImage

            NSLog("PGLImageController #addRectControl rectController.scaleTransform = \(String(describing: rectController!.scaleTransform))")

            NSLog("PGLImageController #addRectControl rectController.view.frame inset from bounds = \(view.bounds)")
            NSLog("PGLImageController #addRectControl rectController.view.frame now = \(newInsetRectFrame)")
            let rectCropView = rectController!.view!
            view.addSubview(rectCropView)
            parmControls[attribute.attributeName!] = rectController!.view
                //parmControls = [String : UIView]() - string index by attributeName
            (rectController!.view).isHidden = true


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
        }

    }

    func showCropTintViews(isHidden: Bool) {
        for aTintView in tintViews {
            aTintView.isHidden = isHidden
        }
        if rectController != nil {
            rectController!.setCorners(isHidden: isHidden)
        }
    }
    func hideRectControl() {
        showCropTintViews(isHidden: true)
        if rectController != nil {

            rectController!.view.isHidden = true
//            rectController?.view.removeFromSuperview()
//            rectController = nil

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
            NSLog("PGLImageController addSliderControl \(attribute.description)")
            NSLog("slider min = \(parmSlider.minimumValue) max = \(parmSlider.maximumValue) value = \(parmSlider.value)")

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
        NSLog("PGLImageController #buttonWasPressed attribute = \(String(describing: matchedAttribute))")
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
