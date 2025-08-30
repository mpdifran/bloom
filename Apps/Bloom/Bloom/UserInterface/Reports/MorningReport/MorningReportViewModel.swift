//
//  MorningReportViewModel.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-07-23.
//

import Foundation
import CoreHealth
import DataContainer
import BloomModel

extension MorningReportView.ViewModel {
  enum AlertKind: Sendable, Identifiable {
    var id: String {
      switch self {
      case .periodPrediction(let date):
        return "periodPrediction_\(date.timeIntervalSince1970)"
      case .intenseActivity(let value):
        return "intenseActivity_\(value)"
      case .sedentaryActivity:
        return "sedentaryActivity"
      }
    }

    case periodPrediction(Date)
    case intenseActivity(Double)
    case sedentaryActivity
  }
}

extension MorningReportView {
  @MainActor @Observable
  final class ViewModel {
    var incompleteReminders = [ReminderOccurrenceDisplay]()

    init() {
      Task {
        await triggerReportLoadIfNeeded()
      }
      Task {
        await loadYesterdaysUncompletedOccurrences()
      }
    }

    private let reminderModelActor = ReminderModelActor.standard()
  }
}

extension MorningReportView.ViewModel {

  func loadYesterdaysUncompletedOccurrences() async {
    do {
      let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
      let reminderDTOs = try await reminderModelActor.fetchAllReminders()

      // Get all occurrences for yesterday
      let yesterdaysOccurrences = reminderDTOs.flatMap { reminder in
        occurrenceDisplaysFor(reminder: reminder, date: yesterday)
      }

      // Filter out completed occurrences
      self.incompleteReminders = yesterdaysOccurrences.filter { !$0.isCompleted }
    } catch {
      print("Failed to fetch yesterday's uncompleted reminders: \(error)")
    }
  }
}

extension MorningReportView.ViewModel {

  var alerts: [MorningReportView.ViewModel.AlertKind] {
    var alerts = [MorningReportView.ViewModel.AlertKind]()

    if let date = relevantPredictedPeriodDate {
      alerts.append(.periodPrediction(date))
    }
    if let ratio = intenseActivityLevelRatio {
      alerts.append(.intenseActivity(ratio))
    }
    if hasSedentaryStreak {
      alerts.append(.sedentaryActivity)
    }

    return alerts
  }
}

extension MorningReportView.ViewModel {

  var relevantPredictedPeriodDate: Date? {
    guard
      let periodDate = VitalsViewModel.shared.menstrualSummary?.nextPredictedPeriodDate,
      let remainingDays = Calendar.current.dateComponents([.day], from: .now, to: periodDate).day,
      remainingDays <= 4,
      remainingDays >= -3
    else {
      return nil
    }
    
    return periodDate
  }

  var intenseActivityLevelRatio: Double? {
    guard
      let energyRatioSample = VitalsViewModel.shared.activityLevelSummary?.details.energyRatioSamples.last(where: { Calendar.current.isDateInYesterday($0.date) }),
      ActivityLevelSummary.ActivityLevel(energyRatioSample.value) == .intense
    else {
      return nil
    }

    return energyRatioSample.value
  }

  var hasSedentaryStreak: Bool {
    VitalsViewModel.shared.activityLevelSummary?.details.hasSedentaryStreakLast3Days == true
  }
}

private extension MorningReportView.ViewModel {

  func triggerReportLoadIfNeeded() async {
    // Morning report generation has been removed
    // UI will show existing reports from database but won't generate new ones
  }

  func occurrenceDisplaysFor(reminder: ReminderDTO, date: Date) -> [ReminderOccurrenceDisplay] {
    let calendar = Calendar.current
    let dayStart = calendar.startOfDay(for: date)

    // Get completion records for the specified date
    let dateCompletions = reminder.completionRecords
      .filter { calendar.isDate($0.completedDate, inSameDayAs: date) }

    // Get all occurrences that were scheduled for the date with their times
    var occurrenceTimePairs: [(ReminderOccurrenceDTO, Date)] = []

    for occurrence in reminder.occurrences {
      let scheduledTimes = scheduledTimesFor(occurrence: occurrence, date: date)
      for scheduledTime in scheduledTimes {
        occurrenceTimePairs.append((occurrence, scheduledTime))
      }
    }

    // Sort by scheduled time
    occurrenceTimePairs.sort { $0.1 < $1.1 }

    // Create displays
    return occurrenceTimePairs.map { (occurrence, scheduledTime) in
      let isCompleted = dateCompletions.contains { $0.occurrenceID == occurrence.id }
      let completionDate = dateCompletions.first { $0.occurrenceID == occurrence.id }?.completedDate

      return ReminderOccurrenceDisplay(
        reminder: reminder,
        occurrence: occurrence,
        scheduledTime: scheduledTime,
        isCompleted: isCompleted,
        completionDate: completionDate
      )
    }
  }

  func scheduledTimesFor(occurrence: ReminderOccurrenceDTO, date: Date) -> [Date] {
    let calendar = Calendar.current
    let dayStart = calendar.startOfDay(for: date)

    let hour = Int(occurrence.timeOfDay) / 3600
    let minute = (Int(occurrence.timeOfDay) % 3600) / 60

    switch occurrence.cadenceType {
    case .daily:
      if let scheduledTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: dayStart) {
        return [scheduledTime]
      }

    case .weekly:
      guard let daysOfWeek = occurrence.daysOfWeek,
            let weekday = calendar.dateComponents([.weekday], from: date).weekday,
            daysOfWeek.contains(weekday) else {
        return []
      }
      if let scheduledTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: dayStart) {
        return [scheduledTime]
      }

    case .monthly:
      guard let dayOfMonth = occurrence.dayOfMonth,
            let day = calendar.dateComponents([.day], from: date).day,
            dayOfMonth == day else {
        return []
      }
      if let scheduledTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: dayStart) {
        return [scheduledTime]
      }

    case .yearly:
      guard let monthOfYear = occurrence.monthOfYear,
            let dayOfYear = occurrence.dayOfYear else {
        return []
      }
      let dateComponents = calendar.dateComponents([.month, .day], from: date)
      guard monthOfYear == dateComponents.month,
            dayOfYear == dateComponents.day else {
        return []
      }
      if let scheduledTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: dayStart) {
        return [scheduledTime]
      }
    @unknown default:
      break
    }

    return []
  }
}
