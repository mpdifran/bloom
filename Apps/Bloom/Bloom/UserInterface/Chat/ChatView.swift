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
  @State private var scrollToBottomTrigger = false

  @Environment(\.dismiss) private var dismiss
  @Environment(TabController.self) private var tabController: TabController

  var body: some View {
    NavigationStack {
      chatContent
        .groupedBackground()
        .sensoryFeedback(.selection, trigger: viewModel.cellModels)
        .animation(.default, value: viewModel.cellModels)
        .navigationTitle("Bud")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          toolbarContent
        }
    }
    .presentationCompactAdaptation(.fullScreenCover)
    .sheet($presentedSheet)
    .alert(error: $viewModel.error)
    .task {
      await viewModel.maintainWebSocketConnection()
    }
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
    messageList
      .overlay {
        scrollToBottomButton {
          scrollToBottomTrigger = true
        }
        .zStackAlignment(.bottom)
      }
      .safeAreaInset(edge: .bottom) {
        ChatMessageBar()
      }
  }
  
  @ViewBuilder
  private var messageList: some View {
    if viewModel.cellModels.isEmpty {
      ChatPromptsView()
        .zStackAlignment(.bottom)
    } else {
      ChatLayoutView(
        cellModels: $viewModel.cellModels,
        scrollToBottomTrigger: $scrollToBottomTrigger,
        onLoadMore: {
          await viewModel.loadMoreMessages()
        },
        onIsAtBottomChanged: { atBottom in
          withAnimation {
            isAtBottom = atBottom
          }
        }
      )
    }
  }
}


private extension ChatView {

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
