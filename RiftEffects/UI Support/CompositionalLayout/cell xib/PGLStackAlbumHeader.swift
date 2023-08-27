//
//  PGLStackAlbumHeader.swift
//  RiftEffects
//
//  Created by Will on 8/27/23.
//  Copyright © 2023 Will Loew-Blosser. All rights reserved.
//

import UIKit

class PGLStackAlbumHeader: UITableViewCell {

    static let reuseIdentifer = "StackAlbumHeader-reuse-identifier"

    static let nibName = "PGLStackAlbumHeader"

    @IBOutlet weak var cellLabel: UILabel!

    @IBOutlet weak var userText: UITextField!


    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        resignFirstResponder()
        return true
    }
    
}
