//
//  ChatBubbleCell.swift
//  AirChat
//
//  Created by Mark DiFranco on 2022-01-23.
//

import SwiftUI
import BloomUI
import BloomModel

public struct ChatBubbleCell: View {
  let message: String
  let isDirect: Bool
  let isCurrentUser: Bool
  let showTail: Bool
  let showReportButton: Bool
  let responseID: String?
  let requestID: String?
  let sources: [SocketMessage.SourceRef]

  public init(
    message: String,
    isDirect: Bool,
    isCurrentUser: Bool,
    showTail: Bool,
    showReportButton: Bool = false,
    responseID: String? = nil,
    requestID: String? = nil,
    sources: [SocketMessage.SourceRef] = []
  ) {
    self.message = message
    self.isDirect = isDirect
    self.isCurrentUser = isCurrentUser
    self.showTail = showTail
    self.showReportButton = showReportButton
    self.responseID = responseID
    self.requestID = requestID
    self.sources = sources
  }

  @State private var showReportSheet = false
  @State private var showSourcesSheet = false

  /// Whether there is anything to put under the message. Without this an empty row still takes
  /// padding, leaving a gap under every ordinary reply.
  private var showsControlRow: Bool {
    sources.isNotEmpty || (showReportButton && responseID != nil && requestID != nil)
  }

  @Bindable private var themeController = ThemeController.shared

  public var body: some View {
    VStack(alignment: .leading) {
      if isCurrentUser {
        ChatBubble(
          position: isCurrentUser ? .trailing : .leading,
          showTail: showTail,
          shouldFill: !isDirect,
          includePadding: isCurrentUser,
          foregroundStyle: foregroundColor,
          backgroundStyle: isCurrentUser ? AnyShapeStyle(.tint) : AnyShapeStyle(.background),
          onCopy: {
            UIPasteboard.general.string = message.trimmingCharacters(in: .whitespacesAndNewlines)
          }
        ) {
          Text(message.trimmingCharacters(in: .whitespacesAndNewlines).attributedMarkdown)
            .fixedSize(horizontal: false, vertical: true)
        }
      } else {
        // The model writes its own inline citations as markdown links, and they are the same
        // links whether the message is still streaming or finished - so nothing rearranges itself
        // when the reply completes.
        Text(message.trimmingCharacters(in: .whitespacesAndNewlines).attributedMarkdown)
          .fixedSize(horizontal: false, vertical: true)
          .padding(.vertical, 10)
          .padding(.horizontal, 15)
          .horizontalAlignment(.leading)
          .contextMenu {
            Button("Copy", systemSymbol: .documentOnDocument) {
              UIPasteboard.general.string = message.trimmingCharacters(in: .whitespacesAndNewlines)
            }
          }

        if showsControlRow {
          HStack(spacing: 16) {
            if showReportButton, responseID != nil, requestID != nil {
              Button("Report a Problem") {
                showReportSheet = true
              }
              .bold()
              .font(.caption)
            }

            if sources.isNotEmpty {
              ChatSourcesFooter(sources: sources) {
                showSourcesSheet = true
              }
            }
          }
          .padding(.horizontal, 15)
        }
      }
    }
    .environment(\.openURL, OpenURLAction { url in
      // Links in a reply stay inside the app: bouncing to Safari drops the user out of the
      // conversation they were reading.
      SafariPresenter.open(url, tint: themeController.theme.color)
      return .handled
    })
    .sheet(isPresented: $showSourcesSheet) {
      ChatSourcesSheet(sources: sources)
    }
    .fullScreenCover(isPresented: $showReportSheet) {
      if let responseID = responseID,
         let requestID = requestID {
        ChatReportReviewView(
          responseID: responseID,
          requestID: requestID
        )
        .environment(themeController)
      }
    }
  }
}

private extension ChatBubbleCell {

  var foregroundColor: Color {
    switch (isCurrentUser, isDirect) {
    case (true, true):
      return Color(uiColor: .label)
    case (true, false):
      return .white
    case (false, true):
      return Color(uiColor: .label)
    case (false, false):
      return Color(uiColor: .label)
    }
  }
}

#Preview {
  PreviewEnvironment {
    ScrollView {
      VStack {
        ChatBubbleCell(message: "Hey buddy!", isDirect: false, isCurrentUser: true, showTail: true)
        ChatBubbleCell(message: "Hey, how's it going?", isDirect: false, isCurrentUser: false, showTail: true)
        ChatBubbleCell(message: "It's actually going great!", isDirect: false, isCurrentUser: true, showTail: true)
        ChatBubbleCell(message: "PS It's actually not going great...", isDirect: true, isCurrentUser: true, showTail: true)
        ChatBubbleCell(
          message: "Oh no what's up? Is there a problem I can help you solve?", 
          isDirect: true, 
          isCurrentUser: false, 
          showTail: true, 
          showReportButton: true,
          responseID: "response_123",
          requestID: "request_456"
        )
      }
    }
    .groupedBackground()
  }
}

#Preview("Screenshots") {
  PreviewEnvironment {
    VStack(spacing: 30) {
      ChatBubbleCell(
        message: "I feel tired all the time, what can I do to get my energy up?",
        isDirect: false,
        isCurrentUser: true,
        showTail: true
      )

      ChatBubbleCell(
        message: "What should I eat from this restaurant?",
        isDirect: false,
        isCurrentUser: true,
        showTail: true
      )

      ChatBubbleCell(
        message: "What's a good lower body workout for me that doesn't irritate my sprained ankle?",
        isDirect: false,
        isCurrentUser: true,
        showTail: true
      )

      ChatBubbleCell(
        message: "Can you help me build up to a marathon?",
        isDirect: false,
        isCurrentUser: true,
        showTail: true
      )

      VStack {
        ChatImageCell(
          image: UIImage(named: "CrackersAndCheese")!,
          isCurrentUser: true
        )
        ChatBubbleCell(
          message: "I just ate this for dinner.",
          isDirect: false,
          isCurrentUser: true,
          showTail: true
        )
      }
    }
    .bold()
    .frame(maxWidth: 340)
  }
}
