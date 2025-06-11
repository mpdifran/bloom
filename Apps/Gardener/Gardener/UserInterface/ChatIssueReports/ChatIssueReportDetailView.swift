//
//  ChatIssueReportDetailView.swift
//  Gardener
//
//  Created by Mark DiFranco on 2025-06-11.
//

import AdminBloomModel
import SwiftUI

struct ChatIssueReportDetailView: View {
  let report: AdminChatIssueReport
  
  @State private var messages: [AdminChatMessage] = []
  @State private var isLoadingMessages = false
  @State private var messagesError: Error?
  @State private var selectedRoles: Set<String> = ["user", "assistant", "system", "admin"]
  
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        headerSection
        
        identificationSection
        
        if let notes = report.notes, !notes.isEmpty {
          notesSection(notes)
        }
        
        messagesSection
      }
      .padding()
    }
    .navigationTitle("Issue Report")
    .shelf {
      filterToolbar
    }
    .task {
      await loadMessages()
    }
  }
}

private extension ChatIssueReportDetailView {
  
  var headerSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Report Details")
        .font(.headline)
        .foregroundColor(.secondary)
      
      VStack(alignment: .leading, spacing: 4) {
        HStack {
          Text("Report ID:")
            .fontWeight(.medium)
          Text(report.id)
            .font(.system(.body, design: .monospaced))
            .textSelection(.enabled)
        }
        
        HStack {
          Text("Response ID:")
            .fontWeight(.medium)
          Text(report.responseID)
            .font(.system(.body, design: .monospaced))
            .textSelection(.enabled)
        }
      }
      
      Text("Submitted \(report.createdAt.formatted(date: .abbreviated, time: .shortened))")
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
    .background(Color(.controlBackgroundColor))
    .cornerRadius(8)
  }
  
  var identificationSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("User Information")
        .font(.headline)
        .foregroundColor(.secondary)
      
      HStack {
        Image(systemName: report.isAnonymous ? "person.slash" : "person")
          .foregroundColor(report.isAnonymous ? .orange : .blue)
        
        Text(report.isAnonymous ? "Anonymous" : (report.userName ?? "Unknown User"))
          .fontWeight(.medium)
        
        Spacer()
      }
      
      if let userID = report.userID, !report.isAnonymous {
        Text("User ID: \(userID.value)")
          .font(.system(.caption, design: .monospaced))
          .foregroundColor(.secondary)
          .textSelection(.enabled)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
    .background(Color(.controlBackgroundColor))
    .cornerRadius(8)
  }
  
  func notesSection(_ notes: String) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("User Notes")
        .font(.headline)
        .foregroundColor(.secondary)
      
      Text(notes)
        .font(.body)
        .textSelection(.enabled)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
    .background(Color(.controlBackgroundColor))
    .cornerRadius(8)
  }
  
  
  var messagesSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Chat Messages")
        .font(.headline)
        .foregroundColor(.secondary)
      
      if isLoadingMessages {
        HStack {
          ProgressView()
            .scaleEffect(0.8)
          Text("Loading messages...")
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
      } else if let error = messagesError {
        VStack(alignment: .leading, spacing: 4) {
          Label("Failed to load messages", systemImage: "exclamationmark.triangle")
            .foregroundColor(.red)
          Text(error.localizedDescription)
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
      } else if messages.isEmpty {
        Text("No messages available")
          .font(.body)
          .foregroundColor(.secondary)
          .padding()
      } else {
        VStack(alignment: .leading, spacing: 12) {
          ForEach(filteredMessages) { message in
            MessageBubbleView(message: message)
          }
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
    .background(Color(.controlBackgroundColor))
    .cornerRadius(8)
  }
  
  var filterToolbar: some View {
    HStack {
      Text("Show:")
        .fontWeight(.medium)
      
      Spacer()
      
      ForEach(availableRoles, id: \.self) { role in
        Button(action: {
          toggleRole(role)
        }) {
          HStack(spacing: 4) {
            Image(systemName: selectedRoles.contains(role) ? "checkmark.circle.fill" : "circle")
              .foregroundColor(selectedRoles.contains(role) ? .blue : .secondary)
            Text(roleDisplayName(for: role))
              .foregroundColor(selectedRoles.contains(role) ? .primary : .secondary)
          }
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.horizontal)
  }
  
  var availableRoles: [String] {
    let roles = Set(messages.map { $0.role })
    return ["user", "assistant", "system", "admin"].filter { roles.contains($0) }
  }
  
  var filteredMessages: [AdminChatMessage] {
    messages.filter { selectedRoles.contains($0.role) }
  }
  
  func toggleRole(_ role: String) {
    if selectedRoles.contains(role) {
      selectedRoles.remove(role)
    } else {
      selectedRoles.insert(role)
    }
  }
  
  func roleDisplayName(for role: String) -> String {
    switch role {
    case "user":
      return "User"
    case "assistant":
      return "Assistant"
    case "system":
      return "System"
    case "admin":
      return "Admin"
    default:
      return role.capitalized
    }
  }
  
  func loadMessages() async {
    isLoadingMessages = true
    messagesError = nil
    
    do {
      let response = try await NetworkStack.shared.getChatIssueReportMessages(reportID: report.id)
      messages = response.messages
    } catch {
      messagesError = error
    }
    
    isLoadingMessages = false
  }
}

struct MessageBubbleView: View {
  let message: AdminChatMessage
  
  var body: some View {
    HStack {
      if !isLeftAligned {
        Spacer(minLength: 60)
      }
      messageBubble

      if isLeftAligned {
        Spacer(minLength: 60)
      }
    }
  }
  
  private var isLeftAligned: Bool {
    // Assistant messages align left, user, system, and admin messages align right
    message.role == "assistant"
  }
  
  private var roleDisplayName: String {
    switch message.role {
    case "user":
      return "User"
    case "assistant":
      return "Assistant"
    case "system":
      return "System"
    case "admin":
      return "Admin"
    default:
      return message.role.capitalized
    }
  }
  
  private var bubbleColor: Color {
    switch message.role {
    case "user":
      return Color.blue.opacity(0.1)
    case "admin":
      return Color.purple.opacity(0.1)
    case "system":
      return Color.orange.opacity(0.1)
    case "assistant":
      return Color(.controlBackgroundColor)
    default:
      return Color(.controlBackgroundColor)
    }
  }
  
  private var messageBubble: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(roleDisplayName)
        .font(.caption)
        .fontWeight(.medium)
        .foregroundColor(.secondary)

      if let content = message.content {
        Text(content)
          .font(.body)
          .textSelection(.enabled)
      } else if message.imageFileID != nil {
        Label("Image", systemImage: "photo")
          .font(.body)
          .foregroundColor(.secondary)
      }
    }
    .padding(12)
    .background(bubbleColor)
    .cornerRadius(12)
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .stroke(Color(.separatorColor), lineWidth: 1)
    )
  }
}

#Preview {
  ChatIssueReportDetailView(
    report: AdminChatIssueReport(
      id: "issue_123456789",
      responseID: "response_987654321",
      notes: "The AI response was not helpful and contained incorrect information about nutrition facts.",
      isAnonymous: false,
      userID: AdminBloomModel.UserIdentifier("user_555"),
      userName: "John Doe",
      createdAt: Date()
    )
  )
}
