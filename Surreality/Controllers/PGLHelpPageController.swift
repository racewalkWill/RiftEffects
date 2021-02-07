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

class PGLHelpPageController: UIPageViewController {
    // pop up modal 4 pages intro pics with comments
    var helpPages = ["help1", "help2", "help3", "help4"]
    var currentIndex: Int!

    override func viewDidLoad() {
        super.viewDidLoad()
        if let viewController = viewPhotoCommentController(currentIndex ?? 0) {
          let viewControllers = [viewController]

          setViewControllers(viewControllers,
                             direction: .forward,
                             animated: false,
                             completion: nil)
        }

        dataSource = self
      }
    func viewPhotoCommentController(_ index: Int) -> PGLHelpViewController? {
      guard
        let storyboard = storyboard,
        let page = storyboard.instantiateViewController(withIdentifier: "PGLHelpViewController") as? PGLHelpViewController
        else {
          return nil
      }
      page.photoName = helpPages[index]
      page.photoIndex = index
      return page
    }
  }

  extension PGLHelpPageController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
      if let viewController = viewController as? PGLHelpViewController,
        let index = viewController.photoIndex,
        index > 0 {
        return viewPhotoCommentController(index - 1)
      }

      return nil
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
      if let viewController = viewController as? PGLHelpViewController,
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


