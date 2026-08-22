//
//  DateFormatter+Constants.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-25.
//

import Foundation

public extension DateFormatter {

  static let dateTimeShort = DateFormatter().with {
    $0.dateStyle = .short
    $0.timeStyle = .short
  }

  static let dateTimeMedium = DateFormatter().with {
    $0.dateStyle = .medium
    $0.timeStyle = .medium
  }

  /// Wire format. Only used to serialize dates into the AI/backend payloads, never shown to the
  /// user, so the pattern stays fixed and the locale is pinned to POSIX - otherwise a French or
  /// German device would send localized month names into JSON the server expects in English.
  static let dateTimeMediumWithTimeZone = DateFormatter().with {
    $0.locale = Locale(identifier: "en_US_POSIX")
    $0.dateFormat = "MMM d, yyyy h:mm a zzz"
  }

  static let mediumDateShortTime = DateFormatter().with {
    $0.dateStyle = .medium
    $0.timeStyle = .short
  }

  /// Wire format. Feeds the biological-age payload sent to the backend, not the UI, so the pattern
  /// stays fixed and the locale is pinned to POSIX.
  static let mediumDateShortTimeLowercase = DateFormatter().with {
    $0.locale = Locale(identifier: "en_US_POSIX")
    $0.dateFormat = "MMM d, yyyy h:mma"
  }

  static let justTimeShort = DateFormatter().with {
    $0.dateStyle = .none
    $0.timeStyle = .short
  }

  static let justDateMedium = DateFormatter().with {
    $0.dateStyle = .medium
    $0.timeStyle = .none
  }

  static let justDateShort = DateFormatter().with {
    $0.dateStyle = .short
    $0.timeStyle = .none
  }

  static let justDateLong = DateFormatter().with {
    $0.dateStyle = .long
    $0.timeStyle = .none
  }

  static let justRelativeDateMedium = DateFormatter().with {
    $0.dateStyle = .medium
    $0.timeStyle = .none
    $0.doesRelativeDateFormatting = true
  }

  static let justRelativeDateLong = DateFormatter().with {
    $0.dateStyle = .long
    $0.timeStyle = .none
    $0.doesRelativeDateFormatting = true
  }

  static let relativeDateMediumTimeShort = DateFormatter().with {
    $0.dateStyle = .medium
    $0.timeStyle = .short
    $0.doesRelativeDateFormatting = true
  }

  static let relativeDateTimeMedium = DateFormatter().with {
    $0.dateStyle = .medium
    $0.timeStyle = .medium
    $0.doesRelativeDateFormatting = true
  }

  static let relativeDateTimeShort = DateFormatter().with {
    $0.dateStyle = .short
    $0.timeStyle = .short
    $0.doesRelativeDateFormatting = true
  }

  static let weekdayShortMonthDayYear = DateFormatter().with {
    $0.setLocalizedDateFormatFromTemplate("EEE, MMM d, yyyy")
  }

  static let weekdayFullMonthDayYear = DateFormatter().with {
    $0.setLocalizedDateFormatFromTemplate("EEEE, MMMM d, yyyy")
  }

  static let justFullMonth = DateFormatter().with {
    $0.setLocalizedDateFormatFromTemplate("MMMM")
  }

  static let justShortMonth = DateFormatter().with {
    $0.setLocalizedDateFormatFromTemplate("MMM")
  }

  static let fullMonthAndYear = DateFormatter().with {
    $0.setLocalizedDateFormatFromTemplate("MMMM yyyy")
  }

  static let monthAndDay = DateFormatter().with {
    $0.setLocalizedDateFormatFromTemplate("MMM d")
  }

  static let justDay = DateFormatter().with {
    $0.setLocalizedDateFormatFromTemplate("d")
  }

  static let justDayOfWeek = DateFormatter().with {
    $0.setLocalizedDateFormatFromTemplate("EEEE")
  }

  static let justDayOfWeekShort = DateFormatter().with {
    $0.setLocalizedDateFormatFromTemplate("E")
  }

  static let justRelativeDateShortWithDayOfWeek = DateFormatter().with {
    $0.setLocalizedDateFormatFromTemplate("E, MMM d yyyy")
  }

  static func justRelativeDayOfWeek(date: Date) -> String {
    if
      Calendar.current.isDateInToday(date) ||
        Calendar.current.isDateInTomorrow(date) ||
        Calendar.current.isDateInYesterday(date)
    {
      return justRelativeDateMedium.string(from: date)
    }
    return justDayOfWeek.string(from: date)
  }

  static func conversationRelativeDateOrTime(date: Date) -> String {
    if Calendar.current.isDateInToday(date) {
      return justTimeShort.string(from: date)
    }
    if Calendar.current.isDateInTomorrow(date) || Calendar.current.isDateInYesterday(date) {
      return justRelativeDateMedium.string(from: date)
    }
    let cal = Calendar.current
    if let sixDaysAgo = cal.date(byAdding: .day, value: -6, to: cal.startOfDay(for: Date())),
       let startOfToday = cal.startOfDay(for: Date()) as Date?,
       date >= sixDaysAgo && date < startOfToday {
      return justDayOfWeek.string(from: date)
    }
    return justDateShort.string(from: date)
  }

  static let timeIntervalHourAbbreviated = DateComponentsFormatter().with {
    $0.unitsStyle = .abbreviated
    $0.allowedUnits = [.hour]
  }

  static let timeIntervalMinuteAbbreviated = DateComponentsFormatter().with {
    $0.unitsStyle = .abbreviated
    $0.allowedUnits = [.minute]
  }

  static let timeIntervalHourMinuteAbbreviated = DateComponentsFormatter().with {
    $0.unitsStyle = .abbreviated
    $0.allowedUnits = [.hour, .minute]
  }

  static let timeIntervalHourMinuteShort = DateComponentsFormatter().with {
    $0.unitsStyle = .short
    $0.allowedUnits = [.hour, .minute]
  }

  static let timeIntervalHourMinuteFull = DateComponentsFormatter().with {
    $0.unitsStyle = .full
    $0.allowedUnits = [.hour, .minute]
  }

  static let timeIntervalHourMinuteSecondShort = DateComponentsFormatter().with {
    $0.unitsStyle = .short
    $0.allowedUnits = [.hour, .minute, .second]
  }

  static let timeIntervalHourMinuteSecondAbbreviated = DateComponentsFormatter().with {
    $0.unitsStyle = .abbreviated
    $0.allowedUnits = [.hour, .minute, .second]
  }

  static let timeIntervalHourMinuteSecondPadded = DateComponentsFormatter().with {
    $0.allowedUnits = [.hour, .minute, .second]
    $0.unitsStyle = .positional
    $0.zeroFormattingBehavior = [.pad]
  }

  static let timeIntervalDaysFull = DateComponentsFormatter().with {
    $0.unitsStyle = .full
    $0.allowedUnits = [.day]
  }

  static func relativeTimeIntervalDaysFullFromNow(_ date: Date) -> String {
    if
      Calendar.current.isDateInToday(date) ||
        Calendar.current.isDateInTomorrow(date) ||
        Calendar.current.isDateInYesterday(date)
    {
      return justRelativeDateMedium.string(from: date)
    }
    let interval = timeIntervalDaysFull.string(from: .now, to: date) ?? ""

    return String(
      localized: "in \(interval)",
      bundle: Bundle.bloomFoundation,
      comment: "How far in the future something is. The placeholder is a duration, e.g. \"3 days\"."
    )
  }

  /// Log format. Deliberately fixed and pinned to POSIX so timestamps stay comparable across
  /// devices regardless of the user's region or calendar.
  static let millisecondBasedLogInterval = DateFormatter().with {
    $0.locale = Locale(identifier: "en_US_POSIX")
    $0.dateFormat = "HH:mm:ss.SSS"
  }
}

