//
//  GoalTimePeriod+Helpers.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-20.
//

import BloomFoundation
import DataContainer

extension GoalTimePeriod {

  var dateRange: DateRange {
    switch self {
    case .daily:
        .today()
    case .weekly:
        .startOfWeekToNow()
    case .monthly:
        .startOfMonthToNow()
    case .yearly:
        .startOfYearToNow()
    @unknown default:
        .today()
    }
  }

  var name: String {
    switch self {
    case .daily:
      "Daily"
    case .weekly:
      "Weekly"
    case .monthly:
      "Monthly"
    case .yearly:
      "Yearly"
    @unknown default:
      ""
    }
  }
}
