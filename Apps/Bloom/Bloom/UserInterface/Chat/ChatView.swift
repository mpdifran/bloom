//
//  ChatView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-16.
//

import SFSafeSymbols
import SwiftUI
import AppUI
import SwiftData
import DataContainer

struct ChatView: View {

  @State private var viewModel = ChatViewModel()
  @State private var cellBuilder = ChatCellBuilder()
  @State private var presentedSheet: AnyView?
  @State private var isAtBottom = false

  @Environment(\.dismiss) private var dismiss
  @Environment(TabController.self) private var tabController: TabController

  @Query(sort: \ChatMessage.date)
  private var chatMessages: [ChatMessage]

  var body: some View {
    ScrollViewReader { scrollViewProxy in
      ZStack(alignment: .bottom) {
        ChatLayout {
          ForEach(cellBuilder.models) { model in
            ChatCell(
              model: model
            )
            .id(model.id)
            .transition(.blurReplace)
          }

          bottomAnchorView
        }
        .scrollDismissesKeyboard(.interactively)

        scrollToBottomButton {
          withAnimation {
            scrollViewProxy.scrollTo("bottom-anchor", anchor: .top)
          }
        }
      }
    }
    .groupedBackground()
    .safeAreaPadding(.bottom, tabController.chatLauncherSafeAreaInset)
    .sensoryFeedback(.selection, trigger: viewModel.inProgressMessages)
    .sheet($presentedSheet)
    .alert(error: $viewModel.error)
    .animation(.default, value: cellBuilder.models)
    .topSafeAreaBlur()
    .onChange(of: chatMessages) { updateCells() }
    .onChange(of: viewModel.inProgressMessages) { updateCells() }
    .onChange(of: viewModel.assistantTypingStatus) { updateCells() }
    .onChange(of: viewModel.assistantIsTyping) { updateCells() }
    .task {
      updateCells()
    }
  }
}

private extension ChatView {
  func updateCells() {
    cellBuilder.build(
      messages: chatMessages,
      inProgressMessages: viewModel.inProgressMessages,
      statusText: viewModel.assistantTypingStatus,
      assistantIsTyping: viewModel.assistantIsTyping
    )
  }

  var bottomAnchorView: some View {
    Color.clear
      .frame(height: 0.1)
      .id("bottom-anchor")
      .onAppear {
        withAnimation {
          isAtBottom = true
        }
      }
      .onDisappear {
        withAnimation {
          isAtBottom = false
        }
      }
  }

  @ViewBuilder
  func scrollToBottomButton(_ onTap: @escaping () -> Void) -> some View {
    if !isAtBottom {
      Button {
        onTap()
      } label: {
        Image(systemSymbol: .arrowDown)
          .font(.body)
          .foregroundStyle(.text, .fill)
          .frame(square: 32)
          .background(Circle().fill(.ultraThinMaterial))
          .shadow(radius: 2)
      }
      .padding(.bottom, 8)
      .transition(.scale.combined(with: .blurReplace))
    }
  }
}

#Preview {
  PreviewEnvironment {
    ChatView()
  }
}
