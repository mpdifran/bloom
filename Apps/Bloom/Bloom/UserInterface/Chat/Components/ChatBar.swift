//
//  ChatBar.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-01.
//

import SFSafeSymbols
import SwiftUI
import AppUI

private extension Double {
  static let animationSpeed: Double = 1.5
}

struct ChatBar: View {

  let onSubmit: (String, [UIImage]) -> Void
  /// Focuses the field as soon as the bar appears, raising the keyboard. Used by the App Store
  /// screenshot previews, which need the keyboard up without anyone tapping.
  let startFocused: Bool

  init(startFocused: Bool = false, _ onSubmit: @escaping (String, [UIImage]) -> Void) {
    self.startFocused = startFocused
    self.onSubmit = onSubmit
  }

  @State private var text: String = ""
  @State private var images = [UIImage]()
  @State private var didSendToggle = false
  @State private var presentedSheet: AnyView?

  @FocusState private var isFocused: Bool

  var body: some View {
    VStack {
      if images.isNotEmpty {
        imageSection
      }
      chatTextField
    }
    .padding()
    .background {
      RoundedRectangle(cornerRadius: 40)
        .fill(.background.secondary)
        .ignoresSafeArea(edges: .bottom)
        .overlay {
          RoundedRectangle(cornerRadius: 40)
            .stroke(.fill)
            .ignoresSafeArea(edges: .bottom)
        }
    }
    .onAppear {
      guard startFocused else { return }

      isFocused = true
    }
    .sensoryFeedback(.selection, trigger: isFocused)
    .animation(.easeInOut, value: text.isEmpty)
    .animation(.easeInOut, value: images)
    .sheet($presentedSheet)
  }
}

private extension ChatBar {

  var imageSection: some View {
    ScrollView(.horizontal) {
      HStack {
        ForEachEnumeratedNoID(images) { index, image in
          EditableChatImageView(image: image) {
            images.remove(at: index)
          }
        }
      }
      .padding(.horizontal)
    }
  }

  var chatTextField: some View {
    HStack(alignment: .bottom, spacing: 16) {
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
      .scrollDismissesKeyboard(.interactively)
      .frame(minHeight: 24)

      Button {
        submit()
      } label: {
        Image(systemSymbol: .arrowUpCircleFill)
          .foregroundStyle(.white, .tint)
          .font(.title)
          .frame(square: 24)
      }
      .disabled(text.isEmpty)
    }
    .submitLabel(.send)
    .sensoryFeedback(.impact, trigger: didSendToggle)
    .onSubmit {
      submit()
    }
    .cardContainer()
    .onChange(of: text) { oldValue, newValue in
      if let newLineIndex = newValue.lastIndex(of: "\n") {
        text.remove(at: newLineIndex)
        submit()
      }
    }
  }
}

private extension ChatBar {

  func submit() {
    didSendToggle.toggle()
    isFocused = false
    onSubmit(text, images)
    text = ""
    images = []
  }

//  var computedGradientColors: [Color] {
//    let first = gradientColors.first!
//    return gradientColors + [first]
//  }
//
//  func shiftGradientColors() {
//    let last = gradientColors.removeLast()
//    gradientColors.insert(last, at: 0)
//  }
}

#Preview {
  PreviewEnvironment {
    NavigationStack {
      ScrollView {
        VStack {
          ChatBubbleCell(message: "Hello World, it's me!", isDirect: false, isCurrentUser: false, showTail: true)
          ChatBubbleCell(message: "Oh, ok, sounds good.", isDirect: false, isCurrentUser: true, showTail: true)
          ChatBubbleCell(message: "What does that mean?", isDirect: false, isCurrentUser: false, showTail: true)
          ChatBubbleCell(message: "Huh?", isDirect: false, isCurrentUser: false, showTail: true)
          ChatBubbleCell(message: "You know what it means.", isDirect: false, isCurrentUser: true, showTail: true)
        }
      }
      .groupedBackground()
      .navigationTitle("Chat")
      .safeAreaInset(edge: .bottom) {
        ChatBar { (text, images) in

        }
      }
    }
  }
}
