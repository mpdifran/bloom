//
//  TrainingLoadSummary.swift
//  CoreHealth
//
//  Created by Assistant on 2025-01-25.
//

import SwiftUI
import Foundation
import BloomFoundation

public struct TrainingLoadSummary: Sendable, Hashable {
  public let dateRange: DateRange
  public let currentSevenDayAverage: Double
  public let currentTwentyEightDayAverage: Double
  public let percentageDifference: Double // (7day - 28day) / 28day * 100
  public let status: TrainingLoadStatus
  
  // Chart data - daily rolling averages for last 28 days
  public let sevenDayTrend: [DateValueSample] // 7-day rolling avg for each day
  public let twentyEightDayTrend: [DateValueSample] // 28-day rolling avg for each day
  public let dailyLoads: [DateValueSample] // Raw daily loads (dots on chart)
  
  public init(
    dateRange: DateRange,
    currentSevenDayAverage: Double,
    currentTwentyEightDayAverage: Double,
    percentageDifference: Double,
    status: TrainingLoadStatus,
    sevenDayTrend: [DateValueSample],
    twentyEightDayTrend: [DateValueSample],
    dailyLoads: [DateValueSample]
  ) {
    self.dateRange = dateRange
    self.currentSevenDayAverage = currentSevenDayAverage
    self.currentTwentyEightDayAverage = currentTwentyEightDayAverage
    self.percentageDifference = percentageDifference
    self.status = status
    self.sevenDayTrend = sevenDayTrend
    self.twentyEightDayTrend = twentyEightDayTrend
    self.dailyLoads = dailyLoads
  }
}

public enum TrainingLoadStatus: String, CaseIterable, Sendable, Hashable {
  case wellBelow = "Well Below"
  case below = "Below"
  case steady = "Steady"
  case above = "Above"
  case wellAbove = "Well Above"
  
  public static func from(percentageDifference: Double) -> TrainingLoadStatus {
    switch percentageDifference {
    case ...(-20):
      return .wellBelow
    case -20..<(-5):
      return .below
    case -5...5:
      return .steady
    case 5..<20:
      return .above
    default:
      return .wellAbove
    }
  }
  
  public var color: Color {
    switch self {
    case .wellAbove, .wellBelow:
      return .mutedPink
    case .above, .below:
      return .mutedIndigo
    case .steady:
      return .mutedBlue
    }
  }
}
