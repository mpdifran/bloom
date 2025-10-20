//
//  BudSummaryEntry.swift
//  BloomWidgets
//
//  Created by Claude Code on 2025-10-19.
//

import Foundation
import WidgetKit
import BloomUI

struct BudSummaryEntry: TimelineEntry {
  let date: Date
  var relevance: TimelineEntryRelevance?

  // Display fields
  let budState: String?
  let summary: String?
  let timeMode: TimeMode
  let userName: String

  // State flags
  let isLoading: Bool
  let hasError: Bool
  let isSubscribed: Bool
}
