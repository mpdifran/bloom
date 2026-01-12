//
//  Reminder+Preview.swift
//  Bloom
//
//  Created by Assistant on 2025-06-04.
//

import DataContainer

extension Reminder {
  enum Preview { }
}

@MainActor
extension Reminder.Preview {
  static let dailyVitamins = Reminder(
    title: "Take vitamins",
    colorHex: "51CF66",
    occurrences: [
      ReminderOccurrence(
        cadenceType: .daily,
        timeOfDay: 9 * 3600 // 9 AM
      )
    ],
    sideEffects: [
      ReminderSideEffect.Preview.logVitamins
    ]
  )
  
  static let weeklyWaterPlants = Reminder(
    title: "Water plants",
    colorHex: "FF6B35",
    occurrences: [
      ReminderOccurrence(
        cadenceType: .weekly,
        timeOfDay: 10 * 3600, // 10 AM
        daysOfWeek: [1, 5] // Monday and Friday
      )
    ]
  )
  
  static let monthlyPayRent = Reminder(
    title: "Pay rent",
    colorHex: "E74C3C",
    occurrences: [
      ReminderOccurrence(
        cadenceType: .monthly,
        timeOfDay: 8 * 3600, // 8 AM
        dayOfMonth: 1
      )
    ]
  )
}
