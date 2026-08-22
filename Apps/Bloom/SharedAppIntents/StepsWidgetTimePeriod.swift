//
//  StepsWidgetTimePeriod.swift
//  Bloom
//
//  Created by Claude Code on 2026-02-09.
//

import AppIntents
import Foundation

enum StepsWidgetTimePeriod: String, AppEnum {
  case daily
  case weekly
  case monthly
  case yearly

  nonisolated(unsafe) static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Time Period")

  nonisolated(unsafe) static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
    .daily: "Daily",
    .weekly: "Weekly",
    .monthly: "Monthly",
    .yearly: "Yearly",
  ]

  var displayLabel: String {
    switch self {
    case .daily: String(localized: "Today", comment: "Time period label shown in the Steps widget")
    case .weekly: String(localized: "This Week", comment: "Time period label shown in the Steps widget")
    case .monthly: String(localized: "This Month", comment: "Time period label shown in the Steps widget")
    case .yearly: String(localized: "This Year", comment: "Time period label shown in the Steps widget")
    }
  }
}
