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
      String(localized: "Daily", comment: "Display name for goal time period")
    case .weekly:
      String(localized: "Weekly", comment: "Display name for goal time period")
    case .monthly:
      String(localized: "Monthly", comment: "Display name for goal time period")
    case .yearly:
      String(localized: "Yearly", comment: "Display name for goal time period")
    @unknown default:
      ""
    }
  }
}
