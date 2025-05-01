//
//  ChatLauncherView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-22.
//

import SwiftUI

extension View {
  func chatLauncher() -> some View {
    modifier(ChatLauncherViewModifier())
  }
}

struct ChatLauncherViewModifier: ViewModifier {

  @Environment(TabController.self) private var tabController: TabController

  func body(content: Content) -> some View {
    content
      .blur(radius: tabController.isShowingChat ? 15 : 0)
      .overlay {
        if tabController.isShowingChat {
          ChatView()
        }
      }
      .overlay {
        ChatLauncherView()
          .readViewSize { proxy in
            tabController.chatLauncherSafeAreaInset = proxy.size.height
          }
          .zStackAlignment(.bottom)
      }
      .animation(.linear, value: tabController.isShowingChat)
  }
}

struct ChatLauncherView: View {

  @State private var text = ""
  @State private var image: UIImage?
  @State private var presentedSheet: AnyView?
  @State private var didSendToggle = false
  @State private var selectionToggle = false
  @State private var error: Error?

  @FocusState private var isFocused

  @Environment(TabController.self) private var tabController: TabController

  var body: some View {
    VStack {
      if image != nil {
        imageSection
      }

      HStack {
        if !tabController.isShowingChat {
          tabPickerButton
        }

        chatMessageBar

        if !tabController.isShowingChat {
          actionButton
        }
      }
    }
    .padding()
    .background {
      RoundedRectangle(cornerRadius: 40)
        .fill(.background.secondary)
        .ignoresSafeArea(edges: .bottom)
    }
    .animation(.bouncy, value: image)
    .animation(.easeOut, value: tabController.isShowingChat)
    .sensoryFeedback(.impact, trigger: didSendToggle)
    .sensoryFeedback(.selection, trigger: selectionToggle)
    .onChange(of: isFocused) { oldValue, newValue in
      if newValue {
        tabController.isShowingChat = true
      }
    }
    .alert(error: $error)
    .sheet($presentedSheet)
//    contentBuilder()
//      .blur(radius: isFocused ? 10 : 0)
//      .overlay {
//        fakeChatView
//          .opacity(isFocused ? 1 : 0)
//          .onTapGesture {
//            isFocused = false
//          }
//      }
//      .safeAreaInset(edge: .bottom) {
//        chatLaunchBar
//          .background {
//            RoundedRectangle(cornerRadius: 40)
//              .fill(.ultraThinMaterial)
//              .ignoresSafeArea(edges: .bottom)
////              .overlay {
////                RoundedRectangle(cornerRadius: 40)
////                  .stroke(.fill)
////                  .ignoresSafeArea(edges: .bottom)
////              }
//          }
//      }
//      .animation(.easeIn, value: isFocused)
  }
}

private extension ChatLauncherView {

  var imageSection: some View {
    ScrollView(.horizontal) {
      HStack {
        if let image {
          EditableChatImageView(image: image) {
            self.image = nil
          }
          .transition(.scale)
        }
      }
      .padding(.horizontal)
    }
  }

  var chatMessageBar: some View {
    HStack(alignment: .bottom) {
      if tabController.isShowingChat {
        ImagePicker(image: $image, presentedSheet: $presentedSheet) {
          Image(systemSymbol: .cameraCircleFill)
            .foregroundStyle(.white, .tint)
            .font(.title)
            .frame(square: 24)
        }
      }

      if !tabController.isShowingChat {
        Image(systemSymbol: .sparkles)
          .foregroundStyle(.secondary)
      }

      TextField(
        "",
        text: $text,
        prompt: Text("Ask Bud"),
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

      if tabController.isShowingChat {
        if text.isEmpty {
          if isFocused {
            Button {
              isFocused = false
              selectionToggle.toggle()
            } label: {
              Image(systemSymbol: .chevronDownCircleFill)
                .foregroundStyle(.text, .fill)
                .font(.title)
                .frame(square: 24)
            }
          } else {
            Button {
              tabController.isShowingChat = false
              selectionToggle.toggle()
            } label: {
              Image(systemSymbol: .xmarkCircleFill)
                .foregroundStyle(.text, .fill)
                .font(.title)
                .frame(square: 24)
            }
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
    }
    .frame(minWidth: 120)
    .padding(12)
    .cardContainer(fill: .background, includePadding: false)
    .onTapGesture {
      isFocused = true
    }
  }

  var tabPickerButton: some View {
    Menu {
      ForEach(Tab.allCases.reversed()) { tab in
        Button {
          tabController.activeTab = tab
          selectionToggle.toggle()
        } label: {
          Label {
            Text(tab.name)
          } icon: {
            tab.tabImage
          }
        }
      }
    } label: {
      tabController.activeTab.tabImage
        .frame(square: 24)
        .padding(12)
        .cardContainer(fill: .background, includePadding: false)
    }
  }

  var actionButton: some View {
    Button {
      presentedSheet = ActionsView().asAny
      selectionToggle.toggle()
    } label: {
      Image(systemSymbol: .plus)
        .font(.title3)
        .fontDesign(.rounded)
        .fontWeight(.semibold)
        .frame(square: 24)
        .padding(12)
        .cardContainer(fill: .background, includePadding: false)
    }
  }
}

private extension ChatLauncherView {

  func submit() async {
    guard text.isNotEmpty || image != nil else { return }

    didSendToggle.toggle()

    let textToSend = text
    let imageToSend = image

    text = ""
    image = nil

    do {
      try await ChatController.shared.send(message: textToSend, image: imageToSend)
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
          ForEach(1...20, id: \.self) { number in
            Text("\(number)")
              .horizontalAlignment(.leading)
              .cardContainer()
          }
        }
        .padding()
      }
      .groupedBackground()
      .chatLauncher()
    }
  }
}
