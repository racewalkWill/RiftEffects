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

        // an opaque type is returned from addObservor
    var notifications: [NSNotification.Name : Any] = [:]

    deinit {
//        releaseVars()
        Logger(subsystem: LogSubsystem, category: LogMemoryRelease).info("\( String(describing: self) + " - deinit" )")
    }

    override func viewDidLoad() {
        Logger(subsystem: LogSubsystem, category: LogNavigation).info("\( String(describing: self) + "-" + #function)")
        super.viewDidLoad()

        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        containerFilterController = storyboard.instantiateViewController(withIdentifier: "FilterTable") as? PGLMainFilterController

        containerImageController = storyboard.instantiateViewController(withIdentifier: "PGLImageController") as? PGLCompactImageController
        if (containerImageController == nil) || (containerFilterController == nil) {
            return // give up no controller
        }

        addChild(containerImageController!)
        addChild(containerFilterController!)

        guard let filterContainerView = containerFilterController!.view else
            {return     }
        guard let imageContainerView = containerImageController!.view else
            {return     }

        filterContainerView.translatesAutoresizingMaskIntoConstraints = false
        imageContainerView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(imageContainerView)
        view.addSubview(filterContainerView)

//        let spacer = -5.0
        NSLayoutConstraint.activate([
            imageContainerView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            imageContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            imageContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            imageContainerView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 4/3),
                // width to height 4:3 ratio
            filterContainerView.rightAnchor.constraint(equalTo:imageContainerView.leftAnchor, constant:  -30.0),
//            stackContainerView.rightAnchor.constraint(lessThanOrEqualTo: imageContainerView.leftAnchor, constant: -20.0 ),
            filterContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            filterContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30.0),
                // -30 to make room for the bottom toolbar
            filterContainerView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
//            stackContainerView.widthAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 4/3)
            ] )

            // Notify the child view controller that the move is complete.
        containerFilterController?.didMove(toParent: self)
        containerImageController?.didMove(toParent: self)


        setMoreBtnMenu()

//        navigationItem.title = "Filters"//viewerStack.stackName

        navigationController?.isToolbarHidden = true
        // should make the buttons on the filter controller toolbar visible
        // because this controller isToolbarHidden

    }

    override func viewDidDisappear(_ animated: Bool) {
        containerImageController?.releaseVars()
        containerImageController?.removeFromParent()

        containerImageController = nil

        containerFilterController?.removeFromParent()
        containerFilterController = nil
    }

    @IBAction func addFilterBtn(_ sender: UIBarButtonItem) {
        // Segue back to the stackController
        self.navigationController?.popViewController(animated: true)
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

    @IBOutlet weak var recordBtn: UIBarButtonItem!
    
    @IBAction func recordBtnAction(_ sender: UIBarButtonItem) {
        containerImageController?.recordButtonTapped(controllerRecordBtn:sender)
    }
        //MARK: Toolbar buttons actions










    


  
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

        // MARK: - Navigation

        // In a storyboard-based application, you will often want to do a little preparation before navigation
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            // Get the new view controller using segue.destination.
            // Pass the selected object to the new view controller.
            let segueId = segue.identifier

            Logger(subsystem: LogSubsystem, category: LogNavigation).info("\( String(describing: self) + "-" + #function) + \(String(describing: segueId))")

        }

}
