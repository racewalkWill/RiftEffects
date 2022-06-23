//
//  PGLStackImageContainerController.swift
//  RiftEffects
//
//  Created by Will on 5/16/22.
//  Copyright © 2022 Will Loew-Blosser. All rights reserved.
//

import UIKit
import os
class PGLStackImageContainerController: UIViewController {

    var containerImageController: PGLCompactImageController?
    var containerStackController: PGLStackController?

    override func viewDidLoad() {
        super.viewDidLoad()
        Logger(subsystem: LogSubsystem, category: LogNavigation).info("\( String(describing: self) + "-" + #function)")
        // Do any additional setup after loading the view.

        setMoreBtnMenu() 

        navigationItem.title = "Effects"  //viewerStack.stackName

        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        containerStackController = storyboard.instantiateViewController(withIdentifier: "StackController") as? PGLStackController

        containerImageController = storyboard.instantiateViewController(withIdentifier: "PGLImageController") as? PGLCompactImageController
        if (containerImageController == nil) || (containerStackController == nil) {
            return // give up no controller
        }

        addChild(containerImageController!)
        addChild(containerStackController!)

        guard let stackContainerView = containerStackController!.view else
            {return     }
        guard let imageContainerView = containerImageController!.view else
            {return     }

        stackContainerView.translatesAutoresizingMaskIntoConstraints = false
        imageContainerView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(imageContainerView)
        view.addSubview(stackContainerView)


//        let spacer = -5.0
        NSLayoutConstraint.activate([
            imageContainerView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            imageContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            imageContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            imageContainerView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 4/3),
                // width to height 4:3 ratio
            stackContainerView.rightAnchor.constraint(equalTo:imageContainerView.leftAnchor, constant:  -30.0),
//            stackContainerView.rightAnchor.constraint(lessThanOrEqualTo: imageContainerView.leftAnchor, constant: -20.0 ),
            stackContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            stackContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            stackContainerView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
//            stackContainerView.widthAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 4/3)
            ] )

            // Notify the child view controller that the move is complete.
        containerStackController?.didMove(toParent: self)
        containerImageController?.didMove(toParent: self)

        containerStackController?.addToolBarButtons(toController: self)

        configureNavigationItem()
//        setNeedsStatusBarAppearanceUpdate()

    }


    @IBAction func containerAddFilter(_ sender: UIBarButtonItem) {

        containerStackController?.appStack.setFilterChangeModeToAdd()
        containerStackController?.postFilterNavigationChange()
        performSegue(withIdentifier: "showFilterImageContainer", sender: self)
        // chooses new filter

    }

    @IBAction func helpBtnClick(_ sender: UIBarButtonItem) {
        containerImageController?.helpBtnAction(sender)
    }

    @IBOutlet weak var randomBtn: UIBarButtonItem!

    @IBAction func randomBtnClick(_ sender: UIBarButtonItem) {
        containerImageController?.randomBtnAction(sender)
        containerStackController?.updateDisplay()
    }

    @IBOutlet weak var moreBtn: UIBarButtonItem!

    @IBOutlet weak var newTrashBtn: UIBarButtonItem!

    @IBAction func newTrashBtnAction(_ sender: UIBarButtonItem) {
        containerImageController?.newStackActionBtn(sender)
    }


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

    func configureNavigationItem() {


        guard let stackTarget = containerStackController else {
            return
        }
        var currentLeftButtons = navigationItem.leftBarButtonItems
        guard let leftButtonCount = currentLeftButtons?.count
        else { return }
        switch leftButtonCount {
            case 2:
                let editingItem = UIBarButtonItem(title: stackTarget.tableView.isEditing ? "Done" : "Edit", style: .plain, target: self, action: #selector(toggleEditing))
                currentLeftButtons?.append(editingItem)
                navigationItem.leftBarButtonItems = currentLeftButtons

                navigationController?.isToolbarHidden = false
            case 3:
                if (stackTarget.tableView.isEditing) {
                    // change to "Done"
                    currentLeftButtons?[2].title = "Done"
                } else {
                    currentLeftButtons?[2].title = "Edit"
                }
            default:
                return
        }
    }

    @objc
    func toggleEditing() {
        guard let myStackTarget = containerStackController else {
            return
        }
        guard let myTableView = myStackTarget.tableView else {
            return
        }
        myTableView.setEditing(!myTableView.isEditing, animated: true)
        configureNavigationItem()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
