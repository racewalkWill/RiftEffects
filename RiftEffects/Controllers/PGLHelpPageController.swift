//
//  PGLHelpPageController.swift
//  Surreality
//
//  Created by Will on 2/4/21.
//  Copyright © 2021 Will Loew-Blosser. All rights reserved.
//
// from PhotoScroll by Razeware LLC
/// Copyright (c) 2019 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation

import UIKit
import os

class PGLHelpPageController: UIPageViewController {
    // pop up modal 4 pages intro pics with comments
    // PGLImageController checks for first startup and shows this Help
    // PGLImageController turns off first startup boolean

    var helpPages: [(imageName: String, imageText: String )] = [
            ("Help1-Pick",
                "SELECT a filter, TAP the info button, then PICK an image from your photo library") ,
            ("Help2-Parm",
                "Tap to open your photo library"),
            ("Help3-ImagePick",
                "Pick an image - then '<Back'" ),
            ( "Help5-ParmAdjust",
                "Select a filter parm, and adjust the control"),
        ( "longPress",
            "Long touch for filter description"),
        ( "Help4-MorePick",
            "Swipe then touch More or Pick")
            ]

    var currentIndex: Int!
    var instructionText: String!

    override func viewDidLoad() {
        super.viewDidLoad()
        Logger(subsystem: LogSubsystem, category: LogNavigation).info("\( String(describing: self) + "-" + #function)")
        if let viewController = viewPhotoCommentController(currentIndex ?? 0) {
          let viewControllers = [viewController]

          setViewControllers(viewControllers,
                             direction: .forward,
                             animated: false,
                             completion: nil)
        }

        dataSource = self



      }

    override func viewWillDisappear(_ animated: Bool) {

        if ShowHelpOnOpen { UserDefaults.standard.setValue(false, forKey: ShowHelpPageAtStartupKey)}
            // set to false after first time true (startup)
            // only show once on first startup... then user should use the ? button for help

      }

    func viewPhotoCommentController(_ index: Int) -> PGLHelpSinglePage? {
      guard
        let storyboard = storyboard,
        let page = storyboard.instantiateViewController(withIdentifier: "PGLHelpSinglePage") as? PGLHelpSinglePage
        else {
          return nil
      }
        page.photoIndex = index
        page.photoName = helpPages[index].imageName
        page.instructionText = helpPages[index].imageText

      return page
    }
  }

  extension PGLHelpPageController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
      if let viewController = viewController as? PGLHelpSinglePage,
        let index = viewController.photoIndex,
        index > 0 {
        return viewPhotoCommentController(index - 1)
      }

      return nil
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
      if let viewController = viewController as? PGLHelpSinglePage,
        let index = viewController.photoIndex,
        (index + 1) < helpPages.count {
        return viewPhotoCommentController(index + 1)
      }

      return nil
    }

    func presentationCount(for pageViewController: UIPageViewController) -> Int {
      return helpPages.count
    }

    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
      return currentIndex ?? 0
    }
  }


