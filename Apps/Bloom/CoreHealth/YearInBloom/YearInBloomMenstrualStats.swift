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
  public let shortestCycle: CycleExtreme?
  public let longestCycle: CycleExtreme?
  public let follicularActivityIncrease: Double?
  public let lutealRestingHRChange: Double?
  public let lutealSleepEfficiencyChange: Double?
  public let generatedDate: Date

  public init(
    year: Int,
    totalCycles: Int,
    averageCycleDuration: Double,
    shortestCycle: CycleExtreme?,
    longestCycle: CycleExtreme?,
    follicularActivityIncrease: Double?,
    lutealRestingHRChange: Double?,
    lutealSleepEfficiencyChange: Double?,
    generatedDate: Date
  ) {
    self.year = year
    self.totalCycles = totalCycles
    self.averageCycleDuration = averageCycleDuration
    self.shortestCycle = shortestCycle
    self.longestCycle = longestCycle
    self.follicularActivityIncrease = follicularActivityIncrease
    self.lutealRestingHRChange = lutealRestingHRChange
    self.lutealSleepEfficiencyChange = lutealSleepEfficiencyChange
    self.generatedDate = generatedDate
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
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM"
    return formatter.string(from: startDate)
  }
}
