//
//  ChatReportReviewView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-06-11.
//

import SwiftUI
import DataContainer
import SwiftData
import BloomModel
import BloomFoundation
import SFSafeSymbols
import AppUI

struct ChatReportReviewView: View {
  let responseID: String
  let requestID: String

  @State private var messages: [ChatMessageDTO] = []
  @State private var isAnonymous = false
  @State private var notes = ""
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        BloomScrollView(showsChatBar: false, padding: .vertical) {
          warningSection
            .padding(.horizontal)

          ForEach(messages) { message in
            ChatMessageBubbleView(message: message)
          }
        }
      }
      .navigationTitle("Report a Problem")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
      }
      .shelf {
        VStack {
          notesSection

          Toggle("Submit Anonymously", isOn: $isAnonymous)
            .bold()
            .fontDesign(.rounded)
            .toggleStyle(.switch)
            .padding(.vertical, 8)
            .padding(.horizontal)

          AsyncButton {
            try await submitReport()
          } label: {
            Text("Submit Report")
              .horizontallyCentered()
          }
          .buttonStyle(.primary)
        }
      }
      .task {
        await loadMessages()
      }
      .presentationCompactAdaptation(.fullScreenCover)
    }
  }
}

private extension ChatReportReviewView {

  var notesSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Additional Details (optional)")
        .font(.headline)
      
      TextField(
        "Describe what went wrong...",
        text: $notes,
        axis: .vertical
      )
      .lineLimit(3...6)
    }
    .cardContainer(fill: .background)
  }

  var warningSection: some View {
    VStack {
      Image(systemSymbol: .infoCircleFill)
        .font(.system(size: 40))
        .foregroundStyle(.white, .tint)

      Text("The following message content will be submitted with the report.")
        .horizontalAlignment(.leading)
    }
    .horizontallyCentered()
    .cardContainer()
  }
}

private extension ChatReportReviewView {
  
  func loadMessages() async {
    let modelContext = ContainerHolder.shared.createContext()
    
    await MainActor.run {
      do {
        let descriptor = FetchDescriptor<ChatMessage>(
          predicate: #Predicate<ChatMessage> { message in
            message.requestID == requestID
          },
          sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        
        let chatMessages = try modelContext.fetch(descriptor)
        self.messages = chatMessages.map { $0.asDTO() }
      } catch {
        print("Failed to load messages: \(error)")
      }
    }
  }
  
  func submitReport() async throws {
    let request = SubmitChatMessageIssueRequest(
      responseID: responseID,
      notes: notes.isEmpty ? nil : notes,
      isAnonymous: isAnonymous,
      appVersion: Bundle.main.appVersion
    )

    try await NetworkRequester.shared.submitChatMessageIssueReport(request: request)

    await MainActor.run {
      SoundPlayer.playSenderConfirmation()
      dismiss()
    }
  }
}

struct ChatMessageBubbleView: View {
  let message: ChatMessageDTO
  
  var body: some View {
    switch message.content {
    case .message(let text):
      ChatBubbleCell(
        message: text,
        isDirect: false,
        isCurrentUser: message.isCurrentUser,
        showTail: true
      )
    case .imageData(let imageData):
      if let image = UIImage(data: imageData) {
        ChatImageCell(
          image: image,
          isCurrentUser: message.isCurrentUser
        )
      }
    case .richContent(let data):
      ChatRichContentWrapperCell(
        chatMessageID: message.id,
        data: data,
        hasPerformedAction: message.hasPerformedAction,
        dbID: message.dbID
      )
    @unknown default:
      EmptyView()
    }
  }
}

#Preview {
  PreviewEnvironment {
    ChatReportReviewView(
      responseID: "response_123",
      requestID: "request_456"
    )
  }
}
