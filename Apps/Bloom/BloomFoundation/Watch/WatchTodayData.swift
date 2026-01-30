//
//  WatchTodayData.swift
//  BloomFoundation
//
//  Created by Mark DiFranco on 2026-01-30.
//

import Foundation

/// Lightweight today's data for watch synchronization.
/// Contains only the data needed by the watchOS UI.
public struct WatchTodayData: Codable, Sendable {
  public let todaysAdvice: String?
  public let reminders: [WatchReminderData]
  public let lastUpdated: Date

  public init(
    todaysAdvice: String?,
    reminders: [WatchReminderData],
    lastUpdated: Date = Date()
  ) {
    self.todaysAdvice = todaysAdvice
    self.reminders = reminders
    self.lastUpdated = lastUpdated
  }
}

/// Lightweight reminder data for watch display
public struct WatchReminderData: Codable, Sendable, Identifiable, Equatable {
  public let reminderID: String
  public let title: String
  public let colorHex: String
  public let scheduledTime: Date
  public let occurrenceID: String
  public var isCompleted: Bool
  public var status: WatchReminderStatus
  public var completionDate: Date?

  /// Computed id for Identifiable - matches iOS ReminderOccurrenceDisplay pattern
  public var id: String { "\(reminderID)-\(occurrenceID)-\(scheduledTime.timeIntervalSince1970)" }

  public init(
    reminderID: String,
    title: String,
    colorHex: String,
    scheduledTime: Date,
    occurrenceID: String,
    isCompleted: Bool,
    status: WatchReminderStatus,
    completionDate: Date? = nil
  ) {
    self.reminderID = reminderID
    self.title = title
    self.colorHex = colorHex
    self.scheduledTime = scheduledTime
    self.occurrenceID = occurrenceID
    self.isCompleted = isCompleted
    self.status = status
    self.completionDate = completionDate
  }

  // Custom CodingKeys to maintain JSON compatibility
  enum CodingKeys: String, CodingKey {
    case reminderID = "id"
    case title, colorHex, scheduledTime, occurrenceID, isCompleted, status, completionDate
  }
}

/// Status of a reminder for display purposes
public enum WatchReminderStatus: String, Codable, Sendable {
  case upcoming   // Scheduled time is in the future
  case dueNow     // Within 15 minutes of scheduled time
  case overdue    // Past scheduled time and not completed
  case completed  // Completed for today
}
