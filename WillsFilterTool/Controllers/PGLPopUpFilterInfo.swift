//
//  PGLPopUpFilterInfo.swift
//  Surreality
//
//  Created by Will on 3/31/21.
//  Copyright © 2021 Will Loew-Blosser. All rights reserved.
//

import UIKit

class PGLPopUpFilterInfo: UIViewController {

    var filterName: String!
    var textInfo: String!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBOutlet weak var filterLabel: UILabel! {
        didSet {
            filterLabel.text = filterName
        }
    }

    @IBOutlet weak var filterInfoText: UITextView!
    {
        didSet{
            filterInfoText.text = textInfo
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
}
