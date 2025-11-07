//
//  GoalWidgetData.swift
//  BloomFoundation
//
//  Created by Claude Code on 2025-10-30.
//

import Foundation

/// Data structure for caching goal information for widgets
public struct GoalWidgetData: Codable, Sendable {
  /// Unique identifier for the goal
  public let id: String

  /// Target metric raw value (convert to TargetMetric enum in consuming code)
  public let targetMetricRawValue: String

  /// Current progress value for the goal
  public let currentValue: Double

  /// Target value for the goal
  public let targetValue: Double

  /// Unit string for display
  public let targetUnit: String

  /// Time period for the goal (daily, weekly, monthly, yearly)
  public let timePeriod: String

  /// Grid completion data structure
  public let gridData: GridData

  public init(
    id: String,
    targetMetricRawValue: String,
    currentValue: Double,
    targetValue: Double,
    targetUnit: String,
    timePeriod: String,
    gridData: GridData
  ) {
    self.id = id
    self.targetMetricRawValue = targetMetricRawValue
    self.currentValue = currentValue
    self.targetValue = targetValue
    self.targetUnit = targetUnit
    self.timePeriod = timePeriod
    self.gridData = gridData
  }
}

public extension GoalWidgetData {
  /// Grid data that can represent different time periods
  enum GridData: Codable, Sendable {
    case daily(DailyGridData)
    case weekly(WeeklyGridData)
    case monthly(MonthlyGridData)
    case yearly(YearlyGridData)
  }

  /// Daily grid data - 40 weeks with 7 days each
  struct DailyGridData: Codable, Sendable {
    public let weeks: [Week]

    public init(weeks: [Week]) {
      self.weeks = weeks
    }

    public struct Week: Codable, Sendable {
      public let id: Int
      public let isComplete: [Bool]
      public let todayIndex: Int?

      public init(id: Int, isComplete: [Bool], todayIndex: Int? = nil) {
        self.id = id
        self.isComplete = isComplete
        self.todayIndex = todayIndex
      }
    }
  }

  /// Weekly grid data - 20 weeks with completion status
  struct WeeklyGridData: Codable, Sendable {
    public let weeks: [Week]

    public init(weeks: [Week]) {
      self.weeks = weeks
    }

    public struct Week: Codable, Sendable {
      public let id: Int
      public let isComplete: Bool?
      public let isCurrentWeek: Bool
      public let monthLabel: String?

      public init(
        id: Int,
        isComplete: Bool?,
        isCurrentWeek: Bool = false,
        monthLabel: String? = nil
      ) {
        self.id = id
        self.isComplete = isComplete
        self.isCurrentWeek = isCurrentWeek
        self.monthLabel = monthLabel
      }
    }
  }

  /// Monthly grid data - 12 months with completion status
  struct MonthlyGridData: Codable, Sendable {
    public let months: [Month]

    public init(months: [Month]) {
      self.months = months
    }

    public struct Month: Codable, Sendable {
      public let id: Int
      public let isComplete: Bool?
      public let isCurrentMonth: Bool
      public let monthLabel: String

      public init(
        id: Int,
        isComplete: Bool?,
        isCurrentMonth: Bool = false,
        monthLabel: String = ""
      ) {
        self.id = id
        self.isComplete = isComplete
        self.isCurrentMonth = isCurrentMonth
        self.monthLabel = monthLabel
      }
    }
  }

  /// Yearly grid data - 5 years with completion status
  struct YearlyGridData: Codable, Sendable {
    public let years: [Year]

    public init(years: [Year]) {
      self.years = years
    }

    public struct Year: Codable, Sendable {
      public let id: Int
      public let isComplete: Bool?
      public let isCurrentYear: Bool
      public let yearLabel: String

      public init(
        id: Int,
        isComplete: Bool?,
        isCurrentYear: Bool = false,
        yearLabel: String = ""
      ) {
        self.id = id
        self.isComplete = isComplete
        self.isCurrentYear = isCurrentYear
        self.yearLabel = yearLabel
      }
    }
  }
}
