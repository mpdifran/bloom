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
  
  @State private var text = ""
  @State private var image: UIImage?
  @State private var presentedSheet: AnyView?
  @State private var didSendToggle = false
  @State private var error: Error?
  
  @FocusState private var isFocused

  @Environment(TabController.self) private var tabController: TabController

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
    .onAppear {
      isFocused = true
    }
  }
}

private extension ChatMessageBar {

  @available(iOS 26.0, *)
  var content: some View {
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

  var legacyContent: some View {
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

  var imageAndContextSection: some View {
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

  var chatBar: some View {
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
    guard text.isNotEmpty || image != nil else { return }
    
    didSendToggle.toggle()
    
    let textToSend = text
    let imageToSend = image
    let chatContextsToSend = tabController.chatContexts

    text = ""
    image = nil
    tabController.chatContexts = []

    do {
      try await ChatController.shared.send(
        message: textToSend,
        image: imageToSend,
        chatContexts: chatContextsToSend
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
        ChatMessageBar()
      }
    }
  }
}
