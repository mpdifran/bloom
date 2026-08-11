//
//  ChatMessageBar.swift
//  Bloom
//
//  Created by Assistant on 2025-05-28.
//

import SwiftUI
import SFSafeSymbols
import AppUI

struct ChatMessageBar: View {

  let conversationID: String
  let lastMessageID: String?

  @State private var text = ""
  @State private var images = [UIImage]()
  @State private var presentedSheet: AnyView?
  @State private var didSendToggle = false
  @State private var error: Error?

  @FocusState private var isFocused

  @Environment(TabController.self) private var tabController: TabController

  var body: some View {
    Group {
      content
    }
    .animation(.bouncy, value: images)
    .animation(.bouncy, value: tabController.chatContexts)
    .sensoryFeedback(.impact, trigger: didSendToggle)
    .alert(error: $error)
    .sheet($presentedSheet)
    .onAppear {
      isFocused = true
    }
  }
}

private extension ChatMessageBar {

  var content: some View {
    VStack {
      if images.isNotEmpty || tabController.chatContexts.isNotEmpty {
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

  var imageAndContextSection: some View {
    ScrollView(.horizontal) {
      HStack {
        ForEachEnumeratedNoID(images) { index, image in
          EditableChatImageView(image: image) {
            images.remove(at: index)
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

  var chatBar: some View {
    HStack(alignment: .bottom, spacing: 12) {
      ImagePicker(
        images: $images,
        presentedSheet: $presentedSheet,
        maxImageCount: ChatController.maxImageCount
      ) {
        Image(systemSymbol: .plusCircleFill)
          .foregroundStyle(.white, .tint)
          .font(.title)
          .frame(square: 24)
      }

      TextField(
        "",
        text: $text,
        prompt: Text("Message"),
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

  func submit() async {
    guard text.isNotEmpty || images.isNotEmpty else { return }

    didSendToggle.toggle()

    let textToSend = text
    let imagesToSend = images
    let chatContextsToSend = tabController.chatContexts

    text = ""
    images = []
    tabController.chatContexts = []

    do {
      try await ChatController.shared.send(
        message: textToSend,
        images: imagesToSend,
        chatContexts: chatContextsToSend,
        conversationID: conversationID,
        lastMessageID: lastMessageID
      )
    } catch {
      self.error = error
    }
  }
}

#Preview {
  PreviewEnvironment {
    NavigationStack {
      ScrollView {
        VStack {
          ForEach(1...10, id: \.self) { number in
            HStack {
              Text("Message \(number)")
                .padding()
                .background(Color.blue.opacity(0.2))
                .cornerRadius(12)
              Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
          }
        }
        .padding(.top)
      }
      .groupedBackground()
      .navigationTitle("Bud")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          DismissButton()
        }
        ToolbarItem(placement: .primaryAction) {
          Button { } label: {
            Label("Settings", systemSymbol: .gear)
          }
        }
      }
      .safeAreaInset(edge: .bottom) {
        ChatMessageBar(conversationID: "preview", lastMessageID: nil)
      }
    }
  }
}
