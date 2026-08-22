//
//  YearInBloomMenstrualStats.swift
//  CoreHealth
//
//  Created by Claude on 2025-12-17.
//

import Foundation

// MARK: - Main Stats Model

public struct YearInBloomMenstrualStats: Sendable, Codable, Hashable {
  public let year: Int
  public let totalCycles: Int
  public let averageCycleDuration: Double
  public let averagePeriodLength: Double?
  public let shortestCycle: CycleExtreme?
  public let longestCycle: CycleExtreme?
  public let follicularActivityIncrease: Double?
  public let lutealRestingHRChange: Double?
  public let lutealSleepEfficiencyChange: Double?
  public let monthlyPhaseActivityData: [MonthlyPhaseActivityData]
  public let generatedDate: Date

  public init(
    year: Int,
    totalCycles: Int,
    averageCycleDuration: Double,
    averagePeriodLength: Double?,
    shortestCycle: CycleExtreme?,
    longestCycle: CycleExtreme?,
    follicularActivityIncrease: Double?,
    lutealRestingHRChange: Double?,
    lutealSleepEfficiencyChange: Double?,
    monthlyPhaseActivityData: [MonthlyPhaseActivityData],
    generatedDate: Date
  ) {
    self.year = year
    self.totalCycles = totalCycles
    self.averageCycleDuration = averageCycleDuration
    self.averagePeriodLength = averagePeriodLength
    self.shortestCycle = shortestCycle
    self.longestCycle = longestCycle
    self.follicularActivityIncrease = follicularActivityIncrease
    self.lutealRestingHRChange = lutealRestingHRChange
    self.lutealSleepEfficiencyChange = lutealSleepEfficiencyChange
    self.monthlyPhaseActivityData = monthlyPhaseActivityData
    self.generatedDate = generatedDate
  }
}

// MARK: - Monthly Phase Activity Data

public struct MonthlyPhaseActivityData: Identifiable, Sendable, Codable, Hashable {
  public var id: Date { date }
  public let date: Date
  public let follicularActivityLevel: Double?
  public let otherActivityLevel: Double?

  public init(date: Date, follicularActivityLevel: Double?, otherActivityLevel: Double?) {
    self.date = date
    self.follicularActivityLevel = follicularActivityLevel
    self.otherActivityLevel = otherActivityLevel
  }
}

// MARK: - Cycle Extreme

public struct CycleExtreme: Sendable, Codable, Hashable {
  public let duration: Int
  public let startDate: Date

  public init(duration: Int, startDate: Date) {
    self.duration = duration
    self.startDate = startDate
  }

  public var monthName: String {
    // Locale-aware abbreviated month; "MMM" would show English names to French/German users.
    startDate.formatted(.dateTime.month(.abbreviated))
  }
}
