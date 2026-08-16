//
//  ReminderOccurrenceDTO+Display.swift
//  Bloom
//
//  Created by Assistant on 2025-06-04.
//

import Foundation
import BloomFoundation

public struct ReminderOccurrenceDisplay: Identifiable {
  public let id: String
  public let reminder: ReminderDTO
  public let occurrence: ReminderOccurrenceDTO
  public let scheduledTime: Date
  public let isCompleted: Bool
  public let completionDate: Date?
  public let status: ReminderStatus

  public init(
    reminder: ReminderDTO,
    occurrence: ReminderOccurrenceDTO,
    scheduledTime: Date,
    isCompleted: Bool,
    completionDate: Date? = nil,
    status: ReminderStatus? = nil
  ) {
    self.id = "\(reminder.id)-\(occurrence.id)-\(scheduledTime.timeIntervalSince1970)"
    self.reminder = reminder
    self.occurrence = occurrence
    self.scheduledTime = scheduledTime
    self.isCompleted = isCompleted
    self.completionDate = completionDate
    self.status = status ?? ReminderSchedule.status(
      scheduledTime: scheduledTime,
      isCompleted: isCompleted,
      now: Date()
    )
  }
}

public extension ReminderDTO {
  /// Returns display items for today's occurrences, taking into account completions.
  ///
  /// The scheduling rules live in `ReminderSchedule` in BloomFoundation so the watch app resolves
  /// occurrences exactly the way this does.
  func todaysOccurrenceDisplays(now: Date = Date()) -> [ReminderOccurrenceDisplay] {
    let occurrencesByID = Dictionary(occurrences.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

    return ReminderSchedule.slots(for: asPlan(), now: now).compactMap { slot in
      guard let occurrence = occurrencesByID[slot.occurrenceID] else { return nil }

      return ReminderOccurrenceDisplay(
        reminder: self,
        occurrence: occurrence,
        scheduledTime: slot.scheduledTime,
        isCompleted: slot.isCompleted,
        completionDate: slot.completionDate,
        status: slot.status
      )
    }
  }
}

public extension ReminderOccurrenceDTO {
  /// Computed property that converts timeOfDay to a Date
  var time: Date {
    let calendar = Calendar.current
    let startOfDay = calendar.startOfDay(for: Date())
    return startOfDay.addingTimeInterval(timeOfDay)
  }
  
  /// Returns a human-readable description of this occurrence's cadence and time
  var cadenceDescription: String {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    formatter.dateStyle = .none
    
    let timeString = formatter.string(from: time)
    
    switch cadenceType {
    case .daily:
      return "Every day at \(timeString)"
      
    case .weekly:
      guard let days = daysOfWeek, !days.isEmpty else {
        return "Weekly at \(timeString)"
      }

      let sortedDays = days.sorted()
      
      // Check if all days are weekdays (Monday-Friday, which are 2-6 in iOS)
      let weekdays = Set([2, 3, 4, 5, 6])
      if Set(sortedDays) == weekdays {
        return "Weekdays at \(timeString)"
      }
      
      // Check if all days are weekends (Saturday-Sunday, which are 7 and 1 in iOS)
      let weekends = Set([1, 7])
      if Set(sortedDays) == weekends {
        return "Weekends at \(timeString)"
      }
      
      let dayNames = sortedDays.compactMap { Calendar.current.weekdaySymbols[safe: $0 - 1] }
      
      if dayNames.count == 1 {
        return "Every \(dayNames[0]) at \(timeString)"
      } else if dayNames.count == 2 {
        return "Every \(dayNames[0]) and \(dayNames[1]) at \(timeString)"
      } else {
        let allButLast = dayNames.dropLast()
        let commaSeparated = allButLast.joined(separator: ", ")
        return "Every \(commaSeparated), and \(dayNames.last!) at \(timeString)"
      }
      
    case .monthly:
      guard let day = dayOfMonth else {
        return "Monthly at \(timeString)"
      }
      
      let ordinal = NumberFormatter.ordinal.string(from: NSNumber(value: day)) ?? "\(day)"
      return "Every month on the \(ordinal) at \(timeString)"
      
    case .yearly:
      guard let month = monthOfYear, let day = dayOfYear else {
        return "Yearly at \(timeString)"
      }
      
      let monthName = Calendar.current.monthSymbols[safe: month - 1] ?? ""
      let ordinal = NumberFormatter.ordinal.string(from: NSNumber(value: day)) ?? "\(day)"
      return "Every year on \(monthName) \(ordinal) at \(timeString)"
    }
  }
  
  /// Returns all scheduled times for today for this occurrence
  func scheduledTimesToday() -> [Date] {
    ReminderSchedule.scheduledTimes(for: asRule, on: Date())
  }
}