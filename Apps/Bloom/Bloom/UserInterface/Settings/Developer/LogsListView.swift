//
//  LogsListView.swift
//  Bloom
//
//  Created by Assistant on 2025-01-26.
//

import SwiftUI
import SFSafeSymbols
import AppUI

struct LogsListView: View {
  @ObservedObject private var logManager = LogManager.shared
  @State private var selectedTag: LogTag?
  @State private var searchText = ""
  @State private var alertDetails: AlertDetails?
  @State private var presentedSheet: AnyView?

  var body: some View {
    NavigationStack {
      Group {
        if filteredLogs.isEmpty {
          emptyStateView
        } else {
          logsList
        }
      }
      .navigationTitle("Debug Logs")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          DismissButton()
        }

        ToolbarItem(placement: .primaryAction) {
          Button {
            let json = logManager.exportLogsAsJSON()
            UIPasteboard.general.string = json
            alertDetails = AlertDetails(
              title: "Copied to Clipboard",
              message: "All logs have been copied as JSON."
            )
          } label: {
            Image(systemSymbol: .documentOnDocument)
          }
          .buttonStyle(.plain)
        }

        ToolbarItem(placement: .primaryAction) {
          Button {
            presentedSheet = LogTagFilterView(selectedTag: $selectedTag).asAny
          } label: {
            Image(systemSymbol: .line3HorizontalDecrease)
          }
          .buttonStyle(.plain)
        }
      }
      .searchable(text: $searchText, prompt: "Search logs")
      .sheet($presentedSheet)
      .alert(alertDetails: $alertDetails)
    }
    .presentationCornerRadius(30)
    .presentationDragIndicator(.visible)
  }

  private var emptyStateView: some View {
    VStack(spacing: 16) {
      Image(systemSymbol: .textPageBadgeMagnifyingglass)
        .font(.system(size: 48))
        .foregroundStyle(.secondary)

      Text("No Logs")
        .font(.title2)
        .bold()

      Text(searchText.isEmpty ? "No debug logs have been recorded yet." : "No logs match your search.")
        .font(.body)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var logsList: some View {
    BloomScrollView {
      LazyVStack(spacing: 12) {
        ForEach(filteredLogs) { log in
          LogRow(log: log)
        }
      }
    }
  }

  private var filteredLogs: [LogEntry] {
    logManager.logs
      .filter { log in
        // Filter by tag
        if let selectedTag, log.tag != selectedTag {
          return false
        }

        // Filter by search text
        if !searchText.isEmpty {
          return log.message.localizedCaseInsensitiveContains(searchText)
            || log.tag.rawValue.localizedCaseInsensitiveContains(searchText)
        }

        return true
      }
      .reversed() // Show newest first
  }
}

struct LogRow: View {
  let log: LogEntry

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      // Header with tag and timestamp
      HStack {
        Text("[\(log.tag.rawValue)]")
          .font(.caption)
          .fontWeight(.semibold)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(.blue.opacity(0.2))
          .foregroundStyle(.blue)
          .clipShape(Capsule())

        Spacer()

        Text(log.timestamp, style: .time)
          .font(.caption)
          .foregroundStyle(.tertiary)
      }

      // Message
      Text(log.message)
        .font(.body)
        .foregroundStyle(.primary)

      // Full timestamp at bottom
      Text(log.timestamp.formatted(date: .abbreviated, time: .standard))
        .font(.caption2)
        .foregroundStyle(.quaternary)
    }
    .padding()
    .background(.background.secondary)
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }
}

#Preview {
  PreviewEnvironment {
    LogsListView()
  }
}
