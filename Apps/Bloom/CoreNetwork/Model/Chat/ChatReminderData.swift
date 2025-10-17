//
//  ChatReminderData.swift
//  Bloom
//
//  Created by Claude on 2025-06-04.
//

import Foundation

public struct ChatReminderData: SendableNetworkModel {
  public let reminders: [Reminder]

  public init(reminders: [Reminder]) {
    self.reminders = reminders
  }
}

extension ChatReminderData {
  public struct Reminder: SendableNetworkModel {
    public let id: String
    public let title: String
    public let color: String
    public let createdDate: Date
    public let modifiedDate: Date
    public let occurrences: [Occurrence]
    public let completions: [Completion]

    public init(
      id: String,
      title: String,
      color: String,
      createdDate: Date,
      modifiedDate: Date,
      occurrences: [Occurrence],
      completions: [Completion]
    ) {
      self.id = id
      self.title = title
      self.color = color
      self.createdDate = createdDate
      self.modifiedDate = modifiedDate
      self.occurrences = occurrences
      self.completions = completions
    }
  }

  public struct Occurrence: SendableNetworkModel {
    public let id: String
    public let cadenceType: String
    public let timeOfDay: String
    public let daysOfWeek: [String]?
    public let dayOfMonth: Int?
    public let monthOfYear: String?
    public let dayOfYear: Int?

    public init(
      id: String,
      cadenceType: String,
      timeOfDay: String,
      daysOfWeek: [String]?,
      dayOfMonth: Int?,
      monthOfYear: String?,
      dayOfYear: Int?
    ) {
      self.id = id
      self.cadenceType = cadenceType
      self.timeOfDay = timeOfDay
      self.daysOfWeek = daysOfWeek
      self.dayOfMonth = dayOfMonth
      self.monthOfYear = monthOfYear
      self.dayOfYear = dayOfYear
    }
  }

  public struct Completion: SendableNetworkModel {
    public let id: String
    public let completedDate: Date

    public init(id: String, completedDate: Date) {
      self.id = id
      self.completedDate = completedDate
    }
  }
}