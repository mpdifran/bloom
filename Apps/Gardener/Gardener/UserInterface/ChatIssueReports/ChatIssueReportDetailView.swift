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
  
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        headerSection
        
        identificationSection
        
        if let notes = report.notes, !notes.isEmpty {
          notesSection(notes)
        }
        
        technicalDetailsSection
        
        messagesSection
      }
      .padding()
    }
    .navigationTitle("Issue Report")
    .task {
      await loadMessages()
    }
  }
}

private extension ChatIssueReportDetailView {
  
  var headerSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Report ID")
        .font(.headline)
        .foregroundColor(.secondary)
      
      Text(report.id)
        .font(.system(.body, design: .monospaced))
        .textSelection(.enabled)
      
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
        
        Text(report.isAnonymous ? "Anonymous Submission" : "Identified User")
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
  
  var technicalDetailsSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Technical Details")
        .font(.headline)
        .foregroundColor(.secondary)
      
      VStack(alignment: .leading, spacing: 4) {
        HStack {
          Text("Response ID:")
            .fontWeight(.medium)
          Text(report.responseID)
            .font(.system(.body, design: .monospaced))
            .textSelection(.enabled)
        }
      }
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
          ForEach(messages) { message in
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
      if message.role == "assistant" {
        messageBubble
          .frame(maxWidth: 500, alignment: .leading)
        Spacer()
      } else {
        Spacer()
        messageBubble
          .frame(maxWidth: 500, alignment: .trailing)
      }
    }
  }
  
  private var messageBubble: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(message.role == "user" ? "User" : "Assistant")
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
    .background(
      message.role == "user" 
        ? Color.blue.opacity(0.1) 
        : Color(.controlBackgroundColor)
    )
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
      createdAt: Date()
    )
  )
}
