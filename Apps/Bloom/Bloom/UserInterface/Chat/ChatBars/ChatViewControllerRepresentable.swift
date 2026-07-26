//
//  ChatViewControllerRepresentable.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-22.
//

import SwiftUI
import UIKit

/// Hosts the UIKit chat navigation stack (conversations list + chat) for the chat fullScreenCover.
struct ChatViewControllerRepresentable: UIViewControllerRepresentable {
  let tabController: TabController
  let themeController: ThemeController

  func makeUIViewController(context: Context) -> UINavigationController {
    let conversationsViewController = ChatConversationsViewController(
      tabController: tabController,
      themeController: themeController
    )
    return UINavigationController(rootViewController: conversationsViewController)
  }

  func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
    // No updates needed
  }
}
