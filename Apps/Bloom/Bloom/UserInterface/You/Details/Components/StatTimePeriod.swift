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
    case .oneDay: String(localized: "Today")
    case .sevenDays: String(localized: "Last 7 Days")
    case .oneMonth: String(localized: "Last 30 Days")
    case .threeMonths: String(localized: "Last 3 Months")
    case .sixMonths: String(localized: "Last 6 Months")
    case .oneYear: String(localized: "Last Year")
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
    case .oneDay: "vs yesterday"
    case .sevenDays: "vs last week"
    case .oneMonth: "vs last month"
    case .threeMonths: "vs previous 3 months"
    case .sixMonths: "vs previous 6 months"
    case .oneYear: "vs previous year"
    }
  }

  var currentPeriodLabel: String {
    switch self {
    case .oneDay: "Today"
    case .sevenDays: "This Week"
    case .oneMonth: "This Month"
    case .threeMonths: "Last 3 Mo"
    case .sixMonths: "Last 6 Mo"
    case .oneYear: "This Year"
    }
  }

  var previousPeriodLabel: String {
    switch self {
    case .oneDay: "Yesterday"
    case .sevenDays: "Last Week"
    case .oneMonth: "Last Month"
    case .threeMonths: "Prev 3 Mo"
    case .sixMonths: "Prev 6 Mo"
    case .oneYear: "Last Year"
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
