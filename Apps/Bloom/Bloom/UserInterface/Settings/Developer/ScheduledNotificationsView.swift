//
//  ScheduledNotificationsView.swift
//  Bloom
//
//  Created by Claude on 2025-01-18.
//

import SwiftUI
import UserNotifications
import SFSafeSymbols
import AppUI

struct NotificationInfo: Identifiable {
  let id: String
  let title: String
  let body: String
  let triggerDate: Date?
  let categoryID: String
  let triggerDescription: String
  
  init(from request: UNNotificationRequest) {
    self.id = request.identifier
    self.title = request.content.title
    self.body = request.content.body.isEmpty ? request.content.subtitle : request.content.body
    self.categoryID = request.content.categoryIdentifier
    
    // Extract trigger information
    if let calendarTrigger = request.trigger as? UNCalendarNotificationTrigger {
      let components = calendarTrigger.dateComponents
      self.triggerDate = Calendar.current.date(from: components)
      self.triggerDescription = "Calendar: \(formatDateComponents(components))"
    } else if let intervalTrigger = request.trigger as? UNTimeIntervalNotificationTrigger {
      self.triggerDate = Date().addingTimeInterval(intervalTrigger.timeInterval)
      self.triggerDescription = "Interval: \(Int(intervalTrigger.timeInterval))s"
    } else if request.trigger == nil {
      self.triggerDate = Date()
      self.triggerDescription = "Immediate"
    } else {
      self.triggerDate = nil
      self.triggerDescription = "Unknown trigger type"
    }
  }
}

private func formatDateComponents(_ components: DateComponents) -> String {
  let formatter = DateFormatter()
  formatter.dateStyle = .medium
  formatter.timeStyle = .short
  
  if let date = Calendar.current.date(from: components) {
    return formatter.string(from: date)
  } else {
    var parts: [String] = []
    if let month = components.month { parts.append("M:\(month)") }
    if let day = components.day { parts.append("D:\(day)") }
    if let hour = components.hour { parts.append("H:\(hour)") }
    if let minute = components.minute { parts.append("m:\(minute)") }
    return parts.joined(separator: " ")
  }
}

struct ScheduledNotificationsView: View {
  @State private var notifications: [NotificationInfo] = []
  @State private var isLoading = false
  @State private var lastRefresh = Date()
  
  @Environment(\.dismiss) private var dismiss
  
  var body: some View {
    NavigationStack {
      Group {
        if isLoading {
          ProgressView("Loading notifications...")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if notifications.isEmpty {
          emptyStateView
        } else {
          notificationsList
        }
      }
      .navigationTitle("Scheduled Notifications")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Done") {
            dismiss()
          }
          .bold()
        }
        
        ToolbarItem(placement: .primaryAction) {
          Button {
            Task {
              await loadNotifications()
            }
          } label: {
            Image(systemSymbol: .arrowClockwise)
          }
        }
      }
      .task {
        await loadNotifications()
      }
    }
    .presentationCornerRadius(30)
    .presentationDragIndicator(.visible)
  }
  
  private var emptyStateView: some View {
    VStack(spacing: 16) {
      Image(systemSymbol: .bellSlash)
        .font(.system(size: 48))
        .foregroundStyle(.secondary)
      
      Text("No Scheduled Notifications")
        .font(.title2)
        .bold()
      
      Text("There are currently no pending notifications scheduled for this app.")
        .font(.body)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal)
      
      Text("Last checked: \(lastRefresh.formatted(date: .omitted, time: .shortened))")
        .font(.caption)
        .foregroundStyle(.tertiary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
  
  private var notificationsList: some View {
    ScrollView {
      LazyVStack(spacing: 12) {
        ForEach(notifications) { notification in
          NotificationRow(notification: notification)
        }
      }
      .padding()
    }
  }
  
  private func loadNotifications() async {
    isLoading = true
    defer { isLoading = false }
    
    do {
      let center = UNUserNotificationCenter.current()
      let pendingRequests = await center.pendingNotificationRequests()
      
      await MainActor.run {
        self.notifications = pendingRequests
          .map { NotificationInfo(from: $0) }
          .sorted { first, second in
            // Sort by trigger date, with nil dates (immediate) first
            if let firstDate = first.triggerDate, let secondDate = second.triggerDate {
              return firstDate < secondDate
            } else if first.triggerDate == nil && second.triggerDate != nil {
              return true
            } else if first.triggerDate != nil && second.triggerDate == nil {
              return false
            } else {
              return first.id < second.id
            }
          }
        self.lastRefresh = Date()
      }
    }
  }
}

struct NotificationRow: View {
  let notification: NotificationInfo
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      // Header with title and category
      HStack {
        Text(notification.title.isEmpty ? "No Title" : notification.title)
          .font(.headline)
          .foregroundStyle(notification.title.isEmpty ? .secondary : .primary)
        
        Spacer()
        
        Text(notification.categoryID.isEmpty ? "No Category" : notification.categoryID)
          .font(.caption)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(.secondary.opacity(0.2))
          .clipShape(Capsule())
      }
      
      // Body text
      if !notification.body.isEmpty {
        Text(notification.body)
          .font(.body)
          .foregroundStyle(.secondary)
      }
      
      // Trigger info
      HStack {
        Image(systemSymbol: .clock)
          .font(.caption)
          .foregroundStyle(.tertiary)
        
        Text(notification.triggerDescription)
          .font(.caption)
          .foregroundStyle(.tertiary)
        
        Spacer()
        
        Text("ID: \(notification.id)")
          .font(.caption2)
          .foregroundStyle(.quaternary)
      }
    }
    .padding()
    .background(.background.secondary)
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }
}

#Preview {
  ScheduledNotificationsView()
}