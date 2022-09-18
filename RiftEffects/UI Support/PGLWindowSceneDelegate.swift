//
//  PGLWindowSceneDelegate.swift
//  RiftEffects
//
//  Created by Will on 9/18/22.
//  Copyright © 2022 Will Loew-Blosser. All rights reserved.
//

import UIKit

final class PGLWindowSceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
      guard let windowScene = scene as? UIWindowScene else { return }
      let window = UIWindow(windowScene: windowScene)

      let startViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "RootSplitView")


      window.rootViewController =  startViewController
      self.window = window

      window.makeKeyAndVisible()
    }
}
