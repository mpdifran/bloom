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
    case .daily: "Today"
    case .weekly: "This Week"
    case .monthly: "This Month"
    case .yearly: "This Year"
    }
  }
}
