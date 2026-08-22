//
//  BedtimeSleepDurationDetailData.swift
//  Bloom
//
//  Created by Assistant on 2026-01-09.
//

import Foundation

// Uses BedtimeTrend from BedtimeChartData.swift

struct BedtimeSleepDurationDataPoint: Identifiable, Sendable {
  let date: Date
  let bedtimeMinutesFromNoon: Double   // e.g., 660 = 11 PM
  let wakeTimeMinutesFromNoon: Double  // e.g., 1140 = 7 AM (next day)
  let durationMinutes: Double

  var id: Date { date }
}

struct BedtimeSleepDurationSummary: Sendable {
  let dataPoints: [BedtimeSleepDurationDataPoint]
  let averageBedtimeMinutesFromNoon: Double
  let averageWakeTimeMinutesFromNoon: Double
  let averageDurationMinutes: Double
  let bedtimeStandardDeviationMinutes: Double
  let wakeTimeStandardDeviationMinutes: Double
  let bedtimeTrend: BedtimeTrend
  let previousPeriodAverageDurationMinutes: Double?
  let durationChangeFromPreviousPeriod: Double?

  var hasNoData: Bool { dataPoints.isEmpty }

  var averageBedtimeFormatted: String {
    formatTime(minutesFromNoon: averageBedtimeMinutesFromNoon)
  }

  var averageWakeTimeFormatted: String {
    formatTime(minutesFromNoon: averageWakeTimeMinutesFromNoon)
  }

  var averageDurationFormatted: String {
    // Locale-aware duration: hand-built "3h 45m" hardcoded English unit abbreviations.
    return Duration.seconds(Int(averageDurationMinutes) * 60)
      .formatted(.units(allowed: [.hours, .minutes], width: .narrow))
  }

  var previousPeriodAverageDurationFormatted: String? {
    guard let minutes = previousPeriodAverageDurationMinutes else { return nil }
    // Locale-aware duration: hand-built "3h 45m" hardcoded English unit abbreviations.
    return Duration.seconds(Int(minutes) * 60)
      .formatted(.units(allowed: [.hours, .minutes], width: .narrow))
  }

  var consistencyDescription: String {
    if bedtimeStandardDeviationMinutes < 30 {
      return String(localized: "Very Consistent", comment: "Bedtime consistency rating")
    } else if bedtimeStandardDeviationMinutes < 60 {
      return String(localized: "Consistent", comment: "Bedtime consistency rating")
    } else if bedtimeStandardDeviationMinutes < 90 {
      return String(localized: "Somewhat Variable", comment: "Bedtime consistency rating")
    } else {
      return String(localized: "Variable", comment: "Bedtime consistency rating")
    }
  }

  var wakeTimeConsistencyDescription: String {
    if wakeTimeStandardDeviationMinutes < 30 {
      return String(localized: "Very Consistent", comment: "Wake time consistency rating")
    } else if wakeTimeStandardDeviationMinutes < 60 {
      return String(localized: "Consistent", comment: "Wake time consistency rating")
    } else if wakeTimeStandardDeviationMinutes < 90 {
      return String(localized: "Somewhat Variable", comment: "Wake time consistency rating")
    } else {
      return String(localized: "Variable", comment: "Wake time consistency rating")
    }
  }

  private func formatTime(minutesFromNoon: Double) -> String {
    // Convert from minutes-from-noon to minutes-from-midnight
    var minutesFromMidnight = minutesFromNoon + 720
    if minutesFromMidnight >= 1440 {
      minutesFromMidnight -= 1440
    }
    let hours = Int(minutesFromMidnight) / 60
    let minutes = Int(minutesFromMidnight) % 60
    // Formatted through the locale rather than a hardcoded 12-hour AM/PM string, which showed
    // English "AM"/"PM" in every language and ignored 24-hour locales.
    guard let date = Calendar.current.date(from: DateComponents(hour: hours, minute: minutes)) else { return "" }
    return date.formatted(.dateTime.hour().minute())
  }
}
