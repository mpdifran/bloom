//
//  ReminderSchedule.swift
//  BloomFoundation
//

import Foundation

// MARK: - Cadence

/// How often a reminder occurrence repeats.
///
/// Mirrors `ReminderOccurrence.ReminderCadenceType` in DataContainer. It's redeclared here because
/// DataContainer is a SwiftData framework the watch app can't link, and both platforms need to
/// evaluate the same schedule.
public enum ReminderCadence: String, Codable, CaseIterable, Sendable {
  case daily
  case weekly
  case monthly
  case yearly
}

// MARK: - Status

/// Status of a reminder occurrence for display purposes.
public enum ReminderStatus: String, Codable, Sendable {
  case upcoming   // Scheduled time is in the future
  case dueNow     // Within 15 minutes of scheduled time
  case overdue    // Past scheduled time and not completed
  case completed  // Completed for today

  /// Sort order: the most urgent status comes first, completed last.
  public var sortPriority: Int {
    switch self {
    case .overdue: 0
    case .dueNow: 1
    case .upcoming: 2
    case .completed: 3
    }
  }
}

// MARK: - Raw reminder data

/// One repeat rule belonging to a reminder.
public struct ReminderOccurrenceRule: Codable, Sendable, Equatable, Identifiable {
  public let id: String
  public let cadence: ReminderCadence
  /// Seconds from midnight.
  public let timeOfDay: TimeInterval
  /// `Calendar` weekday numbers (1 = Sunday), for `.weekly`.
  public let daysOfWeek: [Int]?
  public let dayOfMonth: Int?
  public let monthOfYear: Int?
  public let dayOfYear: Int?

  public init(
    id: String,
    cadence: ReminderCadence,
    timeOfDay: TimeInterval,
    daysOfWeek: [Int]? = nil,
    dayOfMonth: Int? = nil,
    monthOfYear: Int? = nil,
    dayOfYear: Int? = nil
  ) {
    self.id = id
    self.cadence = cadence
    self.timeOfDay = timeOfDay
    self.daysOfWeek = daysOfWeek
    self.dayOfMonth = dayOfMonth
    self.monthOfYear = monthOfYear
    self.dayOfYear = dayOfYear
  }
}

/// A record that an occurrence was completed.
public struct ReminderCompletionMark: Codable, Sendable, Equatable {
  public let occurrenceID: String?
  public let completedDate: Date

  public init(occurrenceID: String?, completedDate: Date) {
    self.occurrenceID = occurrenceID
    self.completedDate = completedDate
  }
}

/// A reminder and its repeat rules, with enough completion history to decide what's outstanding.
///
/// This is the unit that syncs to the watch: raw rules rather than a rendered list, so the watch can
/// recompute what to show as the clock moves without waiting on the phone.
public struct ReminderPlan: Codable, Sendable, Equatable, Identifiable {
  public let id: String
  public let title: String
  public let colorHex: String
  public let occurrences: [ReminderOccurrenceRule]
  public let completions: [ReminderCompletionMark]

  public init(
    id: String,
    title: String,
    colorHex: String,
    occurrences: [ReminderOccurrenceRule],
    completions: [ReminderCompletionMark]
  ) {
    self.id = id
    self.title = title
    self.colorHex = colorHex
    self.occurrences = occurrences
    self.completions = completions
  }
}

// MARK: - Computed slot

/// A single occurrence of a reminder on a given day, resolved against completions and the clock.
public struct ReminderSlot: Sendable, Equatable, Identifiable {
  public let reminderID: String
  public let occurrenceID: String
  public let title: String
  public let colorHex: String
  public let scheduledTime: Date
  public let isCompleted: Bool
  public let completionDate: Date?
  public let status: ReminderStatus

  public var id: String { "\(reminderID)-\(occurrenceID)-\(scheduledTime.timeIntervalSince1970)" }

  public init(
    reminderID: String,
    occurrenceID: String,
    title: String,
    colorHex: String,
    scheduledTime: Date,
    isCompleted: Bool,
    completionDate: Date?,
    status: ReminderStatus
  ) {
    self.reminderID = reminderID
    self.occurrenceID = occurrenceID
    self.title = title
    self.colorHex = colorHex
    self.scheduledTime = scheduledTime
    self.isCompleted = isCompleted
    self.completionDate = completionDate
    self.status = status
  }
}

// MARK: - Engine

/// Resolves reminder rules into the occurrences to show for a day.
///
/// Single source of truth for both platforms: iOS renders `TodayView` from it and the watch renders
/// its Today tab and complications from it, so the two can't drift.
public enum ReminderSchedule {

  /// How long after its scheduled time an occurrence counts as `.dueNow` rather than `.overdue`.
  public static let dueNowWindow: TimeInterval = 15 * 60

  /// The times a rule fires on the given day, or none if it doesn't fire that day.
  public static func scheduledTimes(
    for rule: ReminderOccurrenceRule,
    on day: Date,
    calendar: Calendar = .current
  ) -> [Date] {
    let startOfDay = calendar.startOfDay(for: day)
    let components = calendar.dateComponents([.weekday, .day, .month], from: day)

    switch rule.cadence {
    case .daily:
      break

    case .weekly:
      guard let daysOfWeek = rule.daysOfWeek,
            let weekday = components.weekday,
            daysOfWeek.contains(weekday) else {
        return []
      }

    case .monthly:
      guard let dayOfMonth = rule.dayOfMonth,
            let day = components.day,
            day == dayOfMonth else {
        return []
      }

    case .yearly:
      guard let monthOfYear = rule.monthOfYear,
            let dayOfYear = rule.dayOfYear,
            components.month == monthOfYear,
            components.day == dayOfYear else {
        return []
      }
    }

    let hour = Int(rule.timeOfDay) / 3600
    let minute = (Int(rule.timeOfDay) % 3600) / 60

    guard let time = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: startOfDay) else {
      return []
    }

    return [time]
  }

  /// Whether the reminder fires at all on the given day.
  public static func hasOccurrence(
    _ plan: ReminderPlan,
    on day: Date,
    calendar: Calendar = .current
  ) -> Bool {
    plan.occurrences.contains { !scheduledTimes(for: $0, on: day, calendar: calendar).isEmpty }
  }

  /// The status of an occurrence at a point in time.
  public static func status(
    scheduledTime: Date,
    isCompleted: Bool,
    now: Date
  ) -> ReminderStatus {
    guard !isCompleted else { return .completed }

    if now < scheduledTime {
      return .upcoming
    } else if now <= scheduledTime.addingTimeInterval(dueNowWindow) {
      return .dueNow
    } else {
      return .overdue
    }
  }

  /// The occurrences to show for one reminder on the day containing `now`.
  ///
  /// Shows an occurrence when it's already completed, when its time has passed, or when it's the
  /// next one still outstanding — so a reminder that fires hourly doesn't fill the day with rows
  /// nobody can act on yet.
  public static func slots(
    for plan: ReminderPlan,
    now: Date = Date(),
    calendar: Calendar = .current
  ) -> [ReminderSlot] {
    let today = calendar.startOfDay(for: now)

    let todaysCompletions = plan.completions.filter {
      calendar.isDate($0.completedDate, inSameDayAs: today)
    }

    let pairs = plan.occurrences
      .flatMap { rule in
        scheduledTimes(for: rule, on: now, calendar: calendar).map { (rule, $0) }
      }
      .sorted { $0.1 < $1.1 }

    var slots: [ReminderSlot] = []
    var hasShownUncompleted = false

    for (rule, scheduledTime) in pairs {
      let completion = todaysCompletions.first { $0.occurrenceID == rule.id }
      let isCompleted = completion != nil
      let timePassed = scheduledTime <= now

      guard isCompleted || !hasShownUncompleted || timePassed else { continue }

      slots.append(ReminderSlot(
        reminderID: plan.id,
        occurrenceID: rule.id,
        title: plan.title,
        colorHex: plan.colorHex,
        scheduledTime: scheduledTime,
        isCompleted: isCompleted,
        completionDate: completion?.completedDate,
        status: status(scheduledTime: scheduledTime, isCompleted: isCompleted, now: now)
      ))

      if !isCompleted {
        hasShownUncompleted = true
      }
    }

    return slots
  }

  /// The occurrences to show across several reminders, in display order.
  public static func slots(
    for plans: [ReminderPlan],
    now: Date = Date(),
    calendar: Calendar = .current
  ) -> [ReminderSlot] {
    sorted(plans.flatMap { slots(for: $0, now: now, calendar: calendar) })
  }

  /// Display order: outstanding first (most urgent first), then completed (most recently first).
  public static func sorted(_ slots: [ReminderSlot]) -> [ReminderSlot] {
    slots.sorted { first, second in
      if first.isCompleted && second.isCompleted {
        if let firstDate = first.completionDate, let secondDate = second.completionDate {
          return firstDate > secondDate
        }
        return first.scheduledTime > second.scheduledTime
      }

      if first.isCompleted != second.isCompleted {
        return !first.isCompleted
      }

      let firstPriority = first.status.sortPriority
      let secondPriority = second.status.sortPriority

      if firstPriority != secondPriority {
        return firstPriority < secondPriority
      }

      return first.scheduledTime < second.scheduledTime
    }
  }
}
