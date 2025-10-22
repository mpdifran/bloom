//
//  ChatLayoutSwiftUIView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-07-20.
//

import SwiftUI

struct ChatLayoutSwiftUIView: View {
  @Binding var cellModels: [ChatCellModel]
  @Binding var scrollToBottomTrigger: Bool
  @Binding var conversationInProgress: Bool

  let onIsAtBottomChanged: (Bool) -> Void

  var body: some View {
    ScrollViewReader { scrollViewReader in
      ScrollView {
        LazyVStack {
          ForEach(cellModels) { cellModel in
            createCell(for: cellModel)
          }
        }

        if conversationInProgress {
          Spacer(minLength: 600)
        }
      }
      .onChange(of: scrollToBottomTrigger) { oldValue, newValue in
        guard newValue, let lastUserSentMessageID else { return }

        withAnimation(.easeInOut(duration: 0.3)) {
          scrollViewReader.scrollTo(lastUserSentMessageID, anchor: .top)
        }
        
        // Reset the trigger
        scrollToBottomTrigger = false
      }
    }
  }
}

private extension ChatLayoutSwiftUIView {

  var lastUserSentMessageID: String? {
    cellModels.last(where: { cellModel in
      switch cellModel.contentType {
      case .text(_, _, let metadata):
        return (metadata?.isCurrentUser ?? false)
      default:
        return false
      }
    })?.id
  }
}

private extension ChatLayoutSwiftUIView {

  @ViewBuilder
  func createCell(for cellModel: ChatCellModel) -> some View {
    switch cellModel.contentType {
    case .text(id: let id, let content, let metadata):
      ChatBubbleCell(
        message: content,
        isDirect: false,
        isCurrentUser: metadata?.isCurrentUser ?? false,
        showTail: true,
        showReportButton: metadata?.showReportButton ?? false,
        responseID: metadata?.responseID,
        requestID: metadata?.requestID
      )
      .id(id)

    case .image(let id, let imageData, let metadata):
      ChatImageCell(
        image: UIImage(data: imageData) ?? UIImage(),
        isCurrentUser: metadata?.isCurrentUser ?? false
      )
      .id(id)

    case .richContent(let id, let content, let metadata):
      ChatProcessedRichContentWrapperCell(
        chatMessageID: id,
        content: content,
        hasPerformedAction: metadata?.hasPerformedAction ?? false,
        dbID: metadata?.dbID,
        showReportButton: metadata?.showReportButton ?? false,
        responseID: metadata?.responseID,
        requestID: metadata?.requestID
      )
      .id(id)

    case .typingIndicator:
      TypingIndicatorCell(isDirect: false)

    case .statusText(let status):
      HStack {
        Text(status)
          .font(.subheadline)
          .bold()
          .foregroundStyle(.secondary)
          .fontDesign(.rounded)
          .multilineTextAlignment(.leading)
          .lineLimit(2)
          .contentTransition(.numericText())
          .shimmer()

        Spacer(minLength: 60)
      }
      .padding(.horizontal)

    case .prompts:
      EmptyView() // Remove this from the chat content
    }
  }
}
