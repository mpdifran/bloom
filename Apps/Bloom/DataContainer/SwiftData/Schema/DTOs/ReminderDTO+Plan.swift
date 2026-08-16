//
//  ReminderDTO+Plan.swift
//  DataContainer
//

import Foundation
import BloomFoundation

public extension ReminderOccurrenceDTO {
  /// The persistence-free repeat rule, for the shared scheduling engine.
  var asRule: ReminderOccurrenceRule {
    ReminderOccurrenceRule(
      id: id,
      cadence: ReminderCadence(rawValue: cadenceType.rawValue) ?? .daily,
      timeOfDay: timeOfDay,
      daysOfWeek: daysOfWeek,
      dayOfMonth: dayOfMonth,
      monthOfYear: monthOfYear,
      dayOfYear: dayOfYear
    )
  }
}

public extension ReminderDTO {
  /// The persistence-free form of this reminder, for the shared scheduling engine and for syncing
  /// to the watch.
  ///
  /// - Parameter completionsSince: only completions on or after this date are carried, since the
  ///   watch only ever needs today's to decide what's outstanding.
  func asPlan(completionsSince: Date? = nil) -> ReminderPlan {
    let completions = completionRecords
      .filter { record in
        guard let completionsSince else { return true }
        return record.completedDate >= completionsSince
      }
      .map { ReminderCompletionMark(occurrenceID: $0.occurrenceID, completedDate: $0.completedDate) }

    return ReminderPlan(
      id: id,
      title: title,
      colorHex: colorHex,
      occurrences: occurrences.map(\.asRule),
      completions: completions
    )
  }
}
