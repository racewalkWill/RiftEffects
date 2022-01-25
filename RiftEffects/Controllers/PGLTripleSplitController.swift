//
//  PGLTripleSplitController.swift
//  RiftEffects
//
//  Created by Will on 1/21/22.
//  Copyright © 2022 Will Loew-Blosser. All rights reserved.
//

import UIKit

let EffectBtnAction = NSNotification.Name(rawValue: "EffectBtnActionNotification")
let LibraryBtnAction = NSNotification.Name(rawValue: "LibraryBtnActionNotification")

//class PGLTripleSplitController: UIViewController, UINavigationBarDelegate {
extension PGLImageController {


    // MARK: View Lifecycle



    func setupTripleViews() {

//            loadLibraryController()
//            loadEffectController()
//            setLibraryDynamicConstraints()



            let myCenter =  NotificationCenter.default
            let queue = OperationQueue.main


            var aNotification = myCenter.addObserver(forName: EffectBtnAction, object: nil , queue: queue) {[weak self]
                myUpdate in
                guard let self = self else { return }
                self.toggleEffectControllerHidden()
            }
            notifications.append(aNotification)
             aNotification = myCenter.addObserver(forName: LibraryBtnAction, object: nil , queue: queue) {[weak self]
                myUpdate in
                guard let self = self else { return }
                self.toggleLibraryControllerHidden()
            }
            notifications.append(aNotification)



        }

        // MARK: controller loading


        func loadLibraryController() {
            let storyboard = UIStoryboard(name: "Main", bundle: .main)
            guard let newLibController = storyboard.instantiateViewController(identifier: "OpenStackController")   as? PGLOpenStackViewController
            else {return }

                // LibraryController ""


               // Add the view controller to the container.

               addChild(newLibController)
                guard let libraryView = newLibController.view else { return }
        //        fullScreenImageView.frame = view.bounds
                libraryView.translatesAutoresizingMaskIntoConstraints = false

               view.addSubview(libraryView)
               // Create and activate the constraints for the child’s view.
                let viewInset: CGFloat = 20.0
                let
            staticConstraints =
                [
                    libraryView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: viewInset),
                    libraryView.topAnchor.constraint(equalTo: view.topAnchor , constant: 60),
                    // width contstrain will change.. not static
                    // need to fully define with the dynamic constraint too

                    libraryView.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: 0.8 )
                ]


                newLibController.didMove(toParent: self)
                libraryController = newLibController
                NSLayoutConstraint.activate(staticConstraints)
                setLibraryDynamicConstraints()
        }


         func setLibraryDynamicConstraints() {
            hideLibraryConstraints =  [ libraryController.view.widthAnchor.constraint(equalToConstant: 0.0)
                                        ]
             showLibraryConstraints =  [ libraryController.view.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.30)
                                         ]

                // Notify the child view controller that the move is complete.


            libraryDynamicConstraints = hideLibraryController ? hideLibraryConstraints : showLibraryConstraints
            NSLayoutConstraint.activate(libraryDynamicConstraints)
        }

        func setEffectsDynamicConstraints() {
            hideEffectConstraints =  [
                                       effectController.view.leadingAnchor.constraint(greaterThanOrEqualTo: libraryController.view.leadingAnchor, constant: 0.0) ]
            showEffectConstraints =  [
                                       effectController.view.leadingAnchor.constraint(greaterThanOrEqualTo: libraryController.view.trailingAnchor, constant: 0.0) ]

               // Notify the child view controller that the move is complete.
           NSLayoutConstraint.activate(staticConstraints)

            effectDynamicConstraint = hideEffectController ? hideEffectConstraints : showEffectConstraints
           NSLayoutConstraint.activate(effectDynamicConstraint)
       }

        func updateLibraryDynamicConstraints() {
            NSLayoutConstraint.deactivate(libraryDynamicConstraints)
            libraryDynamicConstraints = hideLibraryController ? hideLibraryConstraints : showLibraryConstraints
            NSLayoutConstraint.activate(libraryDynamicConstraints)
            libraryController.view.setNeedsDisplay()

        }

        func updateEffectDynamicConstraints() {
            NSLayoutConstraint.deactivate(effectDynamicConstraint)
            effectDynamicConstraint = hideEffectController ? hideEffectConstraints : showEffectConstraints
            NSLayoutConstraint.activate(effectDynamicConstraint)
            effectController.view.setNeedsDisplay()

        }

        func loadEffectController() {
            let storyboard = UIStoryboard(name: "Main", bundle: .main)
            effectController = storyboard.instantiateViewController(identifier: "StackController")
                                                as? PGLStackController
            if effectController == nil { return  }

               // Add the view controller to the container.

               addChild(effectController)
                guard let effectView = effectController.view else { return }
        //        fullScreenImageView.frame = view.bounds
                effectView.translatesAutoresizingMaskIntoConstraints = false

               view.addSubview(effectView)
               // Create and activate the constraints for the child’s view.

               NSLayoutConstraint.activate(
                [
                    effectView.topAnchor.constraint(equalTo: libraryController.view.topAnchor , constant: 0.0),
                    effectView.widthAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.30),
                    effectView.heightAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.4 ),
                    // need to fully define with the dynamic constraint too
                ]
                )

            // Notify the child view controller that the move is complete.
            effectController.didMove(toParent: self)
            effectView.isHidden = true
//            setEffectsDynamicConstraints()

        }

        // MARK: Button Actions
         func toggleEffectControllerHidden() {
                  // a released object sometimes receives the notification
                  // the guard is based upon the apple sample app 'Conference-Diffable'
                  //            NSLog("PGLImageController  notificationBlock PGLStackChange")

              hideEffectController = !hideEffectController // toggle
             effectController.view.isHidden = hideEffectController
//             updateEffectDynamicConstraints()
    //         effectController.view.setNeedsUpdateConstraints()


          }

         func toggleLibraryControllerHidden() {
                  // a released object sometimes receives the notification
                  // the guard is based upon the apple sample app 'Conference-Diffable'
                  //            NSLog("PGLImageController  notificationBlock PGLStackChange")

              hideLibraryController = !hideLibraryController // toggle
             if !hideLibraryController && view.isHidden {
                 view.isHidden = false
             }
              libraryController.view.isHidden = hideLibraryController
//             updateLibraryDynamicConstraints()
    //         libraryController.view.setNeedsUpdateConstraints()



          }


   

}
   

