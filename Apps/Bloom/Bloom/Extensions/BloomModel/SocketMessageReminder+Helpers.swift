//
//  SocketMessageReminder+Helpers.swift
//  Bloom
//
//  Created by Claude on 2025-06-04.
//

import BloomModel
import DataContainer

extension SocketMessage.CadenceType {
  var asReminderCadenceType: SchemaV18.ReminderCadenceType {
    switch self {
    case .daily:
      return .daily
    case .weekly:
      return .weekly
    case .monthly:
      return .monthly
    case .yearly:
      return .yearly
    }
  }
}

extension SocketMessage.Weekday {
  var asWeekdayInt: Int {
    switch self {
    case .sunday:
      return 1
    case .monday:
      return 2
    case .tuesday:
      return 3
    case .wednesday:
      return 4
    case .thursday:
      return 5
    case .friday:
      return 6
    case .saturday:
      return 7
    }
  }
}

extension SocketMessage.Month {
  var asMonthInt: Int {
    switch self {
    case .january:
      return 1
    case .february:
      return 2
    case .march:
      return 3
    case .april:
      return 4
    case .may:
      return 5
    case .june:
      return 6
    case .july:
      return 7
    case .august:
      return 8
    case .september:
      return 9
    case .october:
      return 10
    case .november:
      return 11
    case .december:
      return 12
    }
  }
}

extension SocketMessage.CreateReminder {
  func asReminderDTO() -> ReminderDTO {
    ReminderDTO(
      persistentModelID: nil,
      id: self.id ?? UUID().uuidString,
      createdDate: Date(),
      modifiedDate: Date(),
      title: self.title,
      colorHex: self.color,
      occurrences: self.occurrences.map { $0.asReminderOccurrenceDTO() },
      completionRecords: []
    )
  }
}

extension SocketMessage.ReminderOccurrence {
  func asReminderOccurrenceDTO() -> ReminderOccurrenceDTO {
    ReminderOccurrenceDTO(
      persistentModelID: nil,
      id: UUID().uuidString,
      cadenceType: self.cadenceType.asReminderCadenceType,
      timeOfDay: TimeInterval(self.hour * 3600 + self.minute * 60),
      daysOfWeek: self.daysOfWeek?.map { $0.asWeekdayInt },
      dayOfMonth: self.dayOfMonth,
      monthOfYear: self.monthOfYear?.asMonthInt,
      dayOfYear: self.dayOfYear
    )
  }
}