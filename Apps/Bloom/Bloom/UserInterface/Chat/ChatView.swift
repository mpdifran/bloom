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
import UIKit

struct ChatView: View {

  @State private var viewModel = ChatViewModel()
  @State private var cellBuilder = ChatCellBuilder()
  @State private var presentedSheet: AnyView?
  @State private var isAtBottom = false
  @State private var lastMessageCount = 0
  @State private var updateTask: Task<Void, Never>?

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
      chatContentWithModifiers
        .navigationTitle("Bud")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
    }
    .presentationCompactAdaptation(.fullScreenCover)
  }
  
  private var chatContentWithModifiers: some View {
    chatContent
      .groupedBackground()
      .sensoryFeedback(.selection, trigger: viewModel.inProgressMessages)
      .sheet($presentedSheet)
      .alert(error: $viewModel.error)
      .animation(.default, value: cellBuilder.models.count)
      .modifier(ChatUpdateModifier(
        chatMessages: chatMessages,
        inProgressMessages: viewModel.inProgressMessages,
        assistantTypingStatus: viewModel.assistantTypingStatus,
        assistantIsTyping: viewModel.assistantIsTyping,
        updateCells: updateCells
      ))
      .task { await viewModel.maintainWebSocketConnection() }
      .task { updateCells() }
  }
  
  @ToolbarContentBuilder
  private var toolbarContent: some ToolbarContent {
    ToolbarItem(placement: .cancellationAction) {
      Button("Done") {
        dismiss()
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
  
  @ViewBuilder
  private var chatContent: some View {
    ScrollViewReader { scrollViewProxy in
      ZStack(alignment: .bottom) {
        messageList
        
        scrollToBottomButton {
          withAnimation {
            scrollViewProxy.scrollTo("bottom-anchor", anchor: .bottom)
          }
        }
      }
      .safeAreaInset(edge: .bottom) {
        ChatMessageBar()
      }
      .modifier(ScrollBehaviorModifier(
        scrollViewProxy: scrollViewProxy,
        messages: chatMessages
      ))
      .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
        withAnimation {
          scrollViewProxy.scrollTo("bottom-anchor", anchor: .bottom)
        }
      }
      .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)) { _ in
        withAnimation {
          scrollViewProxy.scrollTo("bottom-anchor", anchor: .bottom)
        }
      }
      .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidHideNotification)) { _ in
        withAnimation {
          scrollViewProxy.scrollTo("bottom-anchor", anchor: .bottom)
        }
      }
    }
  }
  
  @ViewBuilder
  private var messageList: some View {
    if cellBuilder.models.isEmpty {
      ChatPromptsView()
        .zStackAlignment(.bottom)
    } else {
      ChatLayout {
        ForEach(cellBuilder.models) { model in
          ChatCell(model: model)
            .id(model.id)
            .transition(.blurReplace)
        }
        
        bottomAnchorView
      }
      .scrollDismissesKeyboard(.interactively)
    }
  }
}

struct ScrollBehaviorModifier: ViewModifier {
  let scrollViewProxy: ScrollViewProxy
  let messages: [ChatMessage]

  @State private var lastMessageCount = 0
  
  func body(content: Content) -> some View {
    content
      .onChange(of: messages) { _, _ in
        withAnimation {
          scrollViewProxy.scrollTo("bottom-anchor", anchor: .bottom)
        }
      }
  }
}

struct ChatUpdateModifier: ViewModifier {
  let chatMessages: [ChatMessage]
  let inProgressMessages: [ChatController.InProgressMessage]
  let assistantTypingStatus: String?
  let assistantIsTyping: Bool
  let updateCells: () -> Void
  
  func body(content: Content) -> some View {
    content
      .onChange(of: chatMessages) { _, _ in
        Task { @MainActor in
          updateCells()
        }
      }
      .onChange(of: inProgressMessages) { _, _ in
        Task { @MainActor in
          updateCells()
        }
      }
      .onChange(of: assistantTypingStatus) { _, _ in
        Task { @MainActor in
          updateCells()
        }
      }
      .onChange(of: assistantIsTyping) { _, _ in
        Task { @MainActor in
          updateCells()
        }
      }
  }
}

private extension ChatView {

  func updateCells() {
    // Cancel any pending update
    updateTask?.cancel()
    
    // Schedule a new update with a small delay to batch rapid changes
    updateTask = Task { @MainActor in
      // Small delay to batch multiple rapid updates
      try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
      
      guard !Task.isCancelled else { return }
      
      cellBuilder.build(
        messages: chatMessages,
        inProgressMessages: viewModel.inProgressMessages,
        statusText: viewModel.assistantTypingStatus,
        assistantIsTyping: viewModel.assistantIsTyping
      )
    }
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
