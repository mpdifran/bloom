//
//  WatchReminderCompletionData.swift
//  BloomFoundation
//
//  Created by Mark DiFranco on 2026-01-30.
//

import Foundation

/// Message sent from watch to phone to complete/uncomplete a reminder
public struct WatchReminderCompletionMessage: Codable, Sendable {
  public static let messageType = "reminderCompletion"

  public let type: String
  public let reminderID: String
  public let occurrenceID: String
  public let completionDate: Date
  public let action: CompletionAction

  public enum CompletionAction: String, Codable, Sendable {
    case complete
    case uncomplete
  }

  public init(
    reminderID: String,
    occurrenceID: String,
    completionDate: Date = Date(),
    action: CompletionAction
  ) {
    self.type = Self.messageType
    self.reminderID = reminderID
    self.occurrenceID = occurrenceID
    self.completionDate = completionDate
    self.action = action
  }
}

/// Response from phone after processing a reminder completion
public struct WatchReminderCompletionResponse: Codable, Sendable {
  public let success: Bool
  public let reminderID: String
  public let isNowCompleted: Bool

  public init(success: Bool, reminderID: String, isNowCompleted: Bool) {
    self.success = success
    self.reminderID = reminderID
    self.isNowCompleted = isNowCompleted
  }
}
