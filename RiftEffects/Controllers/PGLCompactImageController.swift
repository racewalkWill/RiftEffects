//
//  PGLCompactImageController.swift
//  RiftEffects
//
//  Created by Will on 2/7/22.
//  Copyright © 2022 Will Loew-Blosser. All rights reserved.
//

import UIKit

class PGLCompactImageController: PGLImageController {

    override func viewDidLoad() {
        super.viewDidLoad()


    }

    @IBAction func stackBtnAction(_ sender: UIBarButtonItem) {
        // not called button removed
        let horizontalSize = traitCollection.horizontalSizeClass
              if horizontalSize == .compact {
                  // trigger the effects controller in a non dimmed popover
                  // as shown in  WWDC21 session ! Customize and Resize Sheets in UIKit
                 guard let stackEffectsController = self.storyboard?.instantiateViewController(withIdentifier: "StackController") else
                 { return }
                  stackEffectsController.modalPresentationStyle = .formSheet  // was .popover
                  stackEffectsController.preferredContentSize = CGSize(width: 350, height: 300.0)
                  if let popover = stackEffectsController.popoverPresentationController {
                      let sheet = popover.adaptiveSheetPresentationController
                      sheet.detents = [.medium(), .large()]
                      sheet.largestUndimmedDetentIdentifier = .medium
                      sheet.prefersScrollingExpandsWhenScrolledToEdge = false
                      sheet.prefersEdgeAttachedInCompactHeight = true
                      sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true

                  }
//                  let navController = UINavigationController(rootViewController: stackEffectsController)
//                  present(navController, animated: true, completion: nil )
//                  let items = stackEffectsController.toolbarItems
//                  NSLog("stack has tool bar items \(items)")
                 present(stackEffectsController, animated: true, completion: nil )
                    // but no nav bar item with the buttons !



              }
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
