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

  @Query private var chatMessages: [ChatMessage]

  init() {
    var descriptor = FetchDescriptor<ChatMessage>(
      sortBy: [SortDescriptor(\.date, order: .reverse)]
    )
    descriptor.fetchLimit = 20

    _chatMessages = Query(descriptor, animation: .default)
  }

  var body: some View {
    NavigationStack {
      ScrollViewReader { scrollViewProxy in
        ZStack(alignment: .bottom) {
          if chatMessages.isEmpty {
            ChatPromptsView()
              .zStackAlignment(.bottom)
          } else {
            ChatLayout {
              ForEach(cellBuilder.models) { model in
                ChatCell(
                  model: model
                )
                .id(model.id)
                .transition(.blurReplace)
              }

              if viewModel.inProgressMessages.isEmpty && viewModel.assistantIsTyping {
                TypingIndicatorCell(isDirect: false)
                  .id("typing-indicator")
                  .transition(.blurReplace)
              }

              bottomAnchorView
            }
            .scrollDismissesKeyboard(.interactively)
          }

          scrollToBottomButton {
            withAnimation {
              scrollViewProxy.scrollTo("bottom-anchor", anchor: .top)
            }
          }
        }
        .onChange(of: tabController.isChatBarFocused) { _, _ in
          withAnimation {
            scrollViewProxy.scrollTo("bottom-anchor", anchor: .top)
          }
        }
        .onChange(of: viewModel.inProgressMessages) { _, newValue in
          withAnimation {
            scrollViewProxy.scrollTo("bottom-anchor", anchor: .top)
          }
          if newValue.isEmpty {
            Task {
              await Delay(300)
              await MainActor.run {
                scrollViewProxy.scrollTo("bottom-anchor", anchor: .top)
              }
            }
          }
        }
        .onChange(of: viewModel.assistantIsTyping) { _, _ in
          withAnimation {
            scrollViewProxy.scrollTo("bottom-anchor", anchor: .top)
          }
        }
        .onChange(of: viewModel.assistantTypingStatus) { _, _ in
          withAnimation {
            scrollViewProxy.scrollTo("bottom-anchor", anchor: .top)
          }
        }
        .onChange(of: chatMessages.count) { _, _ in
          withAnimation {
            scrollViewProxy.scrollTo("bottom-anchor", anchor: .top)
          }
        }
      }
      .groupedBackground()
      .safeAreaPadding(.bottom, tabController.chatLauncherSafeAreaInset)
      .sensoryFeedback(.selection, trigger: viewModel.inProgressMessages)
      .sheet($presentedSheet)
      .alert(error: $viewModel.error)
      .animation(.default, value: cellBuilder.models)
      .onChange(of: chatMessages) { updateCells() }
      .onChange(of: viewModel.inProgressMessages) { updateCells() }
      .onChange(of: viewModel.assistantTypingStatus) { updateCells() }
      .onChange(of: viewModel.assistantIsTyping) { updateCells() }
      .navigationTitle("Bud")
      .navigationBarTitleDisplayMode(.inline)
      .task {
        await viewModel.maintainWebSocketConnection()
      }
      .task {
        updateCells()
      }
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Done") {
            tabController.isShowingChat = false
            tabController.isChatBarFocused = false
          }
          .bold()
        }
        ToolbarItem(placement: .primaryAction) {
          Button {
            presentedSheet = ChatSettingsView().asAny
          } label: {
            Label("Settings", systemSymbol: .gear)
          }
        }
      }
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
    if chatMessages.isNotEmpty && !isAtBottom {
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
