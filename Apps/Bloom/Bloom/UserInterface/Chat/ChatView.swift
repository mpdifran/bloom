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
  @State private var presentedSheet: AnyView?
  @State private var isAtBottom = false

  @Environment(\.dismiss) private var dismiss
  @Environment(TabController.self) private var tabController: TabController

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
      .sensoryFeedback(.selection, trigger: viewModel.cellModels)
      .sheet($presentedSheet)
      .alert(error: $viewModel.error)
      .animation(.default, value: viewModel.cellModels)
      .task { await viewModel.maintainWebSocketConnection() }
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
        cellModels: viewModel.cellModels
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
    if viewModel.cellModels.isEmpty {
      ChatPromptsView()
        .zStackAlignment(.bottom)
    } else {
      ChatLayout {
        ForEach(viewModel.cellModels) { model in
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
  let cellModels: [ChatCellModel]
  
  func body(content: Content) -> some View {
    content
      .onChange(of: cellModels) { _, _ in
        withAnimation {
          scrollViewProxy.scrollTo("bottom-anchor", anchor: .bottom)
        }
      }
  }
}

private extension ChatView {

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
    if viewModel.cellModels.isNotEmpty && !isAtBottom {
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
