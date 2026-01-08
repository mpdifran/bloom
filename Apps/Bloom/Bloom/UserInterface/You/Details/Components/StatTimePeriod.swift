//
//  StatTimePeriod.swift
//  Bloom
//
//  Created by Mark DiFranco on 2026-01-08.
//

import Foundation
import BloomFoundation

enum StatTimePeriod: String, CaseIterable, Identifiable, Sendable {
  case sevenDays = "7D"
  case oneMonth = "1M"
  case threeMonths = "3M"
  case sixMonths = "6M"
  case oneYear = "1Y"

  var id: Self { self }

  var displayName: String {
    switch self {
    case .sevenDays: "Last 7 Days"
    case .oneMonth: "Last 30 Days"
    case .threeMonths: "Last 3 Months"
    case .sixMonths: "Last 6 Months"
    case .oneYear: "Last Year"
    }
  }

  var dateRange: DateRange {
    switch self {
    case .sevenDays: .trailingDaysFromNow(7)
    case .oneMonth: .trailingMonthsFromNow(1)
    case .threeMonths: .trailingMonthsFromNow(3)
    case .sixMonths: .trailingMonthsFromNow(6)
    case .oneYear: .trailingYearsFromNow(1)
    }
  }

  var zoneMinutesGoal: Double {
    switch self {
    case .sevenDays: 150
    case .oneMonth: 600
    case .threeMonths: 1800
    case .sixMonths: 3600
    case .oneYear: 7200
    }
  }

  var chartDateFormat: Date.FormatStyle {
    switch self {
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
    case .sevenDays, .oneMonth:
      false
    case .threeMonths, .sixMonths, .oneYear:
      true
    }
  }
}
