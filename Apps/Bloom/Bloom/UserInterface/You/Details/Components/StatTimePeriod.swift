//
//  StatTimePeriod.swift
//  Bloom
//
//  Created by Mark DiFranco on 2026-01-08.
//

import Foundation
import BloomFoundation

enum StatTimePeriod: String, CaseIterable, Identifiable, Sendable {
  case oneDay = "1D"
  case sevenDays = "7D"
  case oneMonth = "1M"
  case threeMonths = "3M"
  case sixMonths = "6M"
  case oneYear = "1Y"

  var id: Self { self }

  var displayName: String {
    switch self {
    case .oneDay: String(localized: "Today", comment: "Display name for stat time period")
    case .sevenDays: String(localized: "Last 7 Days", comment: "Display name for stat time period")
    case .oneMonth: String(localized: "Last 30 Days", comment: "Display name for stat time period")
    case .threeMonths: String(localized: "Last 3 Months", comment: "Display name for stat time period")
    case .sixMonths: String(localized: "Last 6 Months", comment: "Display name for stat time period")
    case .oneYear: String(localized: "Last Year", comment: "Display name for stat time period")
    }
  }

  var dateRange: DateRange {
    switch self {
    case .oneDay: .today()
    case .sevenDays: .trailingDaysFromNow(6)
    case .oneMonth: .trailingMonthsFromNow(1)
    case .threeMonths: .trailingMonthsFromNow(3)
    case .sixMonths: .trailingMonthsFromNow(6)
    case .oneYear: .trailingYearsFromNow(1)
    }
  }

  var zoneMinutesGoal: Double {
    switch self {
    case .oneDay: 22
    case .sevenDays: 150
    case .oneMonth: 600
    case .threeMonths: 1800
    case .sixMonths: 3600
    case .oneYear: 7200
    }
  }

  var chartDateFormat: Date.FormatStyle {
    switch self {
    case .oneDay:
      .dateTime.hour()
    case .sevenDays:
      .dateTime.weekday(.abbreviated)
    case .oneMonth:
      .dateTime.day()
    case .threeMonths, .sixMonths:
      .dateTime.month(.abbreviated).day()
    case .oneYear:
      .dateTime.month(.abbreviated)
    }
  }

  var aggregatesByWeek: Bool {
    switch self {
    case .oneDay, .sevenDays, .oneMonth:
      false
    case .threeMonths, .sixMonths, .oneYear:
      true
    }
  }

  var comparisonPeriodLabel: String {
    switch self {
    case .oneDay: String(localized: "vs yesterday", comment: "Comparison label for stat time period")
    case .sevenDays: String(localized: "vs last week", comment: "Comparison label for stat time period")
    case .oneMonth: String(localized: "vs last month", comment: "Comparison label for stat time period")
    case .threeMonths: String(localized: "vs previous 3 months", comment: "Comparison label for stat time period")
    case .sixMonths: String(localized: "vs previous 6 months", comment: "Comparison label for stat time period")
    case .oneYear: String(localized: "vs previous year", comment: "Comparison label for stat time period")
    }
  }

  var currentPeriodLabel: String {
    switch self {
    case .oneDay: String(localized: "Today", comment: "Current period label for stat time period")
    case .sevenDays: String(localized: "This Week", comment: "Current period label for stat time period")
    case .oneMonth: String(localized: "This Month", comment: "Current period label for stat time period")
    case .threeMonths: String(localized: "Last 3 Mo", comment: "Current period label for stat time period, abbreviated for a compact chart label")
    case .sixMonths: String(localized: "Last 6 Mo", comment: "Current period label for stat time period, abbreviated for a compact chart label")
    case .oneYear: String(localized: "This Year", comment: "Current period label for stat time period")
    }
  }

  var previousPeriodLabel: String {
    switch self {
    case .oneDay: String(localized: "Yesterday", comment: "Previous period label for stat time period")
    case .sevenDays: String(localized: "Last Week", comment: "Previous period label for stat time period")
    case .oneMonth: String(localized: "Last Month", comment: "Previous period label for stat time period")
    case .threeMonths: String(localized: "Prev 3 Mo", comment: "Previous period label for stat time period, abbreviated for a compact chart label")
    case .sixMonths: String(localized: "Prev 6 Mo", comment: "Previous period label for stat time period, abbreviated for a compact chart label")
    case .oneYear: String(localized: "Last Year", comment: "Previous period label for stat time period")
    }
  }

  var previousPeriodDateRange: DateRange {
    let calendar = Calendar.current
    let currentRange = dateRange

    switch self {
    case .oneDay:
      // Yesterday
      return .yesterday()
    case .sevenDays:
      // 7 days before the current period start
      guard let end = calendar.date(byAdding: .second, value: -1, to: currentRange.start),
            let start = calendar.date(byAdding: .day, value: -7, to: end) else {
        return currentRange
      }
      return DateRange(start, end)
    case .oneMonth:
      // 1 month before the current period start
      guard let end = calendar.date(byAdding: .second, value: -1, to: currentRange.start),
            let start = calendar.date(byAdding: .month, value: -1, to: end) else {
        return currentRange
      }
      return DateRange(start, end)
    case .threeMonths:
      // 3 months before the current period start
      guard let end = calendar.date(byAdding: .second, value: -1, to: currentRange.start),
            let start = calendar.date(byAdding: .month, value: -3, to: end) else {
        return currentRange
      }
      return DateRange(start, end)
    case .sixMonths:
      // 6 months before the current period start
      guard let end = calendar.date(byAdding: .second, value: -1, to: currentRange.start),
            let start = calendar.date(byAdding: .month, value: -6, to: end) else {
        return currentRange
      }
      return DateRange(start, end)
    case .oneYear:
      // 1 year before the current period start
      guard let end = calendar.date(byAdding: .second, value: -1, to: currentRange.start),
            let start = calendar.date(byAdding: .year, value: -1, to: end) else {
        return currentRange
      }
      return DateRange(start, end)
    }
  }
}
