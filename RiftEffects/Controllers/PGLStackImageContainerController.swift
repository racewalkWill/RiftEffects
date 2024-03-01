//
//  PGLStackImageContainerController.swift
//  RiftEffects
//
//  Created by Will on 5/16/22.
//  Copyright © 2022 Will Loew-Blosser. All rights reserved.
//

import UIKit
import os
class PGLStackImageContainerController: PGLTwoColumnSplitController {

    var containerImageController: PGLCompactImageController?
    var containerStackController: PGLStackController?
    
    deinit {
//        releaseVars()
        Logger(subsystem: LogSubsystem, category: LogMemoryRelease).info("\( String(describing: self) + " - deinit" )")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        Logger(subsystem: LogSubsystem, category: LogNavigation).info("\( String(describing: self) + "-" + #function)")
        // Do any additional setup after loading the view.

        setMoreBtnMenu() 

//        navigationItem.title = "Effects"  //viewerStack.stackName

        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        containerStackController = storyboard.instantiateViewController(withIdentifier: "StackController") as? PGLStackController

        containerImageController = storyboard.instantiateViewController(withIdentifier: "PGLImageController") as? PGLCompactImageController
        if (containerImageController == nil) || (containerStackController == nil) {
            return // give up no controller
        }

        loadViewColumns(controller: containerStackController!, imageViewer: containerImageController!)

        // no toolbar on the stackImageContainerController so  toolbar buttons don't show
//        containerStackController?.addToolBarButtons(toController: self)

        setUpdateEditButton()
        updateNavigationBar()
//        setNeedsStatusBarAppearanceUpdate()

        // if the stack is empty go to the addFilter directly
        if containerStackController?.appStack.viewerStack.isEmptyStack() ?? true {
            addFilterBtn(UIBarButtonItem())
        }

    }

    override func viewWillAppear(_ animated: Bool) {
        updateNavigationBar()
    }



    @IBAction func helpBtnClick(_ sender: UIBarButtonItem) {
        containerImageController?.helpBtnAction(sender)
    }

    @IBOutlet weak var randomBtn: UIBarButtonItem!

    @IBAction func randomBtnClick(_ sender: UIBarButtonItem) {
        containerImageController?.randomBtnAction(sender)
        containerStackController?.updateDisplay()
        updateNavigationBar()
    }

    @IBOutlet weak var moreBtn: UIBarButtonItem!

    @IBOutlet weak var newTrashBtn: UIBarButtonItem!

    @IBAction func newTrashBtnAction(_ sender: UIBarButtonItem) {
        containerImageController?.newStackActionBtn(sender)
        updateNavigationBar()
    }

    @IBOutlet weak var recordBtyn: UIBarButtonItem!
    
    @IBAction func recordBtnAction(_ sender: UIBarButtonItem) {
        containerImageController?.recordButtonTapped(controllerRecordBtn:sender)
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
             UIAction(title: "Demo..", image:UIImage(systemName: "pencil.circle")) {
             action in
            self.containerImageController?.loadDemoStack(self.moreBtn)
        },
            UIAction(title: "Save..", image:UIImage(systemName: "pencil")) {
            action in
                // self.saveStackAlert(self.moreBtn)
            self.containerImageController?.saveStackActionBtn(self.moreBtn)
        },

            UIAction(title: "Export to Photos", image:UIImage(systemName: "pencil.circle")) {
            action in
            self.containerImageController?.saveToPhotoLibrary()
        },

            UIAction(title: "Privacy.. ", image:UIImage(systemName: "info.circle")) {
            action in
            self.containerImageController?.displayPrivacyPolicy(self.moreBtn)
        }
        ])
        moreBtn.menu = contextMenu
    }

    func setUpdateEditButton() {

        guard let stackTarget = containerStackController else {
            return
        }
           // update the edit button
           if (stackTarget.tableView.isEditing) {
                    // change to "Done"
                    stackEditBtn!.title = "Done"
           } else {
               stackEditBtn!.title = "Edit" }
    }

    func updateNavigationBar() {
//        self.navigationItem.title = self.appStack.firstStack()?.stackName
//        self.navigationItem.title = "Effects"

        stackEditBtn.isHidden = containerStackController?.appStack.viewerStack.isEmptyStack() ?? true
        setNeedsStatusBarAppearanceUpdate()
    }


    @objc func toggleEditing() {
        guard let myStackTarget = containerStackController else {
            return
        }
        guard let myTableView = myStackTarget.tableView else {
            return
        }
        myTableView.setEditing(!myTableView.isEditing, animated: true)
        setUpdateEditButton()
    }

    @IBAction func addFilterBtn(_ sender: Any) {
        containerStackController?.appStack.setFilterChangeModeToAdd()
        containerStackController?.postFilterNavigationChange()
        performSegue(withIdentifier: "showFilterImageContainer", sender: self)
    }

    @IBAction func stackEditBtn(_ sender: UIBarButtonItem) {
        toggleEditing()
    }
    
    @IBOutlet weak var stackEditBtn: UIBarButtonItem!
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
