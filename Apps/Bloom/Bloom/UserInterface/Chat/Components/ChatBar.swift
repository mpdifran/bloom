//
//  ChatBar.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-01.
//

import SFSafeSymbols
import SwiftUI

private extension Double {
  static let animationSpeed: Double = 1.5
}

struct ChatBar: View {

  let onSubmit: (String, UIImage?) -> Void

  init(_ onSubmit: @escaping (String, UIImage?) -> Void) {
    self.onSubmit = onSubmit
  }

  @State private var text: String = ""
  @State private var image: UIImage?
  @State private var didSendToggle = false
  @State private var presentedSheet: AnyView?

  @FocusState private var isFocused: Bool

  var body: some View {
    VStack {
      if image != nil {
        imageSection
      }
      chatTextField
    }
    .padding()
    .background {
      RoundedRectangle(cornerRadius: 40)
        .fill(.background.secondary)
        .ignoresSafeArea(edges: .bottom)
        .shadow(color: .text.opacity(0.1), radius: 20)
        .overlay {
          RoundedRectangle(cornerRadius: 40)
            .stroke(.fill)
            .ignoresSafeArea(edges: .bottom)
        }
    }
    .sensoryFeedback(.selection, trigger: isFocused)
    .animation(.easeInOut, value: text.isEmpty)
    .animation(.easeInOut, value: image)
    .sheet($presentedSheet)
  }
}

private extension ChatBar {

  var imageSection: some View {
    ScrollView(.horizontal) {
      HStack {
        if let image {
          EditableChatImageView(image: image) {
            self.image = nil
          }
        }
      }
      .padding(.horizontal)
    }
  }

  var chatTextField: some View {
    HStack(alignment: .bottom, spacing: 16) {
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
    onSubmit(text, image)
    text = ""
    image = nil
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
        ChatBar { (text, image) in

        }
      }
    }
  }
}
