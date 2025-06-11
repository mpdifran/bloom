//
//  ChatIssueReportsView.swift
//  Gardener
//
//  Created by Mark DiFranco on 2025-06-11.
//

import AdminBloomModel
import SwiftUI

struct ChatIssueReportsView: View {
  @ObservedObject private var store = ChatIssueReportsStore.shared
  @State private var selectedReport: AdminChatIssueReport?
  
  var body: some View {
    List(store.reports, selection: $selectedReport) { report in
      NavigationLink {
        ChatIssueReportDetailView(report: report)
      } label: {
        ChatIssueReportRow(report: report)
          .tag(report)
      }
      .onAppear {
        if report == store.reports.last {
          Task {
            await store.loadMoreIfNeeded()
          }
        }
      }
    }
    .navigationSplitViewColumnWidth(min: 300, ideal: 400, max: 500)
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        refreshButton
      }
    }
    .task {
      await store.loadReports(refresh: true)
    }
    .overlay {
      if store.reports.isEmpty && !store.isLoading {
        ContentUnavailableView(
          "No Reports",
          systemImage: "exclamationmark.triangle",
          description: Text("No chat issue reports have been submitted yet.")
        )
      }
    }
  }
}

private extension ChatIssueReportsView {
  var refreshButton: some View {
    Button {
      Task {
        await store.loadReports(refresh: true)
      }
    } label: {
      Image(systemName: "arrow.clockwise")
    }
    .disabled(store.isLoading)
  }
}

struct ChatIssueReportRow: View {
  let report: AdminChatIssueReport
  
  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        Text("Report \(report.id.prefix(8))")
          .font(.headline)
          .fontDesign(.monospaced)
        
        Spacer()
        
        Text(report.createdAt, style: .relative)
          .font(.caption)
          .foregroundColor(.secondary)
      }
      
      HStack {
        Label(
          report.isAnonymous ? "Anonymous" : (report.userName ?? "Unknown User"),
          systemImage: report.isAnonymous ? "person.slash" : "person"
        )
        .font(.caption)
        
        Spacer()
        
        Text("Response \(report.responseID.prefix(8))")
          .font(.caption)
          .fontDesign(.monospaced)
          .foregroundColor(.secondary)
      }
      
      if let notes = report.notes, !notes.isEmpty {
        Text(notes)
          .font(.caption)
          .lineLimit(3)
          .foregroundColor(.secondary)
      }
    }
    .padding(.vertical, 4)
  }
}

#Preview {
  NavigationSplitView {
    ChatIssueReportsView()
  } detail: {
    Text("Select a report")
  }
}
