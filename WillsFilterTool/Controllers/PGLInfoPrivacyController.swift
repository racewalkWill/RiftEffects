//
//  PGLInfoPrivacyController.swift
//  WillsFilterTool
//
//  Created by Will on 6/3/21.
//  Copyright © 2021 Will Loew-Blosser. All rights reserved.
//
import Foundation
import UIKit
import os

class PGLInfoPrivacyController: UIViewController {


    override func viewDidLoad() {
        super.viewDidLoad()
        PrivacyText.attributedText = readPrivacyPolicy()
        self.navigationItem.title = "https:\\\\willsfiltertool.photo"

        // Do any additional setup after loading the view.
    }

    func readPrivacyPolicy() -> NSAttributedString {
        var policyText = NSAttributedString(string: "Privacy Policy")
        let typeKey = NSAttributedString.DocumentReadingOptionKey.documentType
        let mainBundle = Bundle.main
        guard let privacyPath = mainBundle.path(forResource: "PrivacyPolicy", ofType: "rtf")
            else { return policyText}
        guard let privacyData = FileManager.default.contents(atPath: privacyPath)
        else { return policyText}
        do {
            policyText = try NSAttributedString.init(data: privacyData, options: [typeKey: NSAttributedString.DocumentType.rtf], documentAttributes: nil)

        } catch {
            Logger(subsystem: LogSubsystem, category: LogCategory).error("Privacy Policy read error \(error.localizedDescription)")

        }
        return policyText
    }

    @IBOutlet weak var PrivacyText: UITextView!


    @IBOutlet weak var infoLinkLabel: UILabel! {
        didSet {
            infoLinkLabel.text = "https:\\willsfiltertool.photo"
        }
    }

    @IBOutlet weak var privacyLabel: UILabel!  {
        didSet {

//          privacyLabel.attributedText = readPrivacyPolicy()



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
