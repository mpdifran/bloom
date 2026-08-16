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
  /// Reminder occurrences as the phone resolved them at `lastUpdated`.
  ///
  /// Kept so a watch app older than the phone app still has something to show; current watch
  /// builds resolve `reminderPlans` themselves instead. Optional on the wire in both directions.
  public let reminders: [WatchReminderData]
  /// Raw reminder rules, for the watch to resolve against its own clock.
  public let reminderPlans: [ReminderPlan]?
  public let lastUpdated: Date

  public init(
    todaysAdvice: String?,
    reminders: [WatchReminderData],
    reminderPlans: [ReminderPlan]? = nil,
    lastUpdated: Date = Date()
  ) {
    self.todaysAdvice = todaysAdvice
    self.reminders = reminders
    self.reminderPlans = reminderPlans
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

public extension WatchReminderData {
  /// Renders a resolved occurrence into the legacy wire/display shape.
  init(slot: ReminderSlot) {
    self.init(
      reminderID: slot.reminderID,
      title: slot.title,
      colorHex: slot.colorHex,
      scheduledTime: slot.scheduledTime,
      occurrenceID: slot.occurrenceID,
      isCompleted: slot.isCompleted,
      status: slot.status,
      completionDate: slot.completionDate
    )
  }
}

/// Status of a reminder for display purposes.
///
/// The watch and the phone share one status type; this name stays for the existing call sites.
public typealias WatchReminderStatus = ReminderStatus
