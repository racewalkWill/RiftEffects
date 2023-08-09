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

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}

extension PGLStackInfoHeader {

}

