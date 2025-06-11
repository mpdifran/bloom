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
  
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        headerSection
        
        identificationSection
        
        if let notes = report.notes, !notes.isEmpty {
          notesSection(notes)
        }
        
        technicalDetailsSection
      }
      .padding()
    }
    .navigationTitle("Issue Report")
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
}

#Preview {
  ChatIssueReportDetailView(
    report: AdminChatIssueReport(
      id: "issue_123456789",
      responseID: "response_987654321",
      notes: "The AI response was not helpful and contained incorrect information about nutrition facts.",
      isAnonymous: false,
      userID: UserIdentifier("user_555"),
      createdAt: Date()
    )
  )
}
