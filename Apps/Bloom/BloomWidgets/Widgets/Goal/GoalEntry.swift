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

struct GoalEntry: TimelineEntry {
  let date: Date
  let relevance: TimelineEntryRelevance?

  // Goal metadata
  let goalId: String
  let goalName: String
  let systemImage: String
  let colorHex: String
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
