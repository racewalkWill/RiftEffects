//
//  PGLStackInfoHeader.swift
//  RiftEffects
//
//  Created by Will on 8/9/23.
//  Copyright © 2023 Will Loew-Blosser. All rights reserved.
//

import UIKit

class PGLStackInfoHeader: UITableViewCell {

    static let reuseIdentifer = "StackInfoHeader-reuse-identifier"

    static let nibName = "PGLStackInfoHeader"
    
    let containerView = UIView()

    @IBOutlet weak var cellLabel: UILabel!

    @IBOutlet weak var userText: UITextField!

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        resignFirstResponder()
        return true
    }

}


