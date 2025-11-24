//
//  NewConversationChatMessageBar.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-11-24.
//

import SwiftUI
import DataContainer
import SFSafeSymbols
import AppUI
import TelemetryDeck

struct NewConversationChatMessageBar: View {
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
        .selectable()
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
        Image(systemSymbol: .plus)
          .foregroundStyle(.white, .tint)
          .font(.body)
          .bold()
          .fontDesign(.rounded)
          .frame(square: 30)
          .background {
            Capsule()
              .fill(.tint)
          }
      }

      TextField(
        "",
        text: $text,
        prompt: Text("New Chat"),
        axis: .vertical
      )
      .focused($isFocused)
      .frame(minHeight: 30)
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
          Image(systemSymbol: isFocused ? .chevronDown : .chevronUp)
            .foregroundStyle(.text)
            .font(.body)
            .bold()
            .fontDesign(.rounded)
            .frame(width: 44, height: 30)
            .background {
              Capsule()
                .fill(.fill.tertiary)
            }
        }
      } else {
        Button {
          Task {
            await submit()
          }
        } label: {
          Image(systemSymbol: .arrowUp)
            .foregroundStyle(.white)
            .font(.body)
            .bold()
            .fontDesign(.rounded)
            .frame(width: 44, height: 30)
            .background {
              Capsule()
                .fill(.tint)
            }
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

#Preview {
  PreviewEnvironment {
    BloomScrollView(showsChatBar: false) {
      Text("Chat Content")
    }
    .safeAreaInset(edge: .bottom) {
      NewConversationChatMessageBar(tabController: TabController(), themeController: .shared) { (_, _) in

      }
    }
  }
}
