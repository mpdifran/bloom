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
    .safeAreaInset(edge: .bottom) {
      NewConversationChatBar(
        tabController: tabController,
        themeController: themeController,
        onSelectConversation: onSelectConversation
      )
    }
  }
}

// MARK: - New Conversation Chat Bar

import AppUI
import BloomModel
import DataContainer

struct NewConversationChatBar: View {
  let tabController: TabController
  let themeController: ThemeController
  let onSelectConversation: (ChatConversation, Bool) -> Void

  @State private var text = ""
  @State private var image: UIImage?
  @State private var presentedSheet: AnyView?
  @State private var didSendToggle = false
  @State private var error: Error?

  @FocusState private var isFocused

  var body: some View {
    Group {
      if #available(iOS 26, *) {
        content
      } else {
        legacyContent
      }
    }
    .animation(.bouncy, value: image)
    .animation(.bouncy, value: tabController.chatContexts)
    .sensoryFeedback(.impact, trigger: didSendToggle)
    .alert(error: $error)
    .sheet($presentedSheet)
  }

  @available(iOS 26.0, *)
  private var content: some View {
    VStack {
      if image != nil || tabController.chatContexts.isNotEmpty {
        imageAndContextSection
      }

      chatBar
        .glassEffect(in: RoundedRectangle(cornerRadius: 34))
        .onTapGesture {
          isFocused = true
        }
        .padding(8)
    }
  }

  private var legacyContent: some View {
    VStack {
      if image != nil || tabController.chatContexts.isNotEmpty {
        imageAndContextSection
      }

      chatBar
        .cardContainer(fill: .background, includePadding: false)
        .onTapGesture {
          isFocused = true
        }
    }
    .padding()
    .background {
      RoundedRectangle(cornerRadius: 40)
        .fill(.ultraThinMaterial)
        .ignoresSafeArea(edges: .bottom)
    }
  }

  private var imageAndContextSection: some View {
    ScrollView(.horizontal) {
      HStack {
        if let image {
          EditableChatImageView(image: image) {
            self.image = nil
          }
          .transition(.scale)
        }

        ForEachEnumerated(tabController.chatContexts) { index, chatContext in
          EditableChatContextCell(chatContext: chatContext) {
            tabController.chatContexts.remove(at: index)
          }
          .transition(.scale)
        }
      }
      .padding(.top, 4)
      .padding(.horizontal)
    }
  }

  private var chatBar: some View {
    HStack(alignment: .bottom, spacing: 12) {
      ImagePicker(image: $image, presentedSheet: $presentedSheet) {
        Image(systemSymbol: .plusCircleFill)
          .foregroundStyle(.white, .tint)
          .font(.title)
          .frame(square: 24)
      }

      TextField(
        "",
        text: $text,
        prompt: Text("New Chat"),
        axis: .vertical
      )
      .focused($isFocused)
      .frame(minHeight: 24)
      .submitLabel(.send)
      .onSubmit {
        Task {
          await submit()
        }
      }
      .onChange(of: text) { oldValue, newValue in
        if let newLineIndex = newValue.lastIndex(of: "\n") {
          text.remove(at: newLineIndex)
          Task {
            await submit()
          }
        }
      }

      if text.isEmpty {
        Button {
          isFocused.toggle()
        } label: {
          Image(systemSymbol: isFocused ? .chevronDownCircleFill : .chevronUpCircleFill)
            .foregroundStyle(.text, .fill)
            .font(.title)
            .frame(square: 24)
        }
      } else {
        Button {
          Task {
            await submit()
          }
        } label: {
          Image(systemSymbol: .arrowUpCircleFill)
            .foregroundStyle(.white, .tint)
            .font(.title)
            .frame(square: 24)
        }
      }
    }
    .padding(12)
  }

  private func submit() async {
    guard text.isNotEmpty || image != nil else { return }

    didSendToggle.toggle()

    let textToSend = text
    let imageToSend = image
    let chatContextsToSend = tabController.chatContexts

    text = ""
    image = nil
    tabController.chatContexts = []
    isFocused = false

    do {
      // Create a new conversation directly on main context
      let modelContext = ContainerHolder.shared.container.mainContext
      let conversation = ChatConversation(name: "New Chat")
      modelContext.insert(conversation)
      try modelContext.save()

      TelemetryDeck.signal("Create Chat Conversation")

      // Send the message to the new conversation
      try await ChatController.shared.send(
        message: textToSend,
        image: imageToSend,
        chatContexts: chatContextsToSend,
        conversationID: conversation.id,
        lastMessageID: nil
      )

      // Navigate to the new conversation (don't focus since we're already sending)
      await MainActor.run {
        onSelectConversation(conversation, false)
      }
    } catch {
      self.error = error
    }
  }
}
