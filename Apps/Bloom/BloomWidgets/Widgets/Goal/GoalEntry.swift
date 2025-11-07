//
//  GoalEntry.swift
//  BloomWidgets
//
//  Created by Claude Code on 2025-10-30.
//

import Foundation
import WidgetKit
import BloomFoundation
import BloomUI
import DataContainer

struct GoalEntry: TimelineEntry {
  let date: Date
  let relevance: TimelineEntryRelevance?

  // Goal metadata
  let goalId: String
  let targetMetric: TargetMetric
  let currentValue: Double
  let targetValue: Double
  let targetUnit: String
  let timePeriod: String

  // Grid data (union type for different time periods)
  let gridData: GridData

  // State flags
  let isLoading: Bool
}

extension GoalEntry {
  enum GridData {
    case daily(GoalGridModel)
    case weekly(GoalGridWeekModel)
    case monthly(GoalGridMonthModel)
    case yearly(GoalGridYearModel)
  }
}
