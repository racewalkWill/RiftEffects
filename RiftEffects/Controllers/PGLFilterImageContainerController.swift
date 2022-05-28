//
//  PGLFilterImageContainerController.swift
//  RiftEffects
//
//  Created by Will on 5/23/22.
//  Copyright © 2022 Will Loew-Blosser. All rights reserved.
//

import UIKit
import os

/// container for Filter and Image controllers side by side
class PGLFilterImageContainerController: UIViewController {

    var containerImageController: PGLCompactImageController?
    var containerFilterController: PGLMainFilterController?

    override func viewDidLoad() {
        Logger(subsystem: LogSubsystem, category: LogNavigation).info("\( String(describing: self) + "-" + #function)")
        super.viewDidLoad()
        if let indexImage = self.children.firstIndex(where: { $0 is PGLCompactImageController }) {
            containerImageController = self.children[indexImage] as? PGLCompactImageController
        }
        if let indexFilter = self.children.firstIndex(where: { $0 is PGLMainFilterController }) {
            containerFilterController = self.children[indexFilter] as? PGLMainFilterController
        }

        setMoreBtnMenu()

        // Do any additional setup after loading the view.
    }


    @IBOutlet weak var embeddedFilterView: UIView!

    @IBOutlet weak var embeddedImageView: UIView!

    @IBAction func addFilterBtn(_ sender: UIBarButtonItem) {
        // Segue back to the stackController
    }

    @IBAction func showImageControllerBtn(_ sender: UIBarButtonItem) {
        // go full screen with the ImageController
        // segue to imageController does the work
    }

    @IBAction func newStackBtnClick(_ sender: UIBarButtonItem) {
        // trash icon to start a new stack
        containerImageController?.newStackActionBtn(sender)
    }
    
    @IBAction func randomBtnClick(_ sender: UIBarButtonItem) {
        containerImageController?.randomBtnAction(sender)

    }
    @IBAction func moreBtnClick(_ sender: UIBarButtonItem) {
        // see the setMoreBtnMenu()

    }

    @IBOutlet weak var moreBtn: UIBarButtonItem!

    @IBOutlet weak var newTrashBtn: UIBarButtonItem!


    @IBAction func helpBtnClick(_ sender: UIBarButtonItem) {
        containerImageController?.helpBtnAction(sender)
        
    }
    @IBOutlet weak var randomBtn: UIBarButtonItem!
    
    // MARK: Menu
    func setMoreBtnMenu() {
            //      if traitCollection.userInterfaceIdiom == .phone {
        let libraryMenu = UIAction.init(title: "Library..", image: UIImage(systemName: "folder"), identifier: PGLImageController.LibraryMenuIdentifier, discoverabilityTitle: "Library", attributes: [], state: UIMenuElement.State.off) {
            action in
            guard let _ = self.containerImageController?.openStackActionBtn(self.moreBtn)
            else { return }
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
                                 children: [ libraryMenu
                                             ,
                                             UIAction(title: "Save..", image:UIImage(systemName: "pencil")) {
            action in
                // self.saveStackAlert(self.moreBtn)
            self.containerImageController?.saveStackActionBtn(self.moreBtn)
        },
                                             UIAction(title: "Save As..", image:UIImage(systemName: "pencil.circle")) {
            action in
            self.containerImageController?.saveStackAsActionBtn(self.moreBtn)
        },
                                             UIAction(title: "Privacy.. ", image:UIImage(systemName: "info.circle")) {
            action in
            self.containerImageController?.displayPrivacyPolicy(self.moreBtn)
        }
                                             //                                ,
                                             //                        UIAction(title: "Reduce size", image:UIImage(systemName: "pencil")) {
                                             //                            action in
                                             //                            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate
                                             //                            else { return }
                                             //                            appDelegate.dataWrapper.build14DeleteOrphanStacks()
                                             //                                    }


                                           ])
        moreBtn.menu = contextMenu
    }

        // MARK: - Navigation

        // In a storyboard-based application, you will often want to do a little preparation before navigation
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            // Get the new view controller using segue.destination.
            // Pass the selected object to the new view controller.
            let segueId = segue.identifier

            Logger(subsystem: LogSubsystem, category: LogNavigation).info("\( String(describing: self) + "-" + #function) + \(String(describing: segueId))")

            switch segueId {
                case "embedImageController" :

                    guard let destination = segue.destination  as? PGLCompactImageController
                        else { return  }
                    containerImageController = destination

                case "embedMainFilterController" :
                    guard let parmDestination = segue.destination as? PGLMainFilterController
                        else { return }
                    containerFilterController = parmDestination

                default: return
            }

        }

}
