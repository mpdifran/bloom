//
//  HealthInsightEntry.swift
//  BloomWidgets
//
//  Created by Claude Code on 2025-10-22.
//

import Foundation
import WidgetKit
import SwiftUI

struct HealthInsightEntry: TimelineEntry {
  let date: Date
  var relevance: TimelineEntryRelevance?

  // Display fields
  let title: String
  let body: String
  let priority: Int

  // State flags
  let isLoading: Bool
  let hasError: Bool
  let isSubscribed: Bool
}
