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
    let hours = Int(averageDurationMinutes) / 60
    let mins = Int(averageDurationMinutes) % 60
    return "\(hours)h \(mins)m"
  }

  var previousPeriodAverageDurationFormatted: String? {
    guard let minutes = previousPeriodAverageDurationMinutes else { return nil }
    let hours = Int(minutes) / 60
    let mins = Int(minutes) % 60
    return "\(hours)h \(mins)m"
  }

  var consistencyDescription: String {
    if bedtimeStandardDeviationMinutes < 30 {
      return "Very Consistent"
    } else if bedtimeStandardDeviationMinutes < 60 {
      return "Consistent"
    } else if bedtimeStandardDeviationMinutes < 90 {
      return "Somewhat Variable"
    } else {
      return "Variable"
    }
  }

  var wakeTimeConsistencyDescription: String {
    if wakeTimeStandardDeviationMinutes < 30 {
      return "Very Consistent"
    } else if wakeTimeStandardDeviationMinutes < 60 {
      return "Consistent"
    } else if wakeTimeStandardDeviationMinutes < 90 {
      return "Somewhat Variable"
    } else {
      return "Variable"
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
    let period = hours >= 12 ? "PM" : "AM"
    let displayHour = hours == 0 ? 12 : (hours > 12 ? hours - 12 : hours)
    return String(format: "%d:%02d %@", displayHour, minutes, period)
  }
}
