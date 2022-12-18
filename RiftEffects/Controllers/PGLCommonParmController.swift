//
//  PGLCommonParmController.swift
//  RiftEffects
//
//  Created by Will on 5/4/22.
//  Copyright © 2022 Will Loew-Blosser. All rights reserved.
//

import Foundation
import UIKit
import os


class PGLCommonController: UIViewController, UIAdaptivePresentationControllerDelegate, UIPopoverPresentationControllerDelegate, UITextFieldDelegate, UIFontPickerViewControllerDelegate {
    // provides single parm logic for both
    // PGLSelectParmController and the PGLImageController

    var appStack: PGLAppStack! {
        // now a computed property
        guard let myAppDelegate =  UIApplication.shared.delegate as? AppDelegate
            else { Logger(subsystem: LogSubsystem, category: LogCategory).fault("PGLSelectParmController viewDidLoad fatalError(AppDelegate not loaded")
            fatalError("PGLSelectParmController could not access the AppDelegate")
        }
       return  myAppDelegate.appStack
    }

    var notifications: [NSNotification.Name : Any] = [:] // an opaque type is returned from addObservor


        // MARK:  UIFontPickerViewControllerDelegate
    func showFontPicker(_ sender: Any) {

      let fontConfig = UIFontPickerViewController.Configuration()
      fontConfig.includeFaces = false
      let fontPicker = UIFontPickerViewController(configuration: fontConfig)
        fontPicker.delegate = self

        if traitCollection.userInterfaceIdiom == .phone {
          fontPicker.modalPresentationStyle = .popover
          fontPicker.preferredContentSize = CGSize(width: 200, height: 350.0)
          // specify anchor point?
          guard let popOverPresenter = fontPicker.popoverPresentationController
          else { return }
//                    popOverPresenter.sourceView = filterCell
          let sheet = popOverPresenter.adaptiveSheetPresentationController //adaptiveSheetPresentationController
          sheet.detents = [.medium(), .large()]
  //        sheet.prefersScrollingExpandsWhenScrolledToEdge = false
          sheet.prefersEdgeAttachedInCompactHeight = true
          sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true


          }
        present(fontPicker, animated: true, completion: nil)
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
//           NSLog("PGLImageController textFieldDidEndEditing ")
            if let target = appStack.targetAttribute {
                if target.isTextInputUI() && reason == .committed {
                // put the new value into the parm
                target.set(textField.text as Any)
                textField.isHidden = true
            }
            }
        }

        internal func textFieldShouldReturn(_ textField: UITextField) -> Bool {

            textField.resignFirstResponder()
            return true
        }

        internal func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
            return true
        }

    func addTextChangeNotification(textAttributeName: String) {

//        NSLog("PGLSelectParmController addTextChangeNotification for \(textAttributeName)")
        let myCenter =  NotificationCenter.default
        let queue = OperationQueue.main
        guard let textField = appStack.parmControls[ textAttributeName ] as? UITextField else
            {return }

        let textNotifier = myCenter.addObserver(forName: UITextField.textDidChangeNotification, object: textField , queue: queue) {[weak self]
            myUpdate in
            guard let self = self else { return } // a released object sometimes receives the notification
                          // the guard is based upon the apple sample app 'Conference-Diffable'
            Logger(subsystem: LogSubsystem, category: LogNavigation).info("PGLCommonController  notificationBlock UITextField.textDidChangeNotification")
            if let target = self.appStack.targetAttribute {
                if target.isTextInputUI()  {
                    // shows changes as they are typed.. no commit reason
                // put the new value into the parm
                    target.set(textField.text as Any)

            }
        }

        }
        notifications[UITextField.textDidChangeNotification] = textNotifier
        // this notification is removed with all the notifications in viewWillDisappear

    }

    //MARK: hide/show parm controls

    func togglePosition(theControlView: UIView, enable: Bool) {
        guard let thePositionView = theControlView as? UIImageView
        else { return }
        if enable {
            thePositionView.isOpaque = true
                //newView.alpha = 0.6 alpha not used when isOpaque == true
            thePositionView.tintColor = .systemFill
            thePositionView.backgroundColor = .systemBackground
        }
        else
        {   thePositionView.isOpaque = false
            thePositionView.alpha = 0.5
            thePositionView.tintColor = .systemBackground
            thePositionView.backgroundColor = .secondarySystemBackground

        }
        theControlView.setNeedsDisplay()
    }

    func highlight(viewNamed: String) {

        // a switch statement might be cleaner
        // both UIImageView and UIControls need to be hidden or shown
        Logger(subsystem: LogSubsystem, category: LogCategory).notice("highlight viewNamed \(viewNamed)")
        for aParmControlTuple in appStack.parmControls {
            if aParmControlTuple.key == viewNamed {
                // show this view
                Logger(subsystem: LogSubsystem, category: LogCategory).debug("highlight view isHidden = false, hightlight = true")
                if let imageControl = (aParmControlTuple.value) as? UIImageView {
//                    imageControl.isHidden = false
                    togglePosition(theControlView: imageControl, enable: true)
                    imageControl.isHighlighted = true
                    Logger(subsystem: LogSubsystem, category: LogCategory).debug("highlight UIImageView isHidden = false, hightlight = true")
                } else {if let viewControl = (aParmControlTuple.value) as? UITextField {
                    viewControl.isHidden = false
                    viewControl.isHighlighted = true
                    viewControl.becomeFirstResponder()
                    Logger(subsystem: LogSubsystem, category: LogCategory).debug("highlight UITextField isHidden = false, hightlight = true")
                    }

                }

            }

        }
    }

}
