//
//  ChatConversationsViewController.swift
//  Bloom
//
//  Created by Assistant on 2025-10-09.
//

import UIKit
import SwiftUI
import SwiftData
import DataContainer
import SFSafeSymbols
import TelemetryDeck

class ChatConversationsViewController: UIHostingController<ChatConversationsRootView> {

  private let tabController: TabController
  private let themeController: ThemeController

  init(tabController: TabController, themeController: ThemeController) {
    self.tabController = tabController
    self.themeController = themeController

    let rootView = ChatConversationsRootView(
      tabController: tabController,
      themeController: themeController,
      onSelectConversation: { _,_  in }  // Temporary placeholder
    )

    super.init(rootView: rootView)

    // Update the rootView with the actual callback now that self is initialized
    self.rootView = ChatConversationsRootView(
      tabController: tabController,
      themeController: themeController,
      onSelectConversation: { [weak self] conversation, shouldFocus in
        self?.pushChatViewController(for: conversation, shouldFocus: shouldFocus)
      }
    )
  }

  @MainActor required dynamic init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupNavigationBar()
  }

  private func setupNavigationBar() {
    navigationItem.leftBarButtonItem = UIBarButtonItem(
      image: UIImage(systemSymbol: .xmark),
      style: .plain,
      target: self,
      action: #selector(dismissTapped)
    )
  }

  @objc private func dismissTapped() {
    dismiss(animated: true)
  }

  private func pushChatViewController(for conversation: ChatConversation, shouldFocus: Bool) {
    let chatViewController = ChatViewController(
      conversationID: conversation.id,
      tabController: tabController,
      themeController: themeController,
      shouldFocusOnAppear: shouldFocus
    )
    navigationController?.pushViewController(chatViewController, animated: true)
  }
}

// MARK: - SwiftUI Root View

struct ChatConversationsRootView: View {
  let tabController: TabController
  let themeController: ThemeController
  let onSelectConversation: (ChatConversation, Bool) -> Void

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    ChatConversationView(
      tabController: tabController,
      themeController: themeController,
      onSelectConversation: onSelectConversation
    )
  }
}
