//
//  ChatReminderData.swift
//  Bloom
//
//  Created by Claude on 2025-06-04.
//

import Foundation

struct ChatReminderData: SendableNetworkModel {
  let reminders: [Reminder]
}

extension ChatReminderData {
  struct Reminder: SendableNetworkModel {
    let id: String
    let title: String
    let color: String
    let createdDate: Date
    let modifiedDate: Date
    let occurrences: [Occurrence]
    let completions: [Completion]
  }
  
  struct Occurrence: SendableNetworkModel {
    let id: String
    let cadenceType: String
    let timeOfDay: String
    let daysOfWeek: [String]?
    let dayOfMonth: Int?
    let monthOfYear: String?
    let dayOfYear: Int?
  }
  
  struct Completion: SendableNetworkModel {
    let id: String
    let completedDate: Date
  }
}