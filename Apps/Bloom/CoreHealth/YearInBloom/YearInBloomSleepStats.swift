//
//  YearInBloomSleepStats.swift
//  CoreHealth
//
//  Created by Claude on 2025-12-16.
//

import Foundation

// MARK: - Main Stats Model

public struct YearInBloomSleepStats: Sendable, Codable, Hashable {
  public let year: Int
  public let monthlySleepStats: [MonthlySleepStats]
  public let yearTotals: SleepYearTotals
  public let lowestSleepScore: SleepScoreExtreme?
  public let highestSleepScore: SleepScoreExtreme?
  public let generatedDate: Date

  public init(
    year: Int,
    monthlySleepStats: [MonthlySleepStats],
    yearTotals: SleepYearTotals,
    lowestSleepScore: SleepScoreExtreme?,
    highestSleepScore: SleepScoreExtreme?,
    generatedDate: Date
  ) {
    self.year = year
    self.monthlySleepStats = monthlySleepStats
    self.yearTotals = yearTotals
    self.lowestSleepScore = lowestSleepScore
    self.highestSleepScore = highestSleepScore
    self.generatedDate = generatedDate
  }
}

// MARK: - Monthly Sleep Stats

public struct MonthlySleepStats: Sendable, Codable, Hashable, Identifiable {
  public var id: Int { month }

  public let month: Int // 1-12
  public let sleepSessionCount: Int
  public let averageCoreSleepPercent: Double
  public let averageDeepSleepPercent: Double
  public let averageRemSleepPercent: Double
  public let averageAwakeSleepPercent: Double
  public let averageCoreSleepMinutes: Double
  public let averageDeepSleepMinutes: Double
  public let averageRemSleepMinutes: Double
  public let averageAwakeSleepMinutes: Double
  public let averageSleepDurationMinutes: Double
  public let averageSleepScore: Double
  public let averageBedtimeMinutes: Double // Minutes from noon (e.g., 660 = 11 PM)
  public let averageWakeTimeMinutes: Double // Minutes from noon (e.g., 1140 = 7 AM)

  public init(
    month: Int,
    sleepSessionCount: Int,
    averageCoreSleepPercent: Double,
    averageDeepSleepPercent: Double,
    averageRemSleepPercent: Double,
    averageAwakeSleepPercent: Double,
    averageCoreSleepMinutes: Double,
    averageDeepSleepMinutes: Double,
    averageRemSleepMinutes: Double,
    averageAwakeSleepMinutes: Double,
    averageSleepDurationMinutes: Double,
    averageSleepScore: Double,
    averageBedtimeMinutes: Double,
    averageWakeTimeMinutes: Double
  ) {
    self.month = month
    self.sleepSessionCount = sleepSessionCount
    self.averageCoreSleepPercent = averageCoreSleepPercent
    self.averageDeepSleepPercent = averageDeepSleepPercent
    self.averageRemSleepPercent = averageRemSleepPercent
    self.averageAwakeSleepPercent = averageAwakeSleepPercent
    self.averageCoreSleepMinutes = averageCoreSleepMinutes
    self.averageDeepSleepMinutes = averageDeepSleepMinutes
    self.averageRemSleepMinutes = averageRemSleepMinutes
    self.averageAwakeSleepMinutes = averageAwakeSleepMinutes
    self.averageSleepDurationMinutes = averageSleepDurationMinutes
    self.averageSleepScore = averageSleepScore
    self.averageBedtimeMinutes = averageBedtimeMinutes
    self.averageWakeTimeMinutes = averageWakeTimeMinutes
  }

  public var monthName: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMMM"
    let components = DateComponents(month: month)
    guard let date = Calendar.current.date(from: components) else { return "" }
    return formatter.string(from: date)
  }

  public var shortMonthName: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM"
    let components = DateComponents(month: month)
    guard let date = Calendar.current.date(from: components) else { return "" }
    return formatter.string(from: date)
  }
}

// MARK: - Sleep Score Extreme

public struct SleepScoreExtreme: Sendable, Codable, Hashable {
  public let score: Int
  public let month: Int // 1-12

  public init(score: Int, month: Int) {
    self.score = score
    self.month = month
  }

  public var shortMonthName: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM"
    let components = DateComponents(month: month)
    guard let date = Calendar.current.date(from: components) else { return "" }
    return formatter.string(from: date)
  }
}

// MARK: - Year Totals

public struct SleepYearTotals: Sendable, Codable, Hashable {
  public let totalSleepSessions: Int
  public let averageCoreSleepPercent: Double
  public let averageDeepSleepPercent: Double
  public let averageRemSleepPercent: Double
  public let averageAwakeSleepPercent: Double
  public let averageSleepDurationMinutes: Double
  public let averageSleepScore: Double

  public init(
    totalSleepSessions: Int,
    averageCoreSleepPercent: Double,
    averageDeepSleepPercent: Double,
    averageRemSleepPercent: Double,
    averageAwakeSleepPercent: Double,
    averageSleepDurationMinutes: Double,
    averageSleepScore: Double
  ) {
    self.totalSleepSessions = totalSleepSessions
    self.averageCoreSleepPercent = averageCoreSleepPercent
    self.averageDeepSleepPercent = averageDeepSleepPercent
    self.averageRemSleepPercent = averageRemSleepPercent
    self.averageAwakeSleepPercent = averageAwakeSleepPercent
    self.averageSleepDurationMinutes = averageSleepDurationMinutes
    self.averageSleepScore = averageSleepScore
  }

  public var averageSleepDurationHours: Double {
    averageSleepDurationMinutes / 60
  }
}

// MARK: - Chart Data Model

public struct MonthlySleepStageChartData: Identifiable, Sendable, Equatable {
  public var id: Date { date }
  public let date: Date
  public let corePercent: Double
  public let deepPercent: Double
  public let remPercent: Double
  public let awakePercent: Double
  public let coreMinutes: Double
  public let deepMinutes: Double
  public let remMinutes: Double
  public let awakeMinutes: Double

  public init(
    date: Date,
    corePercent: Double,
    deepPercent: Double,
    remPercent: Double,
    awakePercent: Double,
    coreMinutes: Double,
    deepMinutes: Double,
    remMinutes: Double,
    awakeMinutes: Double
  ) {
    self.date = date
    self.corePercent = corePercent
    self.deepPercent = deepPercent
    self.remPercent = remPercent
    self.awakePercent = awakePercent
    self.coreMinutes = coreMinutes
    self.deepMinutes = deepMinutes
    self.remMinutes = remMinutes
    self.awakeMinutes = awakeMinutes
  }

  public var total: Double {
    corePercent + deepPercent + remPercent + awakePercent
  }

  public var totalMinutes: Double {
    coreMinutes + deepMinutes + remMinutes + awakeMinutes
  }

  // MARK: - Stacked Chart Values (0-100 scale)

  public var coreEnd: Double { corePercent * 100 }
  public var deepEnd: Double { (corePercent + deepPercent) * 100 }
  public var remEnd: Double { (corePercent + deepPercent + remPercent) * 100 }
  public var awakeEnd: Double { (corePercent + deepPercent + remPercent + awakePercent) * 100 }

  // MARK: - Display Values

  public var corePercentDisplay: Int { Int(corePercent * 100) }
  public var deepPercentDisplay: Int { Int(deepPercent * 100) }
  public var remPercentDisplay: Int { Int(remPercent * 100) }
  public var awakePercentDisplay: Int { Int(awakePercent * 100) }

  public var coreMinutesDisplay: Int { Int(coreMinutes) }
  public var deepMinutesDisplay: Int { Int(deepMinutes) }
  public var remMinutesDisplay: Int { Int(remMinutes) }
  public var awakeMinutesDisplay: Int { Int(awakeMinutes) }
}

// MARK: - Sleep Stage Data Point (for stacked charts)

public enum SleepStage: String, CaseIterable, Sendable {
  case core = "Core"
  case deep = "Deep"
  case rem = "REM"
  case awake = "Awake"
}

public struct SleepStageDataPoint: Identifiable, Sendable {
  public var id: String { "\(date.timeIntervalSince1970)-\(stage.rawValue)" }
  public let date: Date
  public let stage: SleepStage
  public let minutes: Double

  public init(date: Date, stage: SleepStage, minutes: Double) {
    self.date = date
    self.stage = stage
    self.minutes = minutes
  }
}

// MARK: - Sleep Schedule Chart Data

public struct MonthlySleepScheduleData: Identifiable, Sendable, Equatable {
  public var id: Date { date }
  public let date: Date
  public let bedtimeMinutes: Double
  public let wakeTimeMinutes: Double

  public init(date: Date, bedtimeMinutes: Double, wakeTimeMinutes: Double) {
    self.date = date
    self.bedtimeMinutes = bedtimeMinutes
    self.wakeTimeMinutes = wakeTimeMinutes
  }

  public var bedtimeFormatted: String {
    Self.formatMinutesAsTime(bedtimeMinutes)
  }

  public var wakeTimeFormatted: String {
    Self.formatMinutesAsTime(wakeTimeMinutes)
  }

  /// Convert minutes from noon to display time (e.g., 600 -> "10:00 PM")
  public static func formatMinutesAsTime(_ minutesFromNoon: Double) -> String {
    // Convert back to minutes from midnight
    var minutesFromMidnight = minutesFromNoon + 720
    if minutesFromMidnight >= 1440 {
      minutesFromMidnight -= 1440
    }
    let hours = Int(minutesFromMidnight) / 60
    let mins = Int(minutesFromMidnight) % 60
    let period = hours >= 12 ? "PM" : "AM"
    let displayHour = hours == 0 ? 12 : (hours > 12 ? hours - 12 : hours)
    return String(format: "%d:%02d %@", displayHour, mins, period)
  }
}

// MARK: - Chart Data Helpers

public extension YearInBloomSleepStats {

  /// Monthly sleep schedule data for range bar chart
  func monthlySleepScheduleData() -> [MonthlySleepScheduleData] {
    monthlySleepStats.compactMap { stat in
      guard stat.sleepSessionCount > 0,
            let date = Calendar.current.date(
              from: DateComponents(year: year, month: stat.month, day: 15)
            ) else {
        return nil
      }
      return MonthlySleepScheduleData(
        date: date,
        bedtimeMinutes: stat.averageBedtimeMinutes,
        wakeTimeMinutes: stat.averageWakeTimeMinutes
      )
    }
  }

  /// Monthly sleep stage data for stacked area chart
  func monthlySleepStageData() -> [MonthlySleepStageChartData] {
    monthlySleepStats.compactMap { stat in
      guard stat.sleepSessionCount > 0,
            let date = Calendar.current.date(
              from: DateComponents(year: year, month: stat.month, day: 15)
            ) else {
        return nil
      }
      return MonthlySleepStageChartData(
        date: date,
        corePercent: stat.averageCoreSleepPercent,
        deepPercent: stat.averageDeepSleepPercent,
        remPercent: stat.averageRemSleepPercent,
        awakePercent: stat.averageAwakeSleepPercent,
        coreMinutes: stat.averageCoreSleepMinutes,
        deepMinutes: stat.averageDeepSleepMinutes,
        remMinutes: stat.averageRemSleepMinutes,
        awakeMinutes: stat.averageAwakeSleepMinutes
      )
    }
  }

  /// Sleep stage data points in long format for stacked area chart
  func sleepStageDataPoints() -> [SleepStageDataPoint] {
    monthlySleepStageData().flatMap { month in
      [
        SleepStageDataPoint(date: month.date, stage: .core, minutes: month.coreMinutes),
        SleepStageDataPoint(date: month.date, stage: .deep, minutes: month.deepMinutes),
        SleepStageDataPoint(date: month.date, stage: .rem, minutes: month.remMinutes),
        SleepStageDataPoint(date: month.date, stage: .awake, minutes: month.awakeMinutes)
      ]
    }
  }
}
